#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : dem.jl                                                                     |
|  Description: Generate particles from a given DEM file                                   |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. rbf_compute!                                                           |
|               02. surrogateDEM                                                           |
|               03. dem2particle                                                           |
+==========================================================================================#

export dem2particle
export surrogateDEM

"""
    rbf_compute!(ptslist, x2, rbf_model)

Description:
---
Compute the value of the RBF model at the given points. `ptslist` is a 2D array with three
columns (x, y, z). `x2` is a 1D array with two columns (x, y). `rbf_model` is a
`RadialBasis` model.
"""
@views function rbf_compute!(ptslist, x2, rbf_model::T) where T <: RadialBasis
    @inbounds Threads.@threads for i in axes(x2, 1)
        ptslist[i, 3] = rbf_model(x2[i])
    end
    return nothing
end

"""
    surrogateDEM(lpx, lpy, dem; trimbounds, dembounds)

Description:
---
Generate particles from a given DEM file. `lpx` and `lpy` are the space of particles in `x` 
and `y` directions, respectively. `dem` is a coordinates Array with three columns (x, y, z).
`trimbounds` is the bounding box of the particles, if not given, it will be the minimum and 
maximum of the DEM file. `dembounds` is the bounding box of the DEM file, this is for a DEM 
which is not a rectangle area, so `dembounds` represents the polygon of the DEM, the 
returned particles will be inside this polygon.
"""
@views function surrogateDEM(
    lpx, lpy, 
    dem       ::T2;
    trimbounds::T1 = [0.0],
    dembounds ::T2 = [0.0 0.0]
) where {T1 <: Array{Float64, 1}, T2 <: Array{Float64, 2}}
    if trimbounds == [0]
        trimbounds = [minimum(dem[:, 1]), maximum(dem[:, 1]), 
                      minimum(dem[:, 2]), maximum(dem[:, 2])]
    end
    ptslist = meshbuilder(trimbounds[1] : lpx : trimbounds[2], 
                          trimbounds[3] : lpy : trimbounds[4])
    x1 = Vector{Tuple{Float64, Float64}}(undef, size(dem    , 1))
    x2 = Vector{Tuple{Float64, Float64}}(undef, size(ptslist, 1))
    @inbounds for i in axes(dem, 1)
        x1[i] = (dem[i, 1], dem[i, 2])
    end
    @inbounds for i in axes(ptslist, 1)
        x2[i] = (ptslist[i, 1], ptslist[i, 2])
    end

    lb = [minimum(dem[:, 1]), minimum(dem[:, 2])]
    ub = [maximum(dem[:, 1]), maximum(dem[:, 2])]
    rbf_model = RadialBasis(x1, dem[:, 3], lb, ub, rad=cubicRadial())
    ptslist = hcat(ptslist, zeros(Float64, size(ptslist, 1)))
    rbf_compute!(ptslist, x2, rbf_model)

    if dembounds ≠ [0 0]
        vid = findall(i -> particle_in_polygon(ptslist[i, 1], ptslist[i, 2], dembounds), 
            1:size(ptslist, 1))
        return copy(ptslist[vid, :])
    else
        return ptslist
    end
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