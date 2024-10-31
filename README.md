# ***MaterialPointGenerator*** <img src="docs/src/assets/logo.png" align="right" height="126" />

[![CI](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml) 
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg?logo=quicklook)](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable)
[![Version](https://img.shields.io/badge/version-v0.1.3-pink)]()

This package is used for generating structured particles for Material Point Method (MPM) simulation. The current particle generation method using `Gmsh` modeling may require GPU acceleration. We have provided a backend-agnostic solution that supports switching between NVIDIA (CUDA), AMD (ROCm), Apple (Metal), and Intel (oneAPI). Please follow the [documentation](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable) step-by-step to reproduce the results.

---

## Installation ⚙️

Just type <kbd>]</kbd> in Julia's  `REPL`:

```julia
julia> ]
(@1.11) Pkg> add MaterialPointGenerator
```

## Features ✨

- [x] Structured (regular) coordinates
- [x] Support Gmsh for complicated 2/3D models
- [x] Backend-agnostic functions supports
- [x] Particle generation from a Digital Elevation Model (DEM) file  
- [x] Automatically interpolate DEM files with support for shape trimming.

## Showcases 🎲


## Acknowledgement 👍

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).