# MaterialPointGenerator

This package is used for generating structured particles for Material Point Method (MPM) simulation. The current particle generation method using `Gmsh` modeling may require GPU acceleration. We have provided a backend-agnostic solution that supports switching between NVIDIA (CUDA), AMD (ROCm), Apple (Metal), and Intel (oneAPI). Please follow the [documentation](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable) step-by-step to reproduce the results.

---

## Installation ⚙️

Just type `]` in Julia's  `REPL`:

```julia
julia> ]
(@1.11) Pkg> add MaterialPointGenerator
```

## Features ✨

- Structured (regular) coordinates
- Support Gmsh for complicated 2/3D models
- Backend-agnostic functions supports
- Particle generation from a Digital Elevation Model (DEM) file  
- Automatically interpolate DEM files with support for shape trimming.

## Acknowledgement 👍

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).