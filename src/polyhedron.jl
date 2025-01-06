#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : polyhedron.jl                                                              |
|  Description: Generate structured mesh in 3D space by a given polyhedron                 |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. polyhedron2particle                                                    |
|               02. trimesh_voxelize                                                       |
+==========================================================================================#

export polyhedron2particle

struct GmshMesh{T1, T2}
    vertices :: Array{T2, 2}
    faces    :: Array{T1, 2}
    data     :: Vector{Vector{T2}}
    bounds   :: Vector{T2}
end

rs_dir = joinpath(@__DIR__, "_polyhedron")
include(joinpath(rs_dir, "_utils.jl"   ))
include(joinpath(rs_dir, "_workflow.jl"))

"""
    polyhedron2particle(stl_file::String, output_file, h; verbose::Bool=false, )

Description:
---
Convert a polyhedron (`.stl`) to a set of particles. The function will write the populated 
particles of each voxel into a `.xyz` file. The voxel size is defined by `h`, it is suggest
to be equal to the MPM background grid size. The `verbose` is a flag to show the time 
consumption of each step.

Example:
---
```julia
stl_file = "/path/to/your/model.stl"
output_file = "/path/to/your/model.xyz"
h = 0.1
polyhedron2particle(stl_file, output_file, h, verbose=true)
```
"""
function polyhedron2particle(
    stl_file   ::String, 
    output_file::String, 
    h          ::Real; 
    method     ::String="voxel",
    verbose    ::Bool  =false
)
    # inputs check
    method in ["voxel", "ray"] || throw(ArgumentError("method must be 'voxel' or 'ray'"))
    h > 0 || throw(ArgumentError("h must be positive"))

    # implementations
    if method == "voxel"
        pts, tp = trimesh_voxelize3D(stl_file, h)
        t4 = @elapsed np[].savetxt(output_file, pts, fmt="%.6f", delimiter=" ")
        if verbose
            t1, t2, t3 = tp[1], tp[2], tp[3]
            tt = sum(tp) + t4
            @info """voxelization with trimesh
            - load model  : $(@sprintf("%6.2f", t1)) s | $(@sprintf("%6.2f", 100*t1/tt))%
            - voxelize    : $(@sprintf("%6.2f", t2)) s | $(@sprintf("%6.2f", 100*t2/tt))%
            - fill voxels : $(@sprintf("%6.2f", t3)) s | $(@sprintf("%6.2f", 100*t3/tt))%
            - write .xyz  : $(@sprintf("%6.2f", t4)) s | $(@sprintf("%6.2f", 100*t4/tt))%
            $("-"^34)
            - total time  : $(@sprintf("%6.2f", tt)) s
            """
        end
    elseif method == "ray"
        t1 = @elapsed begin
            meshdata = readmesh(stl_file, precision="FP32")
        end
        t2 = @elapsed begin
            coords = _voxelize(meshdata, h)
        end
        t3 = @elapsed begin
            savexyz(joinpath(@__DIR__, output_file), coords)
        end
        tt = t1 + t2 + t3
        @info """ray casting
        - load model  : $(@sprintf("%6.2f", t1)) s | $(@sprintf("%6.2f", 100*t1/tt))%
        - ray casting : $(@sprintf("%6.2f", t2)) s | $(@sprintf("%6.2f", 100*t2/tt))%
        - write .xyz  : $(@sprintf("%6.2f", t3)) s | $(@sprintf("%6.2f", 100*t3/tt))%
        $("-"^34)
        - total time  : $(@sprintf("%6.2f", tt)) s
        """
    end

    return nothing
end

"""
    trimesh_voxelize3D(stl_file::String, h)

Description:
---
Voxelize the given STL model with the trimesh package. The voxel size is defined by `h`.
"""
function trimesh_voxelize3D(stl_file::String, h)
    h > 0 || throw(ArgumentError("h must be positive"))
    
    t1 = @elapsed begin
        mesh = trimesh[].load(stl_file, process=true)
        @info "STL model loaded"
    end

    t2 = @elapsed begin
        voxelized = voxelize(mesh, h)
        offset = h * 0.25
        voxelized_filled = voxelized.fill()
        pts_center = voxelized_filled.points
        @info "voxelized with trimesh"
    end

    t3 = @elapsed begin
        offsets = np[].array([[-offset,  offset,  offset], [-offset, -offset,  offset],
                              [ offset,  offset,  offset], [ offset, -offset,  offset],
                              [-offset,  offset, -offset], [-offset, -offset, -offset],
                              [ offset,  offset, -offset], [ offset, -offset, -offset]])
        pts = np[].vstack([np[].add(pts_center, offset) for offset in offsets])
        pts_num = pyconvert(Int, pts.shape[0])
        @info "filled with $(pts_num) particles"
    end
    return pts, [t1, t2, t3]
end