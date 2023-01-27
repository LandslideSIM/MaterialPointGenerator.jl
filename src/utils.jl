#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : utils.jl                                                                   |
|  Description: Some helper functions in this package                                      |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. savexyz                                                                |
|               02. readxyz                                                                |
+==========================================================================================#

export savexyz
export readxyz

function savexyz(file_dir::P, pts::T) where {P <: String, T <: Array{Float64, 2}}
    open(file_dir, "w") do io
        writedlm(io, pts, '\t')
    end
end

function readxyz(file_dir::P) where P <: String
    return readdlm(file_dir, '\t', Float64)
end