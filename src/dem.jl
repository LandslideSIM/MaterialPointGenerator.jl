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
+==========================================================================================#

export dem2particle
export rasterizeDEM

"""
    IDW!(k, p, dem, idxs, ptslist, tree)

Description:
---
Inverse Distance Weighting (IDW) interpolation method. `k` is the number of nearest 
neighbors, `p` is the power parameter, `dem` is a coordinates Array with three columns 
`(x, y, z)`, `idxs` is the index of the nearest neighbors, `ptslist` is the coordinates 
Array of the particles, `tree` is the KDTree of the DEM.
"""
@views function IDW!(k::Int, p::Int, dem, idxs, ptslist, tree::KDTree)
    @inbounds Threads.@threads for i in axes(ptslist, 1)
        idxs[i, :] .= knn(tree, ptslist[i, 1:2], k, true)[1]
        weighted_sum = 0.0
        weight_total = 0.0
        for j in 1:k
            dx = dem[idxs[i, j], 1] - ptslist[i, 1]
            dy = dem[idxs[i, j], 2] - ptslist[i, 2]
            distance = sqrt(dx * dx + dy * dy)
            if distance ≤ 1e-6
                ptslist[i, 3] = dem[idxs[i, j], 3]
                break
            else
                weight = 1.0 / distance^p
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
    rasterizeDEM(lpx, lpy, dem; k=10, p=2, trimbounds=[0.0 0.0], dembounds=[0.0, 0.0])

Description:
---
Rasterize the DEM file to generate particles. `lpx` and `lpy` are the space of particles in
`x` and `y` directions. `dem` is a coordinates Array with three columns `(x, y, z)`. `k` is 
the number of nearest neighbors (10 by default), `p` is the power parameter (2 by default), 
`trimbounds` is the boundary of the particles, `dembounds` is the boundary of the DEM.
"""
@views function rasterizeDEM(
    lpx, lpy, dem::T1; k::Int=10, p::Int=2, 
    trimbounds::T1 = [0.0 0.0], dembounds::T2 = [0.0, 0.0]
) where {T1 <: Array{Float64, 2}, T2 <: Array{Float64, 1}}
    dem_xmin = minimum(dem[:, 1])
    dem_xmax = maximum(dem[:, 1])
    dem_ymin = minimum(dem[:, 2])
    dem_ymax = maximum(dem[:, 2])
    # get particles from DEM domain
    if dembounds ≠ [0.0, 0.0]
        @info "DEM domain is specified"
        dem_xmin = dembounds[1]
        dem_xmax = dembounds[2]
        dem_ymin = dembounds[3]
        dem_ymax = dembounds[4]
    end
    ξ0 = meshbuilder(dem_xmin : lpx : dem_xmax, dem_ymin : lpy : dem_ymax)
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
    ptslist = hcat(ξ0, zeros(Float64, size(ξ0, 1)))
    # create KDTree for DEM
    tree = KDTree(dem[:, 1:2]')
    idxs = zeros(Int64, size(ptslist, 1), k)
    IDW!(k, p, dem, idxs, ptslist, tree)
    return ptslist
end

"""
    dem2particle(dem, lpz, bottom)

Description:
---
Generate particles from a given DEM file. `dem` is a coordinates Array with three columns 
(x, y, z). `lpz` is the space of particles in `z` direction. `bottom` is a `Float64` value,
which means the plane `z = bottom`.
"""
@views function dem2particle(dem, lpz::T, bottom::T) where T <: Float64
    # values check
    bottom ≤ minimum(dem[:, 3]) || throw(ArgumentError(
        "The bottom coord $(bottom) is higher than the DEM ($minimum(dem[:, 3]))"))
    lpz > 0 || throw(ArgumentError("The particle space on z: $(lpz) should be positive")) 
    # calculate the number of particles in z direction
    ptslength = Vector{Int64}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        ptslength[i] = length(dem[i, 3] : -lpz : bottom)
    end
    pts = zeros(Float64, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in axes(dem, 1)
        x = dem[i, 1]
        y = dem[i, 2]
        z = dem[i, 3]
        for j in 1:ptslength[i]
            pts[v+j, 1] = x
            pts[v+j, 2] = y
            pts[v+j, 3] = z - j * lpz
        end
        v += ptslength[i]
    end
    return pts
end

"""
    dem2particle(dem, lpz, bottom_surf)

Description:
---
Generate particles from a given DEM file and a bottom surface file. `dem` is a coordinates 
Array with three columns (x, y, z). `bottom_surf` is a coordinates Array with three columns,
but it should have the same x and y coordinates as the DEM, and the z value should be lower
than the DEM. `lpz` is the space of particles in `z` direction.
"""
@views function dem2particle(dem::T, lpz, bottom_surf::T) where T <: Array{Float64, 2}
    # values check
    bottom_surf[:, 1:2] == dem[:, 1:2] || throw(ArgumentError(
        "The bottom surface should have the same x and y coordinates as the DEM"))
    all(bottom_surf[:, 3] .≤ dem[:, 3]) || throw(ArgumentError(
        "The bottom surface should be lower than the DEM"))
    lpz > 0 || throw(ArgumentError("The particle space on z: $(lpz) should be positive")) 
    # calculate the number of particles in z direction
    ptslength = Vector{Int64}(undef, size(dem, 1))
    @inbounds for i in axes(dem, 1)
        ptslength[i] = length(dem[i, 3] : -lpz : bottom_surf[i, 3])
    end
    pts = zeros(Float64, Int(sum(ptslength)), 3)
    v = 0
    @inbounds for i in axes(dem, 1)
        x = dem[i, 1]
        y = dem[i, 2]
        z = dem[i, 3]
        for j in 1:ptslength[i]
            pts[v+j, 1] = x
            pts[v+j, 2] = y
            pts[v+j, 3] = z - j * lpz
        end
        v += ptslength[i]
    end
    return pts
end