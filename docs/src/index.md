# MPMPtsGen.jl Manual



[![CI](https://github.com/LandslideSIM/MPMSolver.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/LandslideSIM/MPMSolver.jl/actions/workflows/ci.yml) 
[![codecov](https://codecov.io/gh/LandslideSIM/MPMSolver.jl/branch/master/graph/badge.svg?token=5P4XHD79HN)](https://codecov.io/gh/ZenanH/Landslides.jl) 
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://LandslideSIM.github.io/MPMPtsGen.jl/stable)

This package is used for generating structured points for MPM simulation. Currently, there are some limitations in this package, please follow the [documentation](https://LandslideSIM.github.io/MPMPtsGen.jl/stable) step-by-step to reproduce the results.

---

## Installation 

Just type `]` in Julia's  `REPL`:

```julia
julia> ]
(@1.9) Pkg> add MPMPtsGen
```

## Features 

- [x] Structured coordinates
- [x] Customize the lowest plane (z)
- [x] The projection on the X-Y plane does not have to be rectangular

## To-do 

- [ ] Multi-layer particles
- [ ] Particle generation from a 2D profile

## Acknowledgement 

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).