#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : polygon.jl                                                                 |
|  Description: Generate structured mesh in 2D space by a given polygon                    |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : polygon2particle                                                           |
+==========================================================================================#

export polygon2particle

"""
    polygon2particle(polygon::QueryPolygon, h::Real; fill::Bool=true, edge::Bool=false, ϵ::Symbol=:double)

Description:
---
Convert a polygon to a set of particles. The grid spacing is `h`, it is suggested to be equal
to the MPM background grid size. The `fill` option controls whether to populate the
particles to the nearest grid points, which is useful for MPM simulations. The `edge` option
controls whether to include the edge points of the polygon in the particle generation. `ϵ`
controls the floating-point precision, default is double precision (:double) (or :single).

Example:
---
```julia
points = rand(20, 2)
polygon = get_polygon(points)
h = 0.1
pts = polygon2particle(polygon, h; fill=true, edge=false, ϵ=:single)
# or just provide the polygon file directly
pts = polygon2particle("path/to/your/polygon.geojson", h; fill=true, edge=false, ϵ=:double)
# or just provide the stl file directly
pts = polygon2particle("path/to/your/stlfile.stl", h; fill=true, edge=false, ϵ=:single)
```
"""
function polygon2particle(
    polygon ::QueryPolygon, 
    h       ::Real; 
    fill    ::Bool=true, 
    edge    ::Bool=false,
    ϵ       ::Symbol=:double
)
    pts = sort_pts(_get_pts(polygon, h, fill, edge))
    T = ϵ == :single ? Float32 : Float64
    return Array{T}(pts)
end

function polygon2particle(
    filename::String, 
    h       ::Real; 
    fill    ::Bool=true,
    edge    ::Bool=false,
    ϵ       ::Symbol=:double
)
    isfile(filename) || error("filename must be a valid file path")
    if endswith(filename, ".stl")
        stl_model = readSTL2D(stl_file)
        pts = _get_pts(stl_model, h, fill, edge)
    elseif endswith(filename, ".geojson")
        polygon = read_polygon(filename)
        pts = _get_pts(polygon, h, fill, edge)
    end
    T = ϵ == :single ? Float32 : Float64
    return Array{T}(pts)
end