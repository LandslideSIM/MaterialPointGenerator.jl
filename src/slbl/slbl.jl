#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : slbl.jl                                                                    |
|  Description: SLBL implementation                                                        |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. SLBL3D                                                                 |
+==========================================================================================#

export SLBL3D

"""
    addmask(pts::AbstractMatrix, h::Real)

Description:
---
- This function generates a bounding box grid based on the current DEM range, and attaches 
them to the corresponding nodes of the grid for easy indexing.  
- The first return value is the coordinates of the entire grid, the second return value is 
the node labels: 1 for internal nodes, 2 for boundary nodes, and 0 for external nodes.  
- The third return value is the number of nodes in the grid along the y-direction.
"""
@views function addmask(pts::AbstractMatrix, h::Real)

    x1, x2 = minimum(pts[:, 1]) - h*2, maximum(pts[:, 1]) + h*2
    y1, y2 = minimum(pts[:, 2]) - h*2, maximum(pts[:, 2]) + h*2

    gridxy = meshbuilder(x1:h:x2, y1:h:y2)
    gridz  = zeros(size(gridxy, 1))

    x1, x2 = minimum(gridxy[:, 1]), maximum(gridxy[:, 1])
    y1, y2 = minimum(gridxy[:, 2]), maximum(gridxy[:, 2])
    ny = Int(div(y2-y1, h) + 1)

    b_id = zeros(Int, size(gridxy, 1))
    @inbounds for i in axes(pts, 1)
        px, py, pz = pts[i, 1], pts[i, 2], pts[i, 3]
        ni = Int(div((px-x1), h)) * ny + Int(div((py-y1), h) + 1)
        b_id[ni] = 1
        gridz[ni] = pz
    end
    v_id = findall(b_id .== 1)
    @inbounds for i in v_id
        if b_id[i+1] == 0 || b_id[i-1] == 0 || b_id[i-ny] == 0 || b_id[i+ny] == 0
            b_id[i] = 2
        end
    end
    grid = Array(hcat(gridxy, gridz))
    return grid, b_id, ny
end

@views function SLBL3D(dem::AbstractMatrix, h::Real, zmax::Real, L::Real)
    size(dem, 2) == 3 || throw(ArgumentError("dem must be a Nx3 array"))
    h > 0 || throw(ArgumentError("h must be positive"))
    zmax ≠ 0 || throw(ArgumentError("zmax cannot be zero"))
    L > 0 || throw(ArgumentError("L must be positive"))

    c = 4 * ((zmax/L) / L) * h * h
    grid_c, b_id, ny = addmask(dem, h)
    grid_p = copy(grid_c)
    v_id = findall(b_id .== 1)
    @info "got mask, c is $(c)"

    if zmax > 0
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

            iter_c = maximum(abs.(grid_p[:, 3] .- grid_c[:, 3])) < 1e-4 ? false : true
            grid_p .= grid_c
        end
    else
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

    vid = findall(b_id .≠ 0)
    return Array(grid_c[vid, :])
end