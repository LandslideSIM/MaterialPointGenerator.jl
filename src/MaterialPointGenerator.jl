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

using DelimitedFiles, CondaPkg, Gmsh, NearestNeighbors, PrecompileTools, Printf, PythonCall, 
      Suppressor, WriteVTK
      
import Suppressor.@suppress as @MPGsuppress
export @MPGsuppress

const trimesh     = Ref{Py}()
const voxelize_fn = Ref{Py}()
const np          = Ref{Py}()

function __init__()
    trimesh[] = pyimport("trimesh")
    np[]      = pyimport("numpy")
    voxelize_fn[] = @pyconst(trimesh[].voxel.creation.voxelize)
end

voxelize(mesh, pitch) = voxelize_fn[](mesh, pitch=pitch)

include(joinpath(@__DIR__, "meshgenerator.jl"))
include(joinpath(@__DIR__, "polygon.jl"      ))
include(joinpath(@__DIR__, "polyhedron.jl"   ))
include(joinpath(@__DIR__, "dem.jl"          ))
include(joinpath(@__DIR__, "utils.jl"        ))

@setup_workload begin
    const testassets = joinpath(@__DIR__, "../test/testsuit/testassets")
    @compile_workload begin
        @MPGsuppress begin
            # testdem.jl
            tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
            dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
            pts = dem2particle(dem, 0.5, -1.0)
            tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
            dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
            bot = copy(dem)
            bot[:, 3] .-= 1.0
            pts = dem2particle(dem, 0.5, bot)
            tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
            dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
            pts = rasterizeDEM(0.6, 0.6, dem)
            # testmeshgenerator.jl
            pts2d = meshbuilder(0:0.1:0.2, 0:0.1:0.2)
            pts3d = meshbuilder(0:0.1:0.1, 0:0.1:0.1, 0:0.1:0.1)
            # testpolygon.jl
            polygon = [0. 0.; 1  0; 1  1; 0  1]
            particle_in_polygon(0.5, 0.5, polygon)
            polygon2particle(polygon, 0.2, 0.2)
            # testpolyhedron.jl
            # polyhedron2particle(joinpath(testassets, "test.stl"), 0.5)
            # testutils.jl
            a = [1.2 2.3 5.0; 3.4 4.5 6.0; 5.6 6.7 7.0]
            savexyz(joinpath(testassets, "testutils.xyz"), a)
            b = readxyz(joinpath(testassets, "testutils.xyz"))
            rm(joinpath(testassets, "testutils.xyz"))
            a = [1 2 3; 2 1 5; 3 1 2]
            b = sortbycol(a, 3)
        end
    end
end;

end