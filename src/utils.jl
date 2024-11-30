#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : utils.jl                                                                   |
|  Description: Some helper functions in this package                                      |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. fastvtp                                                                |
|               02. savedata                                                               |
|               03. readdata                                                               |
|               04. savexyz                                                                |
|               05. readxyz                                                                |
|               06. sortbycol                                                              |
+==========================================================================================#

export fastvtp
export savedata
export readdata
export savexyz
export readxyz
export sortbycol

"""
    fastvtp(coords; vtppath="output", data::T=NamedTuple())

Description:
---
Generates a `.vtp` file by passing custom fields.
"""
function fastvtp(coords; vtppath="output", data::T=NamedTuple()) where T <: NamedTuple
    pts_num = size(coords, 1)
    vtp_cls = [MeshCell(PolyData.Verts(), [i]) for i in 1:pts_num]
    vtk_grid(vtppath, coords', vtp_cls, ascii=false) do vtk
        keys(data) ≠ () && for vtp_key in keys(data)
            vtk[string(vtp_key)] = getfield(data, vtp_key)
        end
    end
    return nothing
end

"""
    savedata(file_dir::String, data)

Description:
---
Save the data `data` to the file `file_dir`.
"""
function savedata(file_dir::String, data)
    open(file_dir, "w") do io
        writedlm(io, data, '\t')
    end
end

"""
    readdata(file_dir::String)

Description:
---
Read the data from `file_dir`.
"""
function readdata(file_dir::String)
    data = readdlm(file_dir, '\t')
    data = size(data, 2) == 1 ? data[:] : data
    return data
end

"""
    savexyz(file_dir::P, pts::T) where {P <: String, T <: Array{Float64, 2}}

Description:
---
Save the points `pts` to the xyz file `file_dir`.
"""
function savexyz(file_dir::P, pts::T) where {P <: String, T <: Array{Float64, 2}}
    size(pts, 2) == 3 || throw(ArgumentError("The input points should have 3 columns."))
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
    xyz = readdlm(file_dir, '\t', Float64)
    size(xyz, 2) == 3 || throw(ArgumentError("The input file should have 3 columns."))
    return xyz
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