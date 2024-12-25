#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : dem.jl                                                                     |
|  Description: Generate particles from a given DEM file                                   |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. DEMSurface                                                             |
|               02. IDW!                                                                   |
|               03. rasterizeDEM                                                           |
|               04. dem2particle                                                           |
+==========================================================================================#

export DEMSurface
export dem2particle
export rasterizeDEM

struct DEMSurface{T1, T2}
    coord::Matrix{T2}
    count::T1
end

function DEMSurface(coord; ϵ="FP64")
    T1 = ϵ == "FP32" ?   Int32 :   Int64
    T2 = ϵ == "FP32" ? Float32 : Float64

    size(coord, 2) == 3 || throw(ArgumentError("The coordinates should have 3 columns"))

    all(unique(coord, dims=1) .== coord) || throw(ArgumentError(
        "The coordinates should be unique on X-Y plane"))

    return DEMSurface{T1, T2}(coord, size(coord, 1))
end

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
    dem    ::DEMSurface{T1, T2}, 
    idxs   ::Matrix{T1}, 
    ptslist::Matrix{T2}, 
    tree   ::KDTree
) where {T1, T2}
    @inbounds Threads.@threads for i in axes(ptslist, 1)
        idxs[i, :] .= knn(tree, ptslist[i, 1:2], k, true)[1]
        weighted_sum = 0.0
        weight_total = 0.0
        for j in 1:k
            dx = dem.coord[idxs[i, j], 1] - ptslist[i, 1]
            dy = dem.coord[idxs[i, j], 2] - ptslist[i, 2]
            distance = sqrt(dx * dx + dy * dy)
            if distance ≤ 1e-6
                ptslist[i, 3] = dem.coord[idxs[i, j], 3]
                break
            else
                weight = 1.0 / distance^p
                weighted_sum += weight * dem.coord[idxs[i, j], 3]
                weight_total += weight
            end
        end
        # safty check
        if weight_total > 1e-6
            ptslist[i, 3] = weighted_sum / weight_total
        else
            ptslist[i, 3] = sum(dem.coord[idxs[i, :], 3]) / k
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
    dem       ::DEMSurface{T1, T2},
    h         ::T2; 
    k         ::T1        = 10, 
    p         ::T1        = 2, 
    trimbounds::Matrix{T2}= [0.0 0.0], 
    dembounds ::Vector{T2}= [0.0, 0.0]
) where {T1, T2}
    # check input arguments
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
        dem_xmin, dem_xmax = minimum(dem.coord[:, 1]), maximum(dem.coord[:, 1])
        dem_ymin, dem_ymax = minimum(dem.coord[:, 2]), maximum(dem.coord[:, 2])
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
    tree = KDTree(dem.coord[:, 1:2]')
    idxs = zeros(T1, size(ptslist, 1), k)
    IDW!(k, p, dem, idxs, ptslist, tree)

    # move the models to the grid (space = h)
    @. ptslist[:, 3] = ceil(ptslist[:, 3] / h) * h
    
    return ptslist
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
    dem   ::DEMSurface{T1, T2}, 
    h     ::T2, 
    bottom::T2
) where {T1, T2}
    # values check
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    bottom < minimum(dem.coord[:, 3]) || throw(ArgumentError(
        "The bottom coord $(bottom) is higher than the dem ($(minimum(dem[:, 3])))"))

    # move the model to the z = 0 plane
    dem.coord[:, 3] .-= bottom

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, dem.count)
    @inbounds for i in 1:dem.count
        ptslength[i] = ceil(T1, dem.coord[i, 3] / h)
    end

    # create the particles
    pts_cen = zeros(T2, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in 1:dem.count
        x, y = dem.coord[i, 1], dem.coord[i, 2]
        for j in 1:ptslength[i]
            pts_cen[v+j, 1] = x
            pts_cen[v+j, 2] = y
            pts_cen[v+j, 3] = (j - 1) * h
        end
        v += ptslength[i]
    end

    # move the model back to the original position
    pts_cen[:, 3] .+= (h * 0.5) .+ bottom

    # populate the particles in each cell
    pts = populate_pts(pts_cen, h)
    return pts
end


"""
    dem2particle(dem, lpz, bottom_surf)

Description:
---
Generate particles from a given DEM file and a bottom surface file. `dem` is a coordinates 
Array with three columns (x, y, z). `bottom_surf` is a coordinates Array with three columns,
but it should have the same x and y coordinates as the DEM, and the z value should be lower
than the DEM. `h` is the space of grid size in `z` direction used in the MPM simulation.
"""
@views function dem2particle(
    dem   ::DEMSurface{T1, T2}, 
    h     ::T2, 
    bottom::DEMSurface{T1, T2}
) where {T1, T2}
    # values check
    h > 0 || throw(ArgumentError("The cloud point space on z: $(h) should be positive"))
    all(bottom.coord[:, 3] .< dem.coord[:, 3]) || throw(ArgumentError(
        "The bottom surface should be lower than the DEM"))
    all(dem.coord[:, 1:2] .== bottom.coord[:, 1:2]) || throw(ArgumentError(
        "The bottom should have the same x and y coordinates as the dem"))

    # move the models to the z = 0 plane
    z_oft = minimum(bottom.coord[:, 3])
    bottom.coord[:, 3] .-= z_oft
    dem.coord[:, 3] .-= z_oft

    # calculate the number of particles in z direction
    ptslength = Vector{T1}(undef, dem.count)
    @inbounds for i in 1:dem.count
        bt = floor(T1, bottom.coord[i, 3] / h) * h
        bottom.coord[i, 3] = bt
        ptslength[i] = ceil(T1, (dem.coord[i, 3] - bt) / h)
    end

    # create the particles
    pts_cen = zeros(T2, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in 1:dem.count
        x, y, z = dem.coord[i, 1], dem.coord[i, 2], bottom.coord[i, 3]
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