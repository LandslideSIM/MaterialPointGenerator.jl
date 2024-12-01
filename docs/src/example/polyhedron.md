# Polyhedron

If your model is not a DEM but rather a more generalized 3D model, we recommend that you first use an STL file to create the 3D model entity. Please note that it is recommended to use MeshLab or other tools to check and ensure that the surface mesh forms a closed 3D entity. 

With MaterialPointGenerator.jl, we can easily accomplish this task by providing the STL file, specifying the output file (`.xyz`), and setting the voxel spacing. The basic idea is to voxelize the STL model and fill it with eight material particles. Therefore, the voxel spacing `lp` is recommended to match the grid spacing in MPM simulations. 

The voxelization of the STL model is handled by [trimesh](https://trimesh.org/); although we introduced a Python dependency, it is simple and efficient enough that users do not need to manually configure the Python environment. If you want to use your own Python env, please make sure [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl) can find your env and install the packages in the `CondaPkg.toml`.

Example:
```julia
stl_file = "/path/to/your/model.stl"
output_file = "/path/to/your/mode.xyz" # just give the path even it is not exist
lp = 2.5 # MPM grid size
polyhedron2particle(stl_file, output_file, lp, verbose=true) # verbose==true will show the time profile
pts = readxyz(output_file)
```