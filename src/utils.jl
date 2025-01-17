"""
    flag_dim(x)
  
Returns true if x has 3 dimensions.
This function is used to reshape X in `create_minibatch(X, Y, minibatch_size)` in case x has only 3 dimensions.
"""
flag_dim(x) = length(size(x)) == 3

"""
    create_minibatch(X, Y, minibatch_size)

Create a minibatch's iterator of the data `X`, `Y` of size `1/minibatch_size * length(Y)`.
"""
function create_minibatch(x_data, y_data, minibatch_size; _reshape::Bool=flag_dim(x_data))
  mb = minibatch(x_data, y_data, minibatch_size; xsize = (size(x_data, 1), size(x_data, 2), size(x_data, 3), :))
  if _reshape
    mb.xsize = (size(x_data, 1), size(x_data, 2), 1, :) # To force x_data to take 1 as third dimension
  end
  return mb
end

"""
    vector_params(chain :: C) where C <: Chain
    vector_params(nlp :: AbstractKnetNLPModel)

Retrieve the variables within `chain` or `nlp.chain` as a vector.
"""
vector_params(chain::C) where {C <: Chain} = Array(vcat_arrays_vector(params(chain)))
vector_params(nlp::AbstractKnetNLPModel) = nlp.w

"""
    vcat_arrays_vector(arrays_vector::AbstractVector{Param})

Flatten a vector of arrays `arrays_vector` to a vector.
It concatenates the vectors produced by the application of `Knet.cat1d` to each array.
"""
vcat_arrays_vector(arrays_vector::AbstractVector{Param}) = vcat(Knet.cat1d.(arrays_vector)...)

"""
    reset_minibatch_train!(nlp::AbstractKnetNLPModel)

Select a new training minibatch for `nlp`.
Typically used before a new evaluation of the loss function/gradient.
"""
reset_minibatch_train!(nlp::AbstractKnetNLPModel) =
  nlp.current_training_minibatch = rand(nlp.training_minibatch_iterator)

"""
    reset_minibatch_test!(nlp::AbstractKnetNLPModel)

Select a new test minibatch for `nlp`.
"""
reset_minibatch_test!(nlp::AbstractKnetNLPModel) =
  nlp.current_test_minibatch = rand(nlp.test_minibatch_iterator)

"""
    accuracy(nlp::AbstractKnetNLPModel)

Compute the accuracy of the network `nlp.chain` on the entire test dataset.
"""
accuracy(nlp::AbstractKnetNLPModel) = Knet.accuracy(nlp.chain; data = nlp.test_minibatch_iterator)

"""
    build_layer_from_vec!(array :: AbstractArray{T, N}, v :: AbstractVector{T}, index :: Int) where {T <: Number, N}

Inverse of the function `Knet.cat1d`; set `array` to the values of `v` in the range `index+1:index+consumed_index`.
"""
function build_layer_from_vec!(
  array::AbstractArray{T, N},
  v::AbstractVector{T},
  index::Int,
) where {T <: Number, N}
  sizearray = reduce(*, size(array))
  copyto!(array, v[(index + 1):(index + sizearray)])
  return sizearray
  # size_array is consume_index in the method
  # build_nested_array_from_vec!(nested_array,new_w)
end

"""
    nested_array = build_nested_array_from_vec(model::AbstractKnetNLPModel{T, S}, v::AbstractVector{T}) where {T <: Number, S}
    nested_array = build_nested_array_from_vec(chain_ANN::C, v::AbstractVector{T}) where {C <: Chain, T <: Number}
    nested_array = build_nested_array_from_vec(nested_array::AbstractVector{<:AbstractArray{T,N} where {N}}, v::AbstractVector{T}) where {T <: Number}

Build a vector of `AbstractArray` from `v` similar to `Knet.params(model.chain)`, `Knet.params(chain_ANN)` or `nested_array`.
Call iteratively `build_layer_from_vec` to build each intermediate `AbstractArray`.
This method is not optimized; it allocates memory.
"""
build_nested_array_from_vec(
  model::AbstractKnetNLPModel{T, S},
  v::AbstractVector{T},
) where {T <: Number, S} = build_nested_array_from_vec(model.chain, v)

function build_nested_array_from_vec(
  chain_ANN::C,
  v::AbstractVector{T},
) where {C <: Chain, T <: Number}
  param_chain = params(chain_ANN) # :: Param
  size_param = mapreduce((var_layer -> reduce(*, size(var_layer))), +, param_chain)
  size_param == length(v) || error(
    "Dimension of Vector v mismatch, function build_nested_array $(size_param) != $(length(v))",
  )

  nested_w_value = (w -> w.value).(param_chain)
  nested_array = build_nested_array_from_vec(nested_w_value, v)
  return nested_array
end

function build_nested_array_from_vec(
  nested_array::AbstractVector{<:AbstractArray{T, N} where {N}},
  v::AbstractVector{T},
) where {T <: Number}
  similar_nested_array = map(array -> similar(array), nested_array)
  build_nested_array_from_vec!(similar_nested_array, v)
  return similar_nested_array
end

"""
    build_nested_array_from_vec!(model::AbstractKnetNLPModel{T,S}, new_w::AbstractVector{T}) where {T, S}
    build_nested_array_from_vec!(nested_array :: AbstractVector{<:AbstractArray{T,N} where {N}}, new_w :: AbstractVector{T}) where {T <: Number}

Build a vector of `AbstractArray` from `new_w` similar to `Knet.params(model.chain)` or `nested_array`.
Call iteratively `build_layer_from_vec!` to build each intermediate `AbstractArray`.
This method is not optimized; it allocates memory.
"""
build_nested_array_from_vec!(
  model::AbstractKnetNLPModel{T, S},
  new_w::AbstractVector{T},
) where {T, S} = build_nested_array_from_vec!(model.nested_array, new_w)

function build_nested_array_from_vec!(
  nested_array::AbstractVector{<:AbstractArray{T, N} where {N}},
  new_w::AbstractVector{T},
) where {T <: Number}
  index = 0
  for variable_layer in nested_array
    consumed_indices = build_layer_from_vec!(variable_layer, new_w, index)
    index += consumed_indices
  end
  nested_array
end

"""
    set_vars!(model::AbstractKnetNLPModel{T,S}, new_w::AbstractVector{T}) where {T<:Number, S}
    set_vars!(chain_ANN :: C, nested_w :: AbstractVector{<:AbstractArray{T,N} where {N}}) where {C <: Chain, T <: Number}
    set_vars!(vars :: Vector{Param}, nested_w :: AbstractVector{<:AbstractArray{T,N} where {N}})
)

Set the variables of `model` (resp. `chain_ANN` and `vars`) to `new_w` (resp. `nested_w`).
Build `nested_w`: a vector of `AbstractArray` from `new_v` similar to `Knet.params(model.chain)`.
Then, set the variables `vars` of the neural netword `model` (resp. `chain_ANN`) to `new_w` (resp. `nested_w`).
`set_vars!(model, new_w)` allocates memory.
"""
set_vars!(
  vars::AbstractVector{Param},
  nested_w::AbstractVector{<:AbstractArray{T, N} where {N}},
) where {T <: Number} = map(i -> vars[i].value .= nested_w[i], 1:length(vars))

set_vars!(
  chain_ANN::C,
  nested_w::AbstractVector{<:AbstractArray{T, N} where {N}},
) where {C <: Chain, T <: Number} = set_vars!(params(chain_ANN), nested_w)

function set_vars!(
  model::AbstractKnetNLPModel{T, S},
  new_w::AbstractVector{T},
) where {T <: Number, S}
  build_nested_array_from_vec!(model, new_w)
  set_vars!(model.chain, model.nested_array)
  model.w .= new_w
end
