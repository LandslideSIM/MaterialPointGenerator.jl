#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : _utils.jl                                                                  |
|  Description: Generate particles from a given DEM file                                   |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. insolidbase                                                            |
+==========================================================================================#

export insolidbase

function insolidbase(mp::Matrix{T2}, surf::Matrix{T2}, nv::Matrix{T2}) where T2
    # input bounds check
    size(surf) == size(nv) || throw(DimensionMismatch(
        "surf and nv must have the same size"))
    size(mp, 2) == 3 || throw(DimensionMismatch("mp must have 3 columns"))
    # create a kdtree for the surface / prepare memory for traversing
    kdtree = KDTree(surf')
    id = ones(Bool, size(mp, 1))
    neighbornum = 2
    idt = ones(Bool, size(mp, 1), neighbornum)
    # check if the material point is inside the solid
    @inbounds Threads.@threads for i in axes(mp, 1)
        x, y, z = mp[i, 1], mp[i, 2], mp[i, 3]
        point = @view mp[i, :]
        index, _ = knn(kdtree, point, neighbornum)
        for j in 1:neighbornum
            surf_id = index[j]
            nx, ny, nz = nv[surf_id, 1], nv[surf_id, 2], nv[surf_id, 3]
            sx, sy, sz = surf[surf_id, 1], surf[surf_id, 2], surf[surf_id, 3]
            vx, vy, vz = x - sx, y - sy, z - sz
            dot_val = vx * nx + vy * ny + vz * nz
            if dot_val < 0
                idt[i, j] = false
            end
        end
        id[i] = all(idt[i, :])==false ? false : true
    end
    return mp[findall(id), :]
end