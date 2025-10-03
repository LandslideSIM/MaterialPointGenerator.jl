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

using DelimitedFiles, Logging, FastPointQuery, NearestNeighbors, Printf
using LiveServer: serve
using PrecompileTools: @setup_workload, @compile_workload

include(joinpath(@__DIR__, "reexport.jl"  ))
include(joinpath(@__DIR__, "polygon.jl"   ))
include(joinpath(@__DIR__, "polyhedron.jl"))
include(joinpath(@__DIR__, "utils.jl"     ))
include(joinpath(@__DIR__, "dem.jl"))
include(joinpath(@__DIR__, "slbl/slbl.jl"    ))
include(joinpath(@__DIR__, "slbl/slbl_gui.jl"))

quiet(f) = redirect_stdout(devnull) do
    redirect_stderr(devnull) do
        with_logger(NullLogger()) do
            f()
        end
    end
end

include(joinpath(@__DIR__, "precompile.jl"))

end