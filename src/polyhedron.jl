#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : polyhedron.jl                                                              |
|  Description: Generate structured mesh in 3D space by a given polyhedron                 |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. polyhedron2particle                                                    |
|               02. trimesh_voxelize                                                       |
+==========================================================================================#

export polyhedron2particle

struct GmshMesh{T1, T2}
    vertices :: Array{T2, 2}
    faces    :: Array{T1, 2}
    data     :: Vector{Vector{T2}}
    bounds   :: Vector{T2}
end

rs_dir = joinpath(@__DIR__, "_polyhedron")
include(joinpath(rs_dir, "_utils.jl"   ))
include(joinpath(rs_dir, "_workflow.jl"))

"""
    polyhedron2particle(stl_file::String, output_file, h; method::String="voxel", 
        verbose::Bool=false)

Description:
---
Convert a polyhedron (`.stl`) to a set of particles. The function will write the populated 
particles of each voxel into a `.xyz` file. The voxel size is defined by `h`, it is suggest
to be equal to the MPM background grid size. `method` can be "voxel" or "ray" in string.The 
`verbose` is a flag to show the time consumption of each step.

Example:
---
```julia
stl_file = "/path/to/your/model.stl"
output_file = "/path/to/your/model.xyz"
h = 0.1
polyhedron2particle(stl_file, output_file, h, verbose=true)
```
"""
function polyhedron2particle(
    stl_file   ::String, 
    output_file::String, 
    h          ::Real; 
    method     ::String="voxel",
    verbose    ::Bool  =false
)
    # inputs check
    method in ["voxel", "ray"] || throw(ArgumentError("method must be 'voxel' or 'ray'"))
    h > 0 || throw(ArgumentError("h must be positive"))

    # implementations
    if method == "voxel"
        @pyexec """
        def getparticle(stl_path: str, voxel_resolution: float, output_xyz: str,
                trimesh, pygmsh, np, pyKDTree, pytime):

            t1_start = pytime.perf_counter()

            stl_mesh = trimesh.load(stl_path)
            if not stl_mesh.is_watertight:
                trimesh.repair.fix_winding(stl_mesh)
                trimesh.repair.fill_holes(stl_mesh)
                print(f"STL is repaired (watertight: {stl_mesh.is_watertight})")

            print("\033[1;36m[ Info:\033[0m model loaded and checked (3D stl)")

            t1_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================
            
            t2_start = pytime.perf_counter()

            voxelized = stl_mesh.voxelized(pitch=voxel_resolution, edge_factor=1).fill()
            voxel_points = voxelized.points

            print("\033[1;36m[ Info:\033[0m 3D model is voxelized")

            t2_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================

            t3_start = pytime.perf_counter()

            offset = voxel_resolution * 0.25
            offsets = np.array([[-offset, -offset, -offset],  # 左下后
                                [-offset, -offset,  offset],  # 左下前
                                [-offset,  offset, -offset],  # 左上前
                                [-offset,  offset,  offset],  # 左上后
                                [ offset, -offset, -offset],  # 右下后
                                [ offset, -offset,  offset],  # 右下前
                                [ offset,  offset, -offset],  # 右上前
                                [ offset,  offset,  offset]]) # 右上后
            pts = np.repeat(voxel_points, 8, axis=0) + np.tile(offsets, (len(voxel_points), 1))
            pts_num = len(pts)

            print(f"\033[1;36m[ Info:\033[0m filled with {pts_num} particles")

            t3_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================
            
            t4_start = pytime.perf_counter()

            # 保存结果
            np.savetxt(output_xyz, voxel_points, fmt="%.6f", delimiter=" ")

            t4_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================

            t1 = t1_end - t1_start
            t2 = t2_end - t2_start
            t3 = t3_end - t3_start
            t4 = t4_end - t4_start
            t5 = t1 + t2 + t3 + t4

            return [t1, t2, t3, t4, t5]
        """ => getparticle

        pytp = getparticle(stl_file, h, output_file,
            trimesh, pygmsh, np, pyKDTree, pytime)

        tp = pyconvert(Vector, pytp)

        t1, t2, t3, t4, tt = tp[1], tp[2], tp[3], tp[4], tp[5]

        if verbose
            @info """3D polyhedron
            - load model   : $(@sprintf("%6.2f", t1)) s | $(@sprintf("%6.2f", 100*t1/tt))%
            - voxelize     : $(@sprintf("%6.2f", t2)) s | $(@sprintf("%6.2f", 100*t2/tt))%
            - fill particle: $(@sprintf("%6.2f", t3)) s | $(@sprintf("%6.2f", 100*t3/tt))%
            - write .xyz   : $(@sprintf("%6.2f", t4)) s | $(@sprintf("%6.2f", 100*t4/tt))%
            $("-"^34)
            - total time   : $(@sprintf("%6.2f", tt)) s
            """
        end
    elseif method == "ray"
        t1 = @elapsed begin
            meshdata = readmesh(stl_file, precision="FP32")
        end
        t2 = @elapsed begin
            coords = _voxelize(meshdata, h)
        end
        t3 = @elapsed begin
            savexyz(joinpath(@__DIR__, output_file), coords)
        end
        tt = t1 + t2 + t3
        @info """ray casting
        - load model  : $(@sprintf("%6.2f", t1)) s | $(@sprintf("%6.2f", 100*t1/tt))%
        - ray casting : $(@sprintf("%6.2f", t2)) s | $(@sprintf("%6.2f", 100*t2/tt))%
        - write .xyz  : $(@sprintf("%6.2f", t3)) s | $(@sprintf("%6.2f", 100*t3/tt))%
        $("-"^34)
        - total time  : $(@sprintf("%6.2f", tt)) s
        """
    end

    return nothing
end

function polyhedron2particle(
    stl_file   ::String, 
    msh_file   ::String,
    output_file::String,
    nid_file   ::String, 
    h          ::Real; 
    method     ::String="voxel",
    verbose    ::Bool  =false
)
    if method == "voxel"
        @pyexec """
        def getparticle_msh(stl_path: str, msh_path: str, voxel_resolution: float, output_xyz: str, output_nid: str,
                trimesh, pygmsh, np, pyKDTree, pytime):

            t1_start = pytime.perf_counter()

            stl_mesh = trimesh.load(stl_path)
            if not stl_mesh.is_watertight:
                trimesh.repair.fix_winding(stl_mesh)
                trimesh.repair.fill_holes(stl_mesh)
                print(f"STL is repaired (watertight: {stl_mesh.is_watertight})")

            print("\033[1;36m[ Info:\033[0m model loaded and checked (3D stl)")

            t1_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================
            
            t2_start = pytime.perf_counter()

            voxelized = stl_mesh.voxelized(pitch=voxel_resolution, edge_factor=1).fill()
            voxel_points = voxelized.points

            print("\033[1;36m[ Info:\033[0m 3D model is voxelized")

            t2_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================

            t3_start = pytime.perf_counter()

            pygmsh.initialize()
            pygmsh.option.setNumber("General.Verbosity", 0)
            pygmsh.open(str(msh_path))
            
            polyhedrons = []
            for dim, tag in pygmsh.model.getPhysicalGroups():
                if dim != 2:  # 只处理表面
                    continue
                    
                group_name = pygmsh.model.getPhysicalName(dim, tag) or f"Group_dim{dim}_tag{tag}"
                entities = pygmsh.model.getEntitiesForPhysicalGroup(dim, tag)
                
                node_coords = {}
                triangles = []
                for entity in entities:
                    elem_types, _, node_tags = pygmsh.model.mesh.getElements(dim, entity)
                    for elem_type, nodes in zip(elem_types, node_tags):
                        if elem_type == 2:  # 三角形元素
                            nodes_array = np.array(nodes).reshape(-1, 3)
                            for tri_nodes in nodes_array:
                                triangles.append(tri_nodes)
                                for node in tri_nodes:
                                    if node not in node_coords:
                                        node_coords[node] = pygmsh.model.mesh.getNode(node)[0]
                
                if not triangles:
                    print(f"{group_name}: cannot find triangles")
                    continue
                    
                vertices = np.array(list(node_coords.values()))
                node_map = {node: i for i, node in enumerate(node_coords)}
                faces = np.array([[node_map[n] for n in tri] for tri in triangles])
                mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
                
                is_watertight = mesh.is_watertight
                if not is_watertight:
                    trimesh.repair.fix_winding(mesh)
                    trimesh.repair.fill_holes(mesh)
                    print(f"{group_name} is repaired (watertight: {mesh.is_watertight})")
                
                polyhedrons.append((group_name, mesh))
            
            pygmsh.finalize()

            # Step 3: 分配体素点到多面体
            voxel_group_assignments = np.full(len(voxel_points), "None", dtype=object)
            
            for group_name, mesh in polyhedrons:
                if mesh.is_watertight:
                    min_bound, max_bound = mesh.bounds
                    inside_box = np.all((voxel_points >= min_bound) & (voxel_points <= max_bound), axis=1)
                    points_in_box = voxel_points[inside_box]
                    
                    inside_mesh = mesh.contains(points_in_box)
                    indices_in_box = np.where(inside_box)[0]
                    voxel_group_assignments[indices_in_box[inside_mesh]] = group_name

            # Step 4: 为未分配的体素点赋予最近邻属性
            assigned_mask = voxel_group_assignments != "None"
            unassigned_mask = ~assigned_mask
            
            assigned_points = voxel_points[assigned_mask]
            assigned_groups = voxel_group_assignments[assigned_mask]
            unassigned_points = voxel_points[unassigned_mask]
            
            if len(unassigned_points) > 0 and len(assigned_points) > 0:
                tree = pyKDTree(assigned_points)
                distances, indices = tree.query(unassigned_points)
                nearest_groups = assigned_groups[indices]
                voxel_group_assignments[unassigned_mask] = nearest_groups
            elif len(assigned_points) == 0:
                print("There are no voxel points with assigned attributes")

            print("\033[1;36m[ Info:\033[0m physical groups are attached to particles")
            
            t3_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================

            t4_start = pytime.perf_counter()

            nid = np.repeat(voxel_group_assignments, 8)
            offset = voxel_resolution * 0.25
            offsets = np.array([[-offset, -offset, -offset],  # 左下后
                                [-offset, -offset,  offset],  # 左下前
                                [-offset,  offset, -offset],  # 左上前
                                [-offset,  offset,  offset],  # 左上后
                                [ offset, -offset, -offset],  # 右下后
                                [ offset, -offset,  offset],  # 右下前
                                [ offset,  offset, -offset],  # 右上前
                                [ offset,  offset,  offset]]) # 右上后
            pts = np.repeat(voxel_points, 8, axis=0) + np.tile(offsets, (len(voxel_points), 1))
            pts_num = len(pts)

            print(f"\033[1;36m[ Info:\033[0m filled with {pts_num} particles")

            t4_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================
            
            t5_start = pytime.perf_counter()

            # 保存结果
            np.savetxt(output_xyz, pts, fmt="%.6f", delimiter=" ")
            np.savetxt(output_nid, nid, fmt="%s", delimiter="\\n")

            t5_end = pytime.perf_counter()

            #===============================================================================
            #===============================================================================
            #===============================================================================

            t1 = t1_end - t1_start
            t2 = t2_end - t2_start
            t3 = t3_end - t3_start
            t4 = t4_end - t4_start
            t5 = t5_end - t5_start
            t6 = t1 + t2 + t3 + t4 + t5

            return [t1, t2, t3, t4, t5, t6]
        """ => getparticle_msh

        pytp = getparticle_msh(stl_file, msh_file, h, output_file, nid_file,
            trimesh, pygmsh, np, pyKDTree, pytime)

        tp = pyconvert(Vector, pytp)

        if verbose
            t1, t2, t3, t4, t5, tt = tp[1], tp[2], tp[3], tp[4], tp[5], tp[6]
            @info """3D polyhedron
            - load model    : $(@sprintf("%6.2f", t1)) s | $(@sprintf("%6.2f", 100*t1/tt))%
            - voxelize      : $(@sprintf("%6.2f", t2)) s | $(@sprintf("%6.2f", 100*t2/tt))%
            - attach nid    : $(@sprintf("%6.2f", t3)) s | $(@sprintf("%6.2f", 100*t3/tt))%
            - fill particle : $(@sprintf("%6.2f", t4)) s | $(@sprintf("%6.2f", 100*t4/tt))%
            - write .xy .nid: $(@sprintf("%6.2f", t5)) s | $(@sprintf("%6.2f", 100*t5/tt))%
            $("-"^36)
            - total time    : $(@sprintf("%6.2f", tt)) s
            """
        end
    elseif method == "ray"
        tp = trimesh_voxelize3D(stl_file, h)
    end

    return nothing
end