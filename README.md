# KnetNLPModels : An interface to NLPModels

| **Documentation** | **Linux/macOS/Windows** | **Coverage** | **DOI** |
|:-----------------:|:-------------------------------:|:------------:|:-------:|
| [![docs-stable][docs-stable-img]][docs-stable-url] [![docs-dev][docs-dev-img]][docs-dev-url] | [![build-gh][build-gh-img]][build-gh-url] | [![codecov][codecov-img]][codecov-url] | [![doi][doi-img]][doi-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://JuliaSmoothOptimizers.github.io/KnetNLPModels.jl/stable
[docs-dev-img]: https://img.shields.io/badge/docs-dev-purple.svg
[docs-dev-url]: https://JuliaSmoothOptimizers.github.io/KnetNLPModels.jl/dev
[build-gh-img]: https://github.com/JuliaSmoothOptimizers/KnetNLPModels.jl/workflows/CI/badge.svg?branch=main
[build-gh-url]: https://github.com/JuliaSmoothOptimizers/KnetNLPModels.jl/actions
[codecov-img]: https://codecov.io/gh/JuliaSmoothOptimizers/KnetNLPModels.jl/branch/main/graph/badge.svg
[codecov-url]: https://app.codecov.io/gh/JuliaSmoothOptimizers/KnetNLPModels.jl
[doi-img]: https://img.shields.io/badge/DOI-10.5281%2Fzenodo.822073-blue.svg
[doi-url]: https://doi.org/10.5281/zenodo.822073

## Compatibility
Julia ≥ 1.6.

## How to install
This module can be installed with the following command:
```julia
pkg> add KnetNLPModels
pkg> test KnetNLPModels
```

## Synopsis
KnetNLPModels is an interface between [Knet.jl](https://github.com/denizyuret/Knet.jl.git)'s classification neural networks and [NLPModels.jl](https://github.com/JuliaSmoothOptimizers/NLPModels.jl.git).

A `KnetNLPModel` gives the user access to:
- the values of the neural network variables/weights `w`;
- the value of the objective/loss function `L(X, Y; w)` at `w` for a given minibatch `(X,Y)`;
- the gradient `∇L(X, Y; w)` of the objective/loss function at `w` for a given mini-batch `(X,Y)`.

In addition, it provides tools to:
- switch the minibatch used to evaluate the neural network;
- change the minibatch size;
- measure the neural network's accuracy at the current `w`.

## How to use
Check the [tutorial](https://juliasmoothoptimizers.github.io/KnetNLPModels.jl/dev/tutorial/).

## How to Cite

If you use KnetNLPModels.jl in your work, please cite using the format given in [`CITATION.bib`](https://github.com/JuliaSmoothOptimizers/KnetNLPModels.jl/blob/main/CITATION.bib).
