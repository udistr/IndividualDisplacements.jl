# IndividualDisplacements.jl

[![Travis Build Status](https://travis-ci.org/JuliaClimate/IndividualDisplacements.jl.svg?branch=master)](https://travis-ci.org/JuliaClimate/IndividualDisplacements.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaClimate.github.io/IndividualDisplacements.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaClimate.github.io/IndividualDisplacements.jl/dev)
[![DOI](https://zenodo.org/badge/208676176.svg)](https://zenodo.org/badge/latestdoi/208676176)

**IndividualDisplacements.jl** computes point displacements over a gridded domain. It is geared towards the analysis of Climate, Ocean, etc models (`Arakawa C-grids` are natively supported) and the simulation of material transports within the Earth System (e.g. plastics or planktons in the Ocean; dusts or chemicals in the Atmosphere). 

Inter-operability with popular climate model grids via [MeshArrays.jl](https://github.com/JuliaClimate/MeshArrays.jl) is an important aspect. The package can read and write individual displacement collection files, including those generated by the [MIT general circulation model](https://mitgcm.readthedocs.io/en/latest/?badge=latest). `IndividualDisplacements`'s initial test suite is based on global ocean model simulations called [ECCO (v4r2)](https://eccov4.readthedocs.io/en/latest/) and [CBIOMES (alpha)](https://cbiomes.readthedocs.io/en/latest/) (see [Forget et al. 2015](https://doi.org/10.5194/gmd-8-3071-2015)).

### Installation

```
using Pkg
Pkg.add("IndividualDisplacements")
Pkg.test("IndividualDisplacements")
```

<img src="https://github.com/JuliaClimate/IndividualDisplacements.jl/raw/master/examples/figs/SolidBodyRotation.png" width="40%">  <img src="https://github.com/JuliaClimate/IndividualDisplacements.jl/raw/master/examples/figs/RandomFlow.gif" width="40%">

### Example

The above examples are reproduced as follows:

```
using IndividualDisplacements
p = dirname(pathof(IndividualDisplacements))
include(joinpath(p ,"../examples/SolidBodyRotation.jl"))
include(joinpath(p ,"../examples/RandomFlow_fleet.jl"))
```
