# 3D Point Cloud

In this case, we will have the point cloud from scanning. Here we save all the points into 
`.xyz` file. 

- Step 1. We need to rasterize the point cloud in [cloudcompare](https://www.danielgm.net/cc/).
- Step 2. Export the rasterized point cloud into `.xyz`.
- Step 3. Use MPMPtsGen.jl to generate MPM model.

!!! warning
    In step 1, we need to 1) comfirm the effective area of point cloud, 2) define the space/
    cell number on X-Y plane.

!!! warning
    When we use cloudcompare to export .xyz file, maybe it will also include more info. The 
    input file for MPMPtsGen.jl only save the coordinates of x, y, z, i.e. [pts_num x 3]. We
    can use [MeshLab](https://www.meshlab.net/) to do this kind of work efficiently.