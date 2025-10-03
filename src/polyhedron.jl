#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : polyhedron.jl                                                              |
|  Description: Generate structured mesh in 3D space by a given polyhedron                 |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : polyhedron2particle                                                        |
+==========================================================================================#

export polyhedron2particle

"""
    polyhedron2particle(stl_model::STLInfo3D, h::Real; fill::Bool=true, method::Symbol=:voxel, ϵ::Symbol=:double)

Description:
---
Convert a polyhedron (`STLInfo3D`) to a set of particles. The grid spacing is `h`. The 
`fill` option controls whether to populate the particles to the nearest grid points, which is
useful for MPM simulations. The `method` option allows you to choose between voxel-based
and ray-based particle generation. The `ϵ` parameter controls the floating-point precision,
default is :double (double precision) (or :single).

Example:
---
```julia
stl_model = readSTL3D("path/to/your/model.stl")
pts = polyhedron2particle(stl_model, 0.1; fill=true, method=:ray, ϵ=:double) # or method=:voxel
# or just provide the .stl file directly
pts = polyhedron2particle("path/to/your/model.stl", 0.1)
```
"""
function polyhedron2particle(
    stl_model::STLInfo3D, 
    h        ::Real;
    fill     ::Bool=true,
    method   ::Symbol=:voxel,
    ϵ        ::Symbol=:double
)
    if method == :voxel
        pts = sort_pts(_get_pts_voxel(stl_model, h, fill))
    else
        pts = sort_pts(_get_pts_ray(stl_model, h, fill))
    end
    T = ϵ == :single ? Float32 : Float64
    return Array{T}(pts)
end


function polyhedron2particle(
    stl_file::String, 
    h       ::Real;
    fill    ::Bool=true,
    method  ::Symbol=:voxel,
    ϵ       ::Symbol=:double
)
    isfile(stl_file) || error("stl_file must be a valid file path")
    endswith(stl_file, ".stl") || error("stl_file must be a .stl file")
    stl_model = readSTL3D(stl_file)
    return polyhedron2particle(stl_model, h; fill=fill, method=method, ϵ=ϵ)
end