# Polygon

For the two-dimensional polygon model, we consider two cases: 1) simple polygons, which have no holes in their interior, and 2) complex arbitrary polygons.

For the first scenario, we simply need to input the vertices of the polygon in a counterclockwise order, and then MaterialPointGenerator.jl will automatically generate uniform material points of the specified size within the minimum enclosing rectangle (AABB) of the polygon. It will use the winding number algorithm to determine whether each material point is inside the polygon. This process does not take much time for simple polygons, and we have enabled multithreading by default (make sure to configure the correct number of threads when starting Julia).

For the second scenario, to support complex polygons in any situation, we need to utilize some preprocessing software. Here, we recommend using [Gmsh](https://gmsh.info), which is not only open-source and powerful but also offers a user-friendly GUI, making it very easy to get started. We first create the model in Gmsh, where we can determine the precision of the triangular mesh according to our needs (there are many tutorials on Gmsh available on YouTube). After that, we export it as a `.stl` file. While other formats can theoretically be used, we always recommend sticking with the `.stl` format. Next, you simply need to read this file and specify the grid size (the grid size in MPM simulations), which is very straightforward!

## Simple 2D model

We are preparing to discretize a two-dimensional pentagon, noting that the specified distance is between the material points in both the x and y directions.

```@docs
polygon2particle(polygon::AbstractMatrix{T}, lpx, lpy) where T<:Real
```

```julia
julia> polygon = [0.3 0.0; 0.8 0.0; 1.1 0.5; 0.55 0.8; 0.0 0.5]
julia> pts = polygon2particle(polygon, 0.01, 0.01)
223×2 Matrix{Float64}:
 0.03  0.49
 0.08  0.39
 0.08  0.44
 0.08  0.49
 0.08  0.54
 0.13  0.29
 ⋮     
 0.98  0.54
 1.03  0.39
 1.03  0.44
 1.03  0.49
 1.08  0.49
```

![image3](./image3.png)

## Arbitrary 2D model

Please use pre-processing tools like Gmsh or MeshLab to ensure that the current mesh is closed in advance.

```@docs
polygon2particle(stl_file::String, output_file::String, h; verbose::Bool=false)
```

## Advanced

This involves some advanced operations for partitioning the generated material points. There are two ways to achieve this: 1) directly determining whether the current material point is within a specified polygonal area, and 2) using the concept of physical groups in Gmsh to differentiate the model during the meshing phase. 

For the first case, we can utilize a practical function to check if a point is inside the polygon. 

```@docs
particle_in_polygon(
    polygon::AbstractMatrix{T}, 
    px     ::Real, 
    py     ::Real
) where T<:Real
```

For the second case, in addition to the `.stl` file, we also need to provide a `.msh` file.

```@docs
polygon2particle(
    stl_file   ::String, 
    msh_file   ::String, 
    output_file::String,
    nid_file   ::String,
    h; 
    verbose    ::Bool=false
)
```