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

using DelimitedFiles, CondaPkg, Gmsh, NearestNeighbors, Printf, PythonCall

const trimesh      = PythonCall.pynew()
const np           = PythonCall.pynew()
const MultiPolygon = PythonCall.pynew()
const Polygon      = PythonCall.pynew()
const Point        = PythonCall.pynew()
const mapping      = PythonCall.pynew()
const unary_union  = PythonCall.pynew()
const rasterio     = PythonCall.pynew()
const rasterize    = PythonCall.pynew()
const pygmsh       = PythonCall.pynew()
const pyKDTree     = PythonCall.pynew()
const pytime       = PythonCall.pynew()
const embreex      = PythonCall.pynew()

function __init__()
    @info "checking environment..."
    # import Python modules
    PythonCall.pycopy!(trimesh , pyimport("trimesh" ))
    PythonCall.pycopy!(np      , pyimport("numpy"   ))
    PythonCall.pycopy!(rasterio, pyimport("rasterio"))
    PythonCall.pycopy!(pygmsh  , pyimport("gmsh"    ))
    PythonCall.pycopy!(pytime  , pyimport("time"    ))
    # import their submudules
    PythonCall.pycopy!(Polygon     , pyimport("shapely.geometry" ).Polygon     )
    PythonCall.pycopy!(Point       , pyimport("shapely.geometry" ).Point       )
    PythonCall.pycopy!(mapping     , pyimport("shapely.geometry" ).mapping     )
    PythonCall.pycopy!(unary_union , pyimport("shapely.ops"      ).unary_union )
    PythonCall.pycopy!(rasterize   , pyimport("rasterio.features").rasterize   )
    PythonCall.pycopy!(pyKDTree    , pyimport("scipy.spatial"    ).cKDTree     )
    PythonCall.pycopy!(MultiPolygon, pyimport("shapely.geometry" ).MultiPolygon)
    if !Sys.isapple()
        try 
            if !haskey(CondaPkg.current_pip_packages(), "embreex")
                CondaPkg.add_pip("embreex")
                CondaPkg.resolve()
            end
            PythonCall.pycopy!(embreex, pyimport("embreex"))
            @info "embreex loaded"
        catch e
            @warn """embreeX - Python Wrapper for Embree
            1) cannot find compatible version
            2) some features will fall back to native Python code
            """
        end
    else 
        @warn """embreeX - Python Wrapper for Embree
        1) not supported on MacOS arm and x86
        2) some features will fall back to native Python code
        """
    end
end

include(joinpath(@__DIR__, "meshgenerator.jl"))
include(joinpath(@__DIR__, "polygon.jl"      ))
include(joinpath(@__DIR__, "polyhedron.jl"   ))
include(joinpath(@__DIR__, "dem.jl"          ))
include(joinpath(@__DIR__, "utils.jl"        ))

end