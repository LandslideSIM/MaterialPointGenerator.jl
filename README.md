# MaterialPointGenerator <img src="docs/src/assets/logo.png" align="right" height="126" />

[![CI](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/LandslideSIM/MaterialPointGenerator.jl/actions/workflows/ci.yml) 
[![codecov](https://codecov.io/gh/LandslideSIM/MaterialPointGenerator.jl/graph/badge.svg?token=3P72U13J10)](https://codecov.io/gh/LandslideSIM/MaterialPointGenerator.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable)

<p>
This package is used for generating structured points for Material Point Method (MPM) simulation. Currently, there are some limitations in this package, please follow the <a href="https://LandslideSIM.github.io/MaterialPointGenerator.jl/stable">documentation</a> step-by-step to reproduce the results.
</p>

---

## Installation ⚙️

Just type <kbd>]</kbd> in Julia's  `REPL`:

```julia
julia> ]
(@1.10) Pkg> add MaterialPointGenerator
```

## Features ✨

- [x] Structured coordinates
- [x] Customize the lowest plane (z)
- [x] The projection on the X-Y plane does not have to be rectangular

## To-do 🗒️

- [ ] Multi-layer particles
- [ ] Particle generation from a 2D profile

## Acknowledgement 👍

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).