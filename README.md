# ***MaterialPointGenerator*** <img src="docs/src/assets/logo.png" align="right" height="126" />

[![CI](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml) 
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg?logo=quicklook)](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable)
[![Version](https://img.shields.io/badge/version-v0.1.5-pink)]()

This package is used for generating structured particles for Material Point Method (MPM) simulation. To do it, we are relying on [trimesh](https://trimesh.org/) (python) by using [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl). Don't worry, we will handle the env automatically. If you want to use your own Python env, please make sure [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl) can find your env and install the packages in the `CondaPkg.toml`. Please follow the [documentation](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable) step-by-step to reproduce the results.

---

## Installation ⚙️

Just type <kbd>]</kbd> in Julia's  `REPL`:

```julia
julia> ]
(@1.11) Pkg> add MaterialPointGenerator
```

## Features ✨

- [x] Structured (regular) coordinates
- [x] Support complicated 2/3D models
- [x] Particle generation from a Digital Elevation Model (DEM) file  
- [x] Automatically interpolate DEM files with support for shape trimming.

## Showcases 🎲

| 3D phoenix and dragon |  DEM with thickness | complex 2D |
|:--------:|:--------:|:--------:|
| <img src="docs/src/assets/showcase/phoenix_dragon.png" width="200"> | ![Image2](https://via.placeholder.com/100) | ![Image3](https://via.placeholder.com/100) |


## Acknowledgement 👍

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).