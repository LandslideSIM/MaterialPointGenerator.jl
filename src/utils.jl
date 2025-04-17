#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : utils.jl                                                                   |
|  Description: Some helper functions in this package                                      |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. savedata                                                               |
|               02. readdata                                                               |
|               03. savexy                                                                 |
|               04. savexyz                                                                |
|               05. readxy                                                                 |
|               06. readxyz                                                                |
|               07. sortbycol                                                              |
|               08. sortbycol!                                                             |
|               09. csv2geo2d                                                              |
|               10. sort_pts                                                               |
|               11. sort_pts_xy                                                            |
|               12. populate_pts                                                           |
|               13. stl2geo                                                                |
|               14. getnormals                                                             |
+==========================================================================================#

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
export stl2geo
export getnormals

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
    @info """.geo file saved at: 
    $geo_file
    """
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

function stl2geo(stl_file::String, geo_file::String; lc::Real=1)
    mesh = readmesh(stl_file)
    open(geo_file, "w") do f
        # 写入全局特征长度
        println(f, "lc = $lc;")
        # 1. 写入所有点
        N = size(mesh.vertices, 2)  # 点数
        for i in 1:N
            x, y, z = mesh.vertices[:, i]
            println(f, "Point($i) = {$x, $y, $z, lc};")
        end
        # 2. 提取唯一边
        edges = Set{Tuple{Int, Int}}()
        for face in eachcol(mesh.faces)
            a, b, c = face
            # 将边定义为 (小索引, 大索引) 以确保唯一性
            push!(edges, tuple(min(a, b), max(a, b)))
            push!(edges, tuple(min(b, c), max(b, c)))
            push!(edges, tuple(min(c, a), max(c, a)))
        end
        unique_edges = collect(edges)
        # 3. 为每条边分配线编号
        line_dict = Dict{Tuple{Int, Int}, Int}()
        line_id = 1
        for edge in unique_edges
            line_dict[edge] = line_id
            # 写入线定义
            p, q = edge
            println(f, "Line($line_id) = {$p, $q};")
            line_id += 1
        end
        # 4. 为每个三角形定义线循环和平面
        M = size(mesh.faces, 2)  # 三角形数
        for m in 1:M
            a, b, c = mesh.faces[:, m]
            # 计算每条边的有向线编号
            signed_lines = Int[]
            for (p, q) in [(a, b), (b, c), (c, a)]
                if p < q
                    # 方向与线定义一致
                    push!(signed_lines, line_dict[(p, q)])
                else
                    # 方向相反
                    push!(signed_lines, -line_dict[(q, p)])
                end
            end
            # 写入线循环
            println(f, "Line Loop($m) = {$(signed_lines[1]), $(signed_lines[2]), $(signed_lines[3])};")
            # 写入平面
            println(f, "Plane Surface($m) = {$m};")
        end
        # 5. 定义表面循环
        surface_tags = join(1:M, ", ")
        println(f, "Surface Loop(1) = {$surface_tags};")
        # 6. 定义体
        println(f, "Volume(1) = {1};")
    end
    return nothing
end

"""
    getnormals(points::Matrix{<:Real}; k::Int=10)

Description:
---
Compute the external normals of the points using the k-nearest method.

 - The input points should be a `N×3` array.
 - The output normals will be a `N×3` array.
"""
@views function getnormals(points::Matrix{<:Real}; k::Int=10)
    # check input points
    n, pts_dim = size(points)
    pts_dim == 3 || error("Points data must be a N×3 array")
    n > 10 || error("The input must have more than 10 points")
    (typeof(k) == Int && k > 0) || error("k must be a positive integer")
    
    # create KDTree for nearest neighbor search
    tree = KDTree(points')
    idxs, _ = knn(tree, points', k, true)
    
    # pre-allocate arrays
    normals    = zeros(n, 3)
    neighbors  = zeros(k, 3)
    centered   = zeros(k, 3)
    cov_matrix = zeros(3, 3)
    
    # compute unit external normal vector
    @inbounds for i in axes(points, 1)
        # find k nearest neighbors
        neighbors .= points[idxs[i], :]
        # compute centroid
        centroid = mean(neighbors, dims=1)
        centered .= neighbors .- centroid
        # calculate the covariance matrix (more efficient)
        mul!(cov_matrix, centered', centered)
        cov_matrix ./= k
        # eigenvalue decomposition
        eigvals, eigvecs = eigen(Symmetric(cov_matrix))  # 使用 Symmetric 优化
        # get normal vector
        min_idx = argmin(eigvals)
        normal = eigvecs[:, min_idx]
        # make sure it is outward facing
        normal[3] < 0 ? (normal = -normal) : nothing
        # save the result
        normals[i, :] .= normalize(normal)
    end
    
    return normals
end