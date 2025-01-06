#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : MaterialPointGenerator.jl                                                  |
|  Description: Module file of MaterialPointGenerator.jl                                   |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  License    : MIT License                                                                |
+==========================================================================================#

module MaterialPointGenerator

using DelimitedFiles, CondaPkg, Gmsh, NearestNeighbors, Printf, PythonCall, WriteVTK

const trimesh     = Ref{Py}()
const voxelize_fn = Ref{Py}()
const np          = Ref{Py}()
const meshio      = Ref{Py}()
const embreex     = Ref{Py}()

function __init__()
    @info "checking environment..."
    if Sys.ARCH ≠ :aarch64
        CondaPkg.add_pip("embreex")
        embreex[] = pyimport("embreex")
    end
    trimesh[]     = pyimport("trimesh")
    np[]          = pyimport("numpy")
    meshio[]      = pyimport("meshio")
    voxelize_fn[] = @pyconst(trimesh[].voxel.creation.voxelize)
end

voxelize(mesh, pitch) = voxelize_fn[](mesh, pitch=pitch, edge_factor=1.0)

include(joinpath(@__DIR__, "meshgenerator.jl"))
include(joinpath(@__DIR__, "polygon.jl"      ))
include(joinpath(@__DIR__, "polyhedron.jl"   ))
include(joinpath(@__DIR__, "dem.jl"          ))
include(joinpath(@__DIR__, "utils.jl"        ))
end