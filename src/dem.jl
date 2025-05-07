#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : dem.jl                                                                     |
|  Description: Generate particles from a given DEM file                                   |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. IDW!                                                                   |
|               02. rasterizeDEM                                                           |
|               03. dem2particle                                                           |
|               04. getpolygon                                                             |
+==========================================================================================#

export dem2particle
export rasterizeDEM
export getpolygon

include(joinpath(@__DIR__, "_dem/_utils.jl"))

"""
    IDW!(k, p, dem, idxs, ptslist, tree)

Description:
---
Inverse Distance Weighting (IDW) interpolation method. `k` is the number of nearest 
neighbors, `p` is the power parameter, `dem` is a coordinates Array with three columns 
`(x, y, z)`, `idxs` is the index of the nearest neighbors, `ptslist` is the coordinates 
Array of the particles, `tree` is the KDTree of the DEM.
"""
@views function IDW!(
    k      ::T1, 
    p      ::T1, 
    dem    ::AbstractMatrix{T2}, 
    idxs   ::AbstractMatrix{T1}, 
    ptslist::AbstractMatrix{T2}, 
    tree   ::KDTree
) where {T1, T2}
    @inbounds Threads.@threads for i in axes(ptslist, 1)
        idxs[i, :] .= knn(tree, ptslist[i, 1:2], k, true)[1]
        weighted_sum = T2(0.0)
        weight_total = T2(0.0)
        for j in 1:k
            dx = dem[idxs[i, j], 1] - ptslist[i, 1]
            dy = dem[idxs[i, j], 2] - ptslist[i, 2]
            distance = sqrt(dx * dx + dy * dy)
            if distance ≤ 1e-6
                ptslist[i, 3] = dem[idxs[i, j], 3]
                break
            else
                weight = inv(distance^p)
                weighted_sum += weight * dem[idxs[i, j], 3]
                weight_total += weight
            end
        end
        # safty check
        if weight_total > 1e-6
            ptslist[i, 3] = weighted_sum / weight_total
        else
            ptslist[i, 3] = sum(dem[idxs[i, :], 3]) / k
        end
    end
    return nothing
end

"""
    rasterizeDEM(dem, h; k=10, p=2, trimbounds=[0.0 0.0], dembounds=[0.0, 0.0])

Description:
---
Rasterize the DEM file to generate particles. `dem` is a coordinates Array with three 
columns `(x, y, z)`. `h` is the space of the cloud points in `x` and `y` directions, 
normally it is equal to the grid size in the MPM simulation. `k` is the number of nearest 
neighbors (10 by default), `p` is the power parameter (2 by default), `trimbounds` is the 
boundary of the particles, `dembounds` is the boundary of the DEM.
"""
@views function rasterizeDEM(
    dem       ::AbstractMatrix{T2},
    h         ::T2; 
    k         ::T1        = 10, 
    p         ::T1        = 2, 
    trimbounds::AbstractMatrix{T2}= [0.0 0.0], 
    dembounds ::AbstractVector{T2}= [0.0, 0.0]
) where {T1, T2}
    # check input arguments
    size(dem, 2) ≠ 3 && throw(ArgumentError("DEM should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("h must be positive"))
    dembounds ≠ [0.0, 0.0] && length(dembounds) ≠ 4 && throw(ArgumentError(
        "dembounds must have 4 elements: [xmin, xmax, ymin, ymax]"))
    size(trimbounds, 2) ≠ 2 && throw(ArgumentError("trimbounds must have 2 columns"))

    # get particles from DEM domain
    if dembounds ≠ [0.0, 0.0]
        (dembounds[1] > dembounds[2] && dembounds[3] > dembounds[4]) && throw(ArgumentError(
            "dembounds must have [xmin, xmax, ymin, ymax]"))
        @info "DEM domain is specified"
        dem_xmin, dem_xmax = dembounds[1], dembounds[2]
        dem_ymin, dem_ymax = dembounds[3], dembounds[4]
    else
        dem_xmin, dem_xmax = minimum(dem[:, 1]), maximum(dem[:, 1])
        dem_ymin, dem_ymax = minimum(dem[:, 2]), maximum(dem[:, 2])
    end
    ξ0 = meshbuilder(dem_xmin : h : dem_xmax, dem_ymin : h : dem_ymax)
    if trimbounds ≠ [0.0 0.0]
        @info "trimming particles outside the trimbounds"
        pts = size(ξ0, 1)
        rst = Vector{Bool}(undef, pts) 
        @inbounds Threads.@threads for i in 1:pts
            px = ξ0[i, 1]
            py = ξ0[i, 2]
            rst[i] = particle_in_polygon(px, py, trimbounds)
        end
        ξ0 = ξ0[findall(rst), :]
    end
    ptslist = hcat(ξ0, zeros(T2, size(ξ0, 1)))

    # create KDTree for DEM
    tree = KDTree(dem[:, 1:2]')
    idxs = zeros(T1, size(ptslist, 1), k)
    IDW!(k, p, dem, idxs, ptslist, tree)

    # move the models to the grid (space = h)
    @. ptslist[:, 3] = ceil(ptslist[:, 3] / h) * h
    
    return sort_pts_xy(ptslist)
end

@views function rasterizeDEM(
    dem    ::AbstractMatrix{T2},
    h      ::T2,
    polygon::AbstractMatrix{T2}; 
    k      ::Int = 10, 
    p      ::Int = 2
) where T2
    pypolygon = Polygon(np.array(polygon))
    # check input arguments
    size(dem, 2) ≠ 3 && throw(ArgumentError("DEM should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("h must be positive"))

    # get particles from DEM domain
    dem_xmin, dem_xmax = minimum(dem[:, 1]), maximum(dem[:, 1])
    dem_ymin, dem_ymax = minimum(dem[:, 2]), maximum(dem[:, 2])

    # trim the boundary based on the polygon
    ξ0 = meshbuilder(dem_xmin : h : dem_xmax, dem_ymin : h : dem_ymax)
    x_test = np.array(ξ0[:, 1])
    y_test = np.array(ξ0[:, 2])
    v_in_id = pyconvert(Vector, v_contains(pypolygon, x_test, y_test))
    ptslist = hcat(ξ0[v_in_id, :], zeros(T2, count(v_in_id)))

    # create KDTree for DEM
    tree = KDTree(dem[:, 1:2]')
    idxs = zeros(Int, size(ptslist, 1), k)
    IDW!(k, p, dem, idxs, ptslist, tree)

    # move the models to the grid (space = h)
    @. ptslist[:, 3] = ceil(ptslist[:, 3] / h) * h
    
    return ptslist
end

function getpolygon(pts::AbstractMatrix; ratio=0.1)
    pts_col = size(pts, 2)
    if pts_col == 2
        points = pts
    elseif pts_col == 3
        points = pts[:, 1:2]
    else
        throw(ArgumentError("points must be a Nx2 or Nx3 array"))
    end
    point_polygon = concavehull(points, ratio, false)
    return point_polygon.data
end

"""
    dem2particle(dem, h, bottom)

Description: 
---
Generate particles from a given DEM file. `dem` is a coordinates Array with three columns 
(x, y, z). `h` is the space of particles in `z` direction, normally it is equal to the grid 
size in the MPM simulation. `bottom` is a value, which means the plane `z = bottom`.
"""
@views function dem2particle(
    dem   ::AbstractMatrix{T2}, 
    h     ::T2, 
    bottom::T2
) where T2
    # values check
    T1 = T2 == Float32 ? Int32 : Int64
    size(dem, 2) == 3 || throw(ArgumentError("DEM should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    bottom < minimum(dem[:, 3]) || throw(ArgumentError(
        "The bottom coord $(bottom) is higher than the dem ($(minimum(dem[:, 3])))"))

    # move the model to the z = 0 plane
    dem[:, 3] .-= bottom

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        ptslength[i] = ceil(T1, dem[i, 3] / h)
    end

    # create the particles
    pts_cen = zeros(T2, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in axes(dem, 1)
        x, y = dem[i, 1], dem[i, 2]
        for j in 1:ptslength[i]
            pts_cen[v+j, 1] = x
            pts_cen[v+j, 2] = y
            pts_cen[v+j, 3] = (j - 1) * h
        end
        v += ptslength[i]
    end

    # move the model back to the original position
    pts_cen[:, 3] .+= (h * T2(0.5)) .+ bottom

    # populate the particles in each cell
    pts = populate_pts(pts_cen, h)
    return pts
end

"""
    dem2particle(dem, h, bottom, layer)

Description:
---
Generate particles from a given DEM file and a bottom value (flat bottom surface). `dem` is 
a coordinates Array with three columns (x, y, z), and the `bottom` value should be lower
than the dem. `h` is the space of grid size in `z` direction used in the MPM simulation.
`layer` is a Vector of Matrix with three columns (x, y, z), which represents the layer
surfaces. Note that layers are sorted from top to bottom.
"""
@views function dem2particle(
    dem   ::AbstractMatrix{T2}, 
    h     ::T2, 
    bottom::T2,
    layer ::AbstractVector{AbstractMatrix{T2}}
) where T2
    # values check
    T1 = T2 == Float32 ? Int32 : Int64
    size(dem, 2) == 3 || throw(ArgumentError("DEM should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    bottom < minimum(dem[:, 3]) || throw(ArgumentError(
        "The bottom coord $(bottom) is higher than the dem ($(minimum(dem[:, 3])))"))
    layer_num = length(layer)
    dem = sort_pts_xy(dem)
    for i in 1:layer_num layer[i] = sort_pts_xy(layer[i]) end
    for i in 1:layer_num
        dem[:, 1:2] == layer[i][:, 1:2] || throw(ArgumentError(
            "The layer $i should have the same x, y coordinates as the DEM"))        
    end
    layer_num > 1 && all.(layer[i][:, 3] .≤ layer[i + 1][:, 3] for i in 1:length(layer) - 1)

    # move the model to the z = 0 plane
    dem[:, 3] .-= bottom
    for i in eachindex(layer) layer[i][:, 3] .-= bottom end

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        ptslength[i] = ceil(T1, dem[i, 3] / h)
    end

    # create the particles
    pts_cen = zeros(T2 , Int(sum(ptslength)), 3)
    pts_nid = zeros(Int, Int(sum(ptslength)))

    v = 0
    @inbounds for i in axes(dem, 1)
        x, y = dem[i, 1], dem[i, 2]
        for j in 1:ptslength[i]
            z = (j - 1) * h
            pts_cen[v+j, 1] = x
            pts_cen[v+j, 2] = y
            pts_cen[v+j, 3] = z

            # if z > layer[1][i, 3] 
            #     pts_nid[v+j] = 1
            # elseif layer[1][i, 3] ≥ z > layer[2][i, 3]
            #     pts_nid[v+j] = 2
            # elseif layer[2][i, 3] ≥ z > layer[3][i, 3]
            #     pts_nid[v+j] = 3
            # else 
            #     pts_nid[v+j] = 4
            # end

            n_layers = length(layer)
            found = false
            
            # 处理第一个条件：z > layer[1][i,3]
            if z > layer[1][i,3]
                pts_nid[v+j] = 1
                found = true
            else
                # 遍历中间层（layer[2]到layer[end-1]）
                for k in 2:(n_layers-1)
                    if layer[k-1][i,3] >= z > layer[k][i,3]
                        pts_nid[v+j] = k
                        found = true
                        break
                    end
                end
            end
            
            # 处理最后一个区间和else分支
            if !found
                if n_layers >= 2 && layer[n_layers-1][i,3] >= z > layer[n_layers][i,3]
                    pts_nid[v+j] = n_layers
                else
                    pts_nid[v+j] = n_layers + 1
                end
            end
        end
        v += ptslength[i]
    end

    # move the model back to the original position
    pts_cen[:, 3] .+= (h * T2(0.5)) .+ bottom

    # populate the particles in each cell
    pts = populate_pts(pts_cen, h)
    nid = repeat(pts_nid, inner=8)

    return pts, nid
end


"""
    dem2particle(dem, h, bottom)

Description:
---
Generate particles from a given DEM file and a bottom surface file. `dem` is a coordinates 
Array with three columns (x, y, z), which has to be initialized with the struct `DEMSurface`. 
`bottom::DEMSurface` should have the same x and y coordinates as the DEM, and the z value should be lower
than the dem. `h` is the space of grid size in `z` direction used in the MPM simulation.
"""
@views function dem2particle(
    dem   ::AbstractMatrix{T2}, 
    h     ::T2, 
    bottom::AbstractMatrix{T2}
) where T2
    # values check
    T1 = T2 == Float32 ? Int32 : Int64
    size(dem, 2) == 3 || throw(ArgumentError("DEM should have three columns: x, y, z"))
    size(bottom, 2) == 3 || throw(ArgumentError("Bottom should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    all(bottom[:, 3] .< dem[:, 3]) || throw(ArgumentError(
        "The bottom surface should be lower than the DEM"))
    all(dem[:, 1:2] .== bottom[:, 1:2]) || throw(ArgumentError(
        "The bottom should have the same x and y coordinates as the dem"))

    # move the models to the z = 0 plane
    z_oft = minimum(bottom[:, 3])
    bottom[:, 3] .-= z_oft
    dem[:, 3] .-= z_oft

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        bt = floor(T1, bottom[i, 3] / h) * h
        bottom[i, 3] = bt
        ptslength[i] = ceil(T1, (dem[i, 3] - bt) / h)
    end

    # create the particles
    pts_cen = zeros(T2, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in axes(dem, 1)
        x, y, z = dem[i, 1], dem[i, 2], bottom[i, 3]
        for j in 1:ptslength[i]
            pts_cen[v+j, 1] = x
            pts_cen[v+j, 2] = y
            pts_cen[v+j, 3] = z + (j - 1) * h
        end
        v += ptslength[i]
    end

    # move the model back to the original position
    pts_cen[:, 3] .+= (h * 0.5) .+ z_oft

    # populate the particles in each cell
    pts = populate_pts(pts_cen, h)
    return pts
end

"""
    dem2particle(dem, h, bottom, layer)

Description:
---
Generate particles from a given DEM file and a bottom surface file. `dem` is a coordinates
Array with three columns (x, y, z), and the z value should be lower than the `dem`. `h` is 
the space of grid size in `z` direction used in the MPM simulation. `layer` is a Vector of 
Matrix with three columns (x, y, z), which represents the layer surfaces. Note that layers 
are sorted from top to bottom.
"""
@views function dem2particle(
    dem   ::AbstractMatrix{T2}, 
    h     ::T2, 
    bottom::AbstractMatrix{T2},
    layer ::Vector{Matrix{T2}}
) where T2
    # values check
    T1 = T2 == Float32 ? Int32 : Int64
    size(dem, 2) == 3 || throw(ArgumentError("DEM should have three columns: x, y, z"))
    size(bottom, 2) == 3 || throw(ArgumentError("Bottom should have three columns: x, y, z"))
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    all(bottom[:, 3] .< dem[:, 3]) || throw(ArgumentError(
        "The bottom surface should be lower than the DEM"))
    all(dem[:, 1:2] .== bottom[:, 1:2]) || throw(ArgumentError(
        "The bottom should have the same x and y coordinates as the dem"))
    layer_num = length(layer)
    dem = sort_pts_xy(dem)
    for i in 1:layer_num layer[i] = sort_pts_xy(layer[i]) end
    for i in 1:layer_num
        dem[:, 1:2] == layer[i][:, 1:2] || throw(ArgumentError(
            "The layer $i should have the same x, y coordinates as the DEM"))        
    end
    layer_num > 1 && all.(layer[i][:, 3] .≤ layer[i + 1][:, 3] for i in 1:length(layer) - 1)

    # move the models to the z = 0 plane
    z_oft = minimum(bottom[:, 3])
    bottom[:, 3] .-= z_oft
    dem[:, 3] .-= z_oft
    for i in eachindex(layer) layer[i][:, 3] .-= z_oft end

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        bt = floor(T1, bottom[i, 3] / h) * h
        bottom[i, 3] = bt
        ptslength[i] = ceil(T1, (dem[i, 3] - bt) / h)
    end

    # create the particles
    pts_cen = zeros(T2, Int(sum(ptslength)), 3)
    pts_nid = zeros(Int, Int(sum(ptslength)))
    v = 0
    @inbounds for i in axes(dem, 1)
        x, y, z = dem[i, 1], dem[i, 2], bottom[i, 3]
        for j in 1:ptslength[i]
            zp = z + (j - 1) * h
            pts_cen[v+j, 1] = x
            pts_cen[v+j, 2] = y
            pts_cen[v+j, 3] = zp

            n_layers = length(layer)
            found = false
            
            # 处理第一个条件：zp > layer[1][i,3]
            if zp > layer[1][i,3]
                pts_nid[v+j] = 1
                found = true
            else
                # 遍历中间层（layer[2]到layer[end-1]）
                for k in 2:(n_layers-1)
                    if layer[k-1][i,3] >= zp > layer[k][i,3]
                        pts_nid[v+j] = k
                        found = true
                        break
                    end
                end
            end
            
            # 处理最后一个区间和else分支
            if !found
                if n_layers >= 2 && layer[n_layers-1][i,3] >= zp > layer[n_layers][i,3]
                    pts_nid[v+j] = n_layers
                else
                    pts_nid[v+j] = n_layers + 1
                end
            end
        end
        v += ptslength[i]
    end

    # move the model back to the original position
    pts_cen[:, 3] .+= (h * 0.5) .+ z_oft

    # populate the particles in each cell
    pts = populate_pts(pts_cen, h)
    nid = repeat(pts_nid, inner=8)
    return pts, nid
end