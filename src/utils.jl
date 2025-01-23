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
|               04. savexy                                                                 |
|               05. savexyz                                                                |
|               06. readxy                                                                 |
|               07. readxyz                                                                |
|               08. sortbycol                                                              |
|               09. sortbycol!                                                             |
|               10. csv2geo2d                                                              |
|               11. sort_pts                                                               |
|               12. sort_pts_xy                                                            |
|               13. populate_pts                                                           |
+==========================================================================================#

export fastvtp
export savexy
export savexyz
export readxy
export readxyz
export sortbycol
export sortbycol!
export csv2geo2d
export sort_pts
export sort_pts_xy
export populate_pts

"""
    fastvtp(coords; vtp_file="output.vtp", data::T=NamedTuple())

Description:
---
Generates a `.vtp` file by passing custom fields.
"""
function fastvtp(coords; vtp_file="output.vtp", data::T=NamedTuple()) where T <: NamedTuple
    pts_num = size(coords, 1)
    vtp_cls = [MeshCell(PolyData.Verts(), [i]) for i in 1:pts_num]
    vtk_grid(vtp_file, coords', vtp_cls, ascii=false) do vtk
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
    savexy(file_dir::P, pts::T) where {P <: String, T <: AbstractMatrix}

Description:
---
Save the 2D points `pts` to the `.xy` file (`file_dir`).
"""
function savexy(file_dir::P, pts::T) where {P <: String, T <: AbstractMatrix}
    size(pts, 2) == 2 || throw(ArgumentError("The input points should have 2 columns."))
    open(file_dir, "w") do io
        writedlm(io, pts, ' ')
    end
end

"""
    savexyz(file_dir::P, pts::T) where {P <: String, T <: AbstractMatrix}

Description:
---
Save the 3D points `pts` to the `.xyz` file (`file_dir`).
"""
function savexyz(file_dir::P, pts::T) where {P <: String, T <: AbstractMatrix}
    size(pts, 2) == 3 || throw(ArgumentError("The input points should have 3 columns."))
    open(file_dir, "w") do io
        writedlm(io, pts, ' ')
    end
end

"""
    readxy(file_dir::P) where P <: String

Description:
---
Read the 2D `.xy` file from `file_dir`.
"""
function readxy(file_dir::P) where P <: String
    xy = readdlm(file_dir, ' ')[:, 1:2]
    return Float64.(xy)
end

"""
    readxyz(file_dir::P) where P <: String

Description:
---
Read the 3D `.xyz` file from `file_dir`.
"""
function readxyz(file_dir::P) where P <: String
    xyz = readdlm(file_dir, ' ')[:, 1:3]
    return Float64.(xyz)
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

function sortbycol!(pts, col::T) where T <: Int
    tmp = @views pts[sortperm(pts[:, col]), :]
    pts .= tmp
end

"""
    csv2geo2d(csv_file::String, geo_file::String)

Description:
---
Convert the CSV file (.csv) to the Gmsh geo (.geo) file.
"""
function csv2geo2d(csv_file::String, geo_file::String)
    if csv_file[end-3 : end] ≠ ".csv" || geo_file[end-3 : end] ≠ ".geo"
        st1 = "The input file should be a CSV file (.csv)"
        st2 = "The output file should be a Gmsh geo file (.geo)"
        throw(ArgumentError(st1 * "\n" * st2))
    end
    data = readdlm(csv_file, ',')
    open(geo_file, "w") do file
        write(file, "lc = 1.0;\n\n")
        for (id, row) in enumerate(eachrow(data))
            x, y = row
            write(file, "Point($id) = {$x, $y, 0, lc};\n")
        end
    end
    @info ".geo saved at $geo_file"
    return nothing
end

"""
    sort_pts(pts::Matrix)

Description:
---
Sort the points in pts by the (z-), y-, and x-coordinates, in that order (2/3D).
"""
function sort_pts(pts::Matrix)
    if size(pts, 2) == 2
        idx = sortperm(eachrow(pts), by=row -> (row[2], row[1]))
    elseif size(pts, 2) == 3
        idx = sortperm(eachrow(pts), by=row -> (row[3], row[2], row[1]))
    else
        throw(ArgumentError("The input points should have 2 or 3 columns (2/3D)"))
    end
    return pts[idx, :]
end


"""
    sort_pts_xy(pts::Matrix)

Description:
---
Sort the points in pts by the x- and y-coordinates, in that order.
"""
function sort_pts_xy(pts::Matrix)
    idx = sortperm(eachrow(pts), by=row -> (row[1], row[2]))
    return pts[idx, :]
end

"""
    populate_pts(pts_cen, h)

Description:
---
Populate the points around the center points `pts_cen` with the spacing `h/4` (2/3D).
"""
@views function populate_pts(pts_cen::Matrix{T}, h::T) where T
    oft = T(h * 0.25)
    N, D = size(pts_cen)
    if D == 3
        offsets = [-oft oft oft; -oft oft  -oft; -oft -oft oft; -oft -oft -oft;
                    oft oft oft;  oft oft  -oft;  oft -oft oft;  oft -oft -oft]
        pts = Matrix{T}(undef, 8*N, D)
        @inbounds for i in axes(pts_cen, 1)
            start_idx = (i - 1) * 8 + 1
            for j in 1:8
                pts[start_idx + j - 1, :] .= pts_cen[i, :] .+ offsets[j, :]
            end
        end
    elseif D == 2
        offsets = [-oft oft; -oft -oft; oft oft; oft -oft]
        pts = Matrix{T}(undef, 4*N, D)
        @inbounds for i in axes(pts_cen, 1)
            start_idx = (i - 1) * 4 + 1
            for j in 1:4
                pts[start_idx + j - 1, :] .= pts_cen[i, :] .+ offsets[j, :]
            end
        end
    else
        throw(ArgumentError("The input points should have 2 or 3 columns (2/3D)"))
    end
    return pts
end