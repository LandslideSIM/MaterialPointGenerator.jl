```@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: <font size=6>MaterialPointGenerator.jl</font>
  text: 
  tagline: An efficient structured particle generator for the MPM in Julia 
  actions:
    - theme: brand
      text: View on GitHub
      link: https://github.com/LandslideSIM/MaterialPointGenerator.jl
  image:
    src: /assets/logobg.svg
    alt: MaterialPointGenerator.jl

features:
  - icon: 🕸️
    title: Structured coordinates
    details: MaterialPointGenerator.jl is used for generating structured (regular) particles for multiple scenarios
    link: 

  - icon: 🧠
    title: Complicated 2/3D models
    details: It supports complex 2D and 3D models, even with internal holes, as long as the surface mesh is watertight
    link:

  - icon: ⛰️
    title: Digital elevation model (DEM)
    details: Particle generation from a Digital Elevation Model (DEM) file  
    link: 

  - icon: 🧩
    title: DEM advanced operations
    details: Automatically interpolate DEM files with support for shape trimming.
    link:
---
```

##

During the EGU2023 conference, when I presented a high-performance MPM  (Material Point Method) solver, I was asked, 
"How do you discretize the computational model for the MPM?" I didn't have a clear answer (I didn't even consider it a problem) because the models were relatively simple and could be generated directly using some straightforward functions. However, as computational models gradually became more complex and diverse, I began to realize that this was indeed a very good question. 

The preprocessing for MPM should not be a computationally intensive task; it should be fast enough. Yet, I couldn't find a "plug-and-play" generalized code for this purpose. Some literatures have contributed to this issue, and I built upon their work to create a comprehensive and refined julia package. 

> No parallelization, no problem—5,334,808 particles from an STL file (998,137 triangles) in just 0.6 s
> Intel(R) Core(TM) i9-10900K CPU @ 3.70GHz

## Installation

Just type `]` in Julia's  `REPL`:

```julia
julia> ]
(@1.11) Pkg> add MaterialPointGenerator
```

## Acknowledgement

This project is sponserd by [Risk Group | Université de Lausanne](https://wp.unil.ch/risk/) and [China Scholarship Council [中国国家留学基金管理委员会]](https://www.csc.edu.cn/).