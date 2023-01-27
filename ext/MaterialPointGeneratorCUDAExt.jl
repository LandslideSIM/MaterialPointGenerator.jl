module MaterialPointGeneratorCUDAExt

using CUDA
using KernelAbstractions
using Printf
using MaterialPointGenerator

import MaterialPointGenerator: polyhedron2particle, gmsh_mesh3D, particle_in_polyhedron!

CUDA.allowscalar(false) # disable scalar operation on NVIDIA GPU

function polyhedron2particle(msh_path::String, lpx, lpy, lpz, ::Val{:CUDA})
    local node, tet
    @MPGsuppress node, tet = gmsh_mesh3D(msh_path)
    # terminal info
    @info """Gmsh results
    number of nodes     : $(size(node, 1))
    number of tetrahedra: $(size(tet, 1))
    """
    # get bounding box for particles
    min_x, max_x = minimum(node[:, 1]), maximum(node[:, 1])
    min_y, max_y = minimum(node[:, 2]), maximum(node[:, 2])
    min_z, max_z = minimum(node[:, 3]), maximum(node[:, 3])
    # generate structured particles
    pts      = meshbuilder(min_x:lpx:max_x, min_y:lpy:max_y, min_z:lpz:max_z)
    np       = size(pts, 1)
    rst      = Vector{Bool}(zeros(np))
    dev_pts  = CuArray(pts)
    dev_node = CuArray(node)
    dev_tet  = CuArray(tet)
    dev_rst  = CuArray(rst)
    particle_in_polyhedron!(CUDABackend())(ndrange=np, dev_pts, dev_node, dev_tet, dev_rst)
    copyto!(rst, dev_rst)
    CUDA.unsafe_free!(dev_pts)
    CUDA.unsafe_free!(dev_node)
    CUDA.unsafe_free!(dev_tet)
    CUDA.unsafe_free!(dev_rst)
    CUDA.reclaim()
    return copy(pts[findall(rst), :])
end

end