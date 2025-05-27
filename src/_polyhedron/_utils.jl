@inline function cross2D(ax::T, ay::T, bx::T, by::T) where T
    return ax * by - ay * bx
end

@inline function in_tri(ABx::T, ABy::T, BCx::T, BCy::T, CAx::T, CAy::T, 
    v1x::T, v1y::T, v2x::T, v2y::T, v3x::T, v3y::T, px::T, py::T) where T

    # 计算AP, BP, CP向量
    APx = px - v1x
    APy = py - v1y
    BPx = px - v2x
    BPy = py - v2y
    CPx = px - v3x
    CPy = py - v3y

    # 分别计算叉积
    cross1 = cross2D(ABx, ABy, APx, APy)  # AB × AP
    cross2 = cross2D(BCx, BCy, BPx, BPy)  # BC × BP
    cross3 = cross2D(CAx, CAy, CPx, CPy)  # CA × CP

    # 如果 3 个叉积符号全非负，或者全非正，则点在三角形内或边上
    return ((cross1 ≥ 0 && cross2 ≥ 0 && cross3 ≥ 0) ||
            (cross1 ≤ 0 && cross2 ≤ 0 && cross3 ≤ 0))
end

@inline function intersect_z(v1x::T, v1y::T, v1z::T, v2x::T, v2y::T, v2z::T, v3x::T, v3y::T,
    v3z::T, px::T, py::T, mzmin::T, h::T) where T

    # 1) 计算三角形在 XY 平面的面积（用 2D 叉积）
    #    areaABC = cross( (v2 - v1), (v3 - v1) )，只用 x、y 分量
    areaABC = cross2D(v2x - v1x, v2y - v1y, v3x - v1x, v3y - v1y)

    # 2) 分别计算与顶点相关的子三角形面积比例
    #    alpha = area(P,B,C) / area(A,B,C)
    #    beta  = area(A,P,C) / area(A,B,C)
    #    gamma = 1 - alpha - beta
    #    其中 (P) 就是 (px, py)
    areaPBC = cross2D(v2x - px, v2y - py, v3x - px , v3y - py ) / areaABC
    areaAPC = cross2D(px - v1x, py - v1y, v3x - v1x, v3y - v1y) / areaABC

    α = areaPBC
    β = areaAPC
    γ = 1 - α - β

    # 3) 用 (alpha,beta,gamma) 插值三顶点的 z 值
    z = α*v1z + β*v2z + γ*v3z
    
    return floor((z - mzmin) / h) * h + mzmin
end

function check_projection!(meshdata::DataMesh{T1, T2}, h::T2, p2t::Vector, mxmin::T2, 
    mymin::T2, niy::T1) where {T1, T2}

    p2t = copy(p2t)
    @inbounds for i in axes(meshdata.data, 1)
        v1x, v1y = meshdata.data[i][1], meshdata.data[i][2]
        v2x, v2y = meshdata.data[i][4], meshdata.data[i][5] 
        v3x, v3y = meshdata.data[i][7], meshdata.data[i][8]
        ABx, ABy = v2x - v1x, v2y - v1y
        BCx, BCy = v3x - v2x, v3y - v2y
        CAx, CAy = v1x - v3x, v1y - v3y
        xmin, xmax = min(v1x, v2x, v3x), max(v1x, v2x, v3x)
        ymin, ymax = min(v1y, v2y, v3y), max(v1y, v2y, v3y)

        x1 = floor(T1, (xmin - mxmin) / h) * h + mxmin
        x2 = ceil( T1, (xmax - mxmin) / h) * h + mxmin
        y1 = floor(T1, (ymin - mymin) / h) * h + mymin
        y2 = ceil( T1, (ymax - mymin) / h) * h + mymin

        for px in x1:h:x2, py in y1:h:y2
            if in_tri(ABx, ABy, BCx, BCy, CAx, CAy, v1x, v1y, v2x, v2y, v3x, v3y, px, py)
                idx = ceil(T1, (py - mymin) / h) + 1 + ceil(T1, (px - mxmin) / h) * niy
                push!(p2t[idx], i)
            end
        end
    end

    return nothing
end

function fill_voxel!(pts::Vector{Bool}, p2t::Vector, meshdata::DataMesh{T1, T2}, niy::T1, 
    mxmin::T2, mymin::T2, mzmin::T2, mxmax::T2, mymax::T2, mzmax::T2, h::T2) where {T1, T2}

    @inbounds for i in axes(p2t, 1)
        if !isempty(p2t[i]) && length(p2t[i]) % 2 == 0
            px = floor(T1, i / niy) * h + mxmin
            py = (i - floor(T1, i / niy) * niy - 1) * h + mymin
            tri_order = Vector{T2}()
            for tri_id in p2t[i]
                # current triangle
                v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z = meshdata.data[tri_id]
                z = intersect_z(v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z, px, py, mzmin, 
                    h)
                push!(tri_order, z)
            end
            sort!(unique!(tri_order))
            #tri_order[  1] = ceil( T1, (tri_order[  1] - mzmin) / h) * h + mzmin
            #tri_order[end] = floor(T1, (tri_order[end] - mzmin) / h) * h + mzmin
            fill_layers!(pts, px, py, tri_order, mxmin, mymin, mzmin, mxmax, mymax, mzmax, 
                h)
        end
    end

    return nothing
end

@inline function fill_layers!(pts::Vector{Bool}, px::T2, py::T2, tri_order::Vector{T2}, 
    mxmin::T2, mymin::T2, mzmin::T2, mxmax::T2, mymax::T2, mzmax::T2, h::T2) where T2
   
    T1 = T2 == Float64 ? Int64 : Int32
    # 1) 计算网格在 x, y, z 三个维度上的节点数
    #    Nx = floor((mxmax - mxmin)/h) + 1 等
    Nx = floor(T1, (mxmax - mxmin) / h) + 1
    Ny = floor(T1, (mymax - mymin) / h) + 1
    Nz = floor(T1, (mzmax - mzmin) / h) + 1

    # 2) 根据 px, py 计算网格索引 (ix, iy)
    #    由于 px, py 已保证和网格对齐，可以直接 round 或 Int。
    #    注意Julia的数组下标从1开始，所以要 +1。
    ix = Int(round((px - mxmin)/h)) + 1
    iy = Int(round((py - mymin)/h)) + 1

    # 3) 遍历 tri_order 的区间对
    #    例如 tri_order = [z1,z2,z3,z4,...], 
    #    要处理 [z1,z2], [z3,z4], ...
    n_pairs = length(tri_order) ÷ 2  # tri_order长度的一半
    for i in 1:n_pairs
        z_low  = tri_order[2i - 1]
        z_high = tri_order[2i]

        # 3.1) 用步长 h 从 z_low 到 z_high 递增
        #      注意可能出现 z_low < mzmin 或 z_high > mzmax 的情况，可酌情clip一下
        z_start = max(z_low,  mzmin)
        z_end   = min(z_high, mzmax)

        # 如果 z_start > z_end，说明区间在网格之外，跳过
        if z_start > z_end
            continue
        end

        # 3.2) 遍历 z 值
        #      z_range = z_start:h:z_end 可能存在浮点末尾问题，故下面写法更稳健
        z_val = z_start
        while z_val <= z_end + 1e-12  # 容忍一点点浮点误差
            # 计算 z 索引
            iz = Int(round((z_val - mzmin)/h)) + 1

            # 边界检查(若要更严格)
            if iz >= 1 && iz <= Nz
                # 计算线性索引(假设存储顺序是 pts[ix, iy, iz] in Fortran-order)
                # 一种常见的列优先索引映射：
                # idx = ix + (iy-1)*Nx + (iz-1)*Nx*Ny
                idx = ix + (iy-1)*Nx + (iz-1)*Nx*Ny

                # 激活
                pts[idx] = true
            end

            z_val += h
        end
    end

    return nothing# 没有特别返回值，pts 已经就地修改
end

function getpts(pts::Vector{Bool}, Nx::T1, Ny::T1, Nz::T1, h::T2, mxmin::T2, mymin::T2, 
    mzmin::T2) where {T1, T2}

    M = count(pts)  # 激活节点的总数
    M == 0 && return error("No active points found")

    # 分配 M×3 的矩阵，行表示点、列表示坐标
    coords = Matrix{T2}(undef, M, 3)

    current_row = 1
    for iz in 1:Nz
        z = mzmin + (iz - 1) * h
        for iy in 1:Ny
            y = mymin + (iy - 1) * h
            for ix in 1:Nx
                x = mxmin + (ix - 1) * h

                idx = ix + (iy - 1) * Nx + (iz - 1) * Nx * Ny
                if pts[idx]
                    coords[current_row, 1] = x
                    coords[current_row, 2] = y
                    coords[current_row, 3] = z
                    current_row += 1
                end
            end
        end
    end

    return coords
end