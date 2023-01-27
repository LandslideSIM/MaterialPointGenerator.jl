module MaterialPointGeneratorMetalExt

using Metal
using KernelAbstractions
using Printf
using MaterialPointGenerator

import MaterialPointGenerator: polyhedron2particle, gmsh_mesh3D, particle_in_polyhedron!

Metal.allowscalar(false) # disable scalar operation on Apple GPU

function polyhedron2particle(msh_path::String, lpx, lpy, lpz, ::Val{:Metal})
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
    dev_pts  = MtlArray(pts)
    dev_node = MtlArray(node)
    dev_tet  = MtlArray(tet)
    dev_rst  = MtlArray(rst)
    particle_in_polyhedron!(MetalBackend())(ndrange=np, dev_pts, dev_node, dev_tet, dev_rst)
    copyto!(rst, dev_rst)
    Metal.unsafe_free!(dev_pts)
    Metal.unsafe_free!(dev_node)
    Metal.unsafe_free!(dev_tet)
    Metal.unsafe_free!(dev_rst)
    return copy(pts[findall(rst), :])
end

end