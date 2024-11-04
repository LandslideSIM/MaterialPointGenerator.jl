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
|               03. sortbycol                                                              |
+==========================================================================================#

export savexyz
export readxyz
export sortbycol

"""
    savexyz(file_dir::P, pts::T) where {P <: String, T <: Array{Float64, 2}}

Description:
---
Save the points `pts` to the xyz file `file_dir`.
"""
function savexyz(file_dir::P, pts::T) where {P <: String, T <: Array{Float64, 2}}
    open(file_dir, "w") do io
        writedlm(io, pts, '\t')
    end
end

"""
    readxyz(file_dir::P) where P <: String

Description:
---
Read the xyz file from `file_dir`.
"""
function readxyz(file_dir::P) where P <: String
    return readdlm(file_dir, '\t', Float64)
end

"""
    sortbycol(pts, col::T) where T <: Int

Description:
---
Sort the points in `pts` according to the column `col`.
"""
function sortbycol(pts, col::T) where T <: Int
    return pts[sortperm(pts[:, col]), :]
end