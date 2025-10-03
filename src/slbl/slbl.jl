#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : slbl.jl                                                                    |
|  Description: SLBL implementation                                                        |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. SLBL3D                                                                 |
|               02. get_volume                                                             |
+==========================================================================================#

export SLBL3D
export get_volume

"""
    SLBL3D(dem::AbstractMatrix, polygon::QueryPolygon, zmax::Real, L::Real; C::Real=-1)

Description:
---
The SLBL3D function implements the SLBL method for 3D DEM.

- `dem`: A Nx3 matrix representing the DEM surface, where N is the number of points. Each 
row contains the x, y, z coordinates of a point.
- `polygon`: An instance of type `QueryPolygon`, can be obtained by api `get_polygon`.
- `zmax`: A real number representing the maximum height of the failure surface. If `zmax`
is greater than 0, the function calculates the failure surface; if `zmax` is less than 0,
it calculates the reconstruction surface.
- `L`: A real number representing the length scale of the SLBL method.
- `C`: A real number representing the constant in the SLBL method. If `C` is set to -1,
it will be calculated based on the `zmax` and `L` values. Default is -1.
"""
@views function SLBL3D(
    dem    ::AbstractMatrix, 
    polygon::QueryPolygon, 
    zmax   ::Real, 
    L      ::Real; 
    C      ::Real=-1,
    ϵ      ::Real=-1
)
    # inputs check
    dem = sort_pts(dem, z=false)
    size(dem, 2) == 3 || throw(ArgumentError("dem must be a Nx3 array"))
    zmax ≠ 0 || throw(ArgumentError("zmax cannot be zero"))
    L > 0 || throw(ArgumentError("L must be positive"))

    # get dem space
    sp = sort(unique(dem[:, 1]))
    h = sp[2] - sp[1]

    # compute the C value in the SLBL method
    c = C == -1 ? (4 * ((zmax/L) / L) * h * h) : C
    
    # get valid particle id for the SLBL
    v_id = findall(pip_query(polygon, dem[:, 1:2], edge=false))
    grid_c = copy(dem)
    grid_p = copy(dem)
    ny = length(unique(dem[:, 2]))

    # SLBL calculation
    if zmax > 0 # failure surface
        iter_c = true; while iter_c
            Threads.@threads for i in v_id
                n_u = i + 1
                n_d = i - 1
                n_l = i - ny
                n_r = i + ny

                z_temp = (grid_p[n_u, 3] + grid_p[n_d, 3] +
                          grid_p[n_l, 3] + grid_p[n_r, 3]) * 0.25 - c

                grid_c[i, 3] = z_temp < grid_p[i, 3] ? z_temp : grid_c[i, 3]
            end

            cϵ = ϵ == -1 ? 1e-4 : ϵ

            iter_c = maximum(abs.(grid_p[:, 3] .- grid_c[:, 3])) < cϵ ? false : true
            #@info maximum(abs.(grid_p[:, 3] .- grid_c[:, 3]))

            grid_p .= grid_c
        end
    else # reconstruction surface
        iter_c = true; while iter_c
            for i in v_id
                n_u = i + 1
                n_d = i - 1
                n_l = i - ny
                n_r = i + ny

                z_temp = (grid_p[n_u, 3] + grid_p[n_d, 3] +
                          grid_p[n_l, 3] + grid_p[n_r, 3]) * 0.25 - c

                grid_c[i, 3] = z_temp > grid_p[i, 3] ? z_temp : grid_c[i, 3]
            end

            iter_c = maximum(abs.(grid_c[:, 3] .- grid_p[:, 3])) < 1e-4 ? false : true
            grid_p .= grid_c
        end
    end

    dem_before = sort_pts(dem, z=false)
    dem_after = sort_pts(grid_c, z=false)

    if zmax > 0
        all(dem_after[:, 3] .≤ dem_before[:, 3]) || throw(ArgumentError(
            "The failure surface is not valid"))
    else
        all(dem_after[:, 3] .≥ dem_before[:, 3]) || throw(ArgumentError(
            "The reconstruction surface is not valid"))
    end

    vol = 0.0
    @inbounds for i in axes(dem, 1)
        vol += (dem_after[i, 3] - dem_before[i, 3]) * h^2
    end
    
    infotxt = "$(length(v_id)) particles have been selected for the SLBL"
    @info """SLBL calculator
    $("─"^(length(infotxt)))
      zmax --- $(zmax)
         c --- $(c)
         L --- $(L)
    volume --- $(abs(vol)) m³
    $("─"^(length(infotxt)))
    $(infotxt)
    """

    return dem_after
end

@views function SLBL3D(
    dem    ::AbstractMatrix, 
    polygon::QueryPolygon, 
    zmax   ::Real, 
    L      ::Real,
    plane  ::Function; 
    C      ::Real=-1
)
    # inputs check
    dem = sort_pts(dem, z=false)
    size(dem, 2) == 3 || throw(ArgumentError("dem must be a Nx3 array"))
    zmax ≠ 0 || throw(ArgumentError("zmax cannot be zero"))
    L > 0 || throw(ArgumentError("L must be positive"))

    # get dem space
    sp = sort(unique(dem[:, 1]))
    h = sp[2] - sp[1]

    # compute the C value in the SLBL method
    c = C == -1 ? (4 * ((zmax/L) / L) * h * h) : C
    
    # get valid particle id for the SLBL
    v_id = pip_query(polygon, dem[:, 1:2])
    grid_c = copy(dem)
    grid_p = copy(dem)
    ny = length(unique(dem[:, 2]))

    # SLBL calculation
    if zmax > 0 # failure surface
        iter_c = true; while iter_c
            for i in v_id
                n_u = i + 1
                n_d = i - 1
                n_l = i - ny
                n_r = i + ny

                z_temp = (grid_p[n_u, 3] + grid_p[n_d, 3] +
                          grid_p[n_l, 3] + grid_p[n_r, 3]) * 0.25 - c

                grid_c[i, 3] = z_temp < grid_p[i, 3] ? z_temp : grid_c[i, 3]
            end

            z_diff = maximum(abs.(grid_p[:, 3] .- grid_c[:, 3]))
            if z_diff < 1e-4
                iter_c = false
            else
                @inbounds for i in axes(grid_c, 1)
                    if plane(grid_c[i, 1], grid_c[i, 2], grid_c[i, 3])
                        iter_c = false
                        break
                    end
                end
            end

            grid_p .= grid_c
        end
    else # reconstruction surface
        iter_c = true; while iter_c
            for i in v_id
                n_u = i + 1
                n_d = i - 1
                n_l = i - ny
                n_r = i + ny

                z_temp = (grid_p[n_u, 3] + grid_p[n_d, 3] +
                          grid_p[n_l, 3] + grid_p[n_r, 3]) * 0.25 - c

                grid_c[i, 3] = z_temp > grid_p[i, 3] ? z_temp : grid_c[i, 3]
            end

            _, i = findmax(grid_c[:, 3])
            if (maximum(abs.(grid_c[:, 3] .- grid_p[:, 3])) < 1e-4) ||
               (plane(grid_c[i, 1], grid_c[i, 2], grid_c[i, 3]))
                iter_c = false
            end

            grid_p .= grid_c
        end
    end

    dem_before = sort_pts(dem, z=false)
    dem_after = sort_pts(grid_c, z=false)

    if zmax > 0
        all(dem_after[:, 3] .≤ dem_before[:, 3]) || throw(ArgumentError(
            "The failure surface is not valid"))
    else
        all(dem_after[:, 3] .≥ dem_before[:, 3]) || throw(ArgumentError(
            "The reconstruction surface is not valid"))
    end

    vol = 0.0
    @inbounds for i in axes(dem, 1)
        vol += (dem_after[i, 3] - dem_before[i, 3]) * h^2
    end
    
    infotxt = "$(length(v_id)) particles have been selected for the SLBL"
    @info """SLBL calculator
    $("─"^(length(infotxt)))
      zmax --- $(zmax)
         c --- $(c)
         L --- $(L)
    volume --- $(abs(vol)) m³
    $("─"^(length(infotxt)))
    $(infotxt)
    """

    return dem_after
end

"""
    get_volume(dem1::AbstractMatrix, dem2::AbstractMatrix)

Description:
---
Calculate the volume between two DEMs. The two DEMs must have the same x-y coordinates, and
the z-coordinates of `dem1` must be greater than or equal to the z-coordinates of `dem2`
or vice versa.

`dem1` and `dem2` are Nx3 matrices, where N is the number of points, and each row contains
the x, y, z coordinates of a point. Note that `dem1` and `dem2` should be rasterized.
"""
@views function get_volume(dem1::AbstractMatrix, dem2::AbstractMatrix)
    # inputs check
    dem1[:, 1:2] == dem2[:, 1:2] || throw(ArgumentError(
        "dem1 and dem2 must have the same x-y coordinates"))
    (all(dem1[:, 3] .≥ dem2[:, 3]) || all(dem1[:, 3] .≤ dem2[:, 3])) || throw(ArgumentError(
        "dem1 should be totally the upper surface of dem2 or vice versa"))

    # get dem space and area on the x-y plane    
    pts = unique(sort(dem1[:, 1]))   
    vol = 0.0
    h_2 = (pts[2] - pts[1])^2

    # accumulate the volume
    @inbounds for i in axes(dem1, 1)
        vol += h_2 * (dem1[i, 3] - dem2[i, 3])
    end

    return abs(vol)
end
