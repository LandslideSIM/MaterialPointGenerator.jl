# Polyhedron

!!! note

    All example files can be found at `assets/3d_simple` [https://github.com/LandslideSIM/MaterialPointGenerator.jl](https://github.com/LandslideSIM/MaterialPointGenerator.jl).

Here, we only need to provide the `.stl` file and specify the cell size `h`.

```julia
using MaterialPointGenerator

src_dir     = joinpath(@__DIR__, "assets/3d_simple")
stl_file    = joinpath(src_dir, "wedge.stl")
output_file = joinpath(src_dir, "3d_simple.xyz")

polyhedron2particle(stl_file, output_file, 0.5, verbose=true)
```

![image3](./image3.png)

A partially enlarged image:

![image4](./image4.png)