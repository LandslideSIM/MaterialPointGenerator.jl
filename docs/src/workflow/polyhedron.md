# Polyhedron

In addition to the standard 3D model, we recommend obtaining a surface model file directly through other preprocessing software (there is no need for mesh discretization within the model). Using this STL file, we will voxelize it and fill it with uniform material points.

```@docs
polyhedron2particle(
    stl_file   ::String, 
    output_file::String, 
    h          ::Real; 
    method     ::String="voxel",
    verbose    ::Bool  =false
)
```

Note that `h` refers to the size of the grid in the MPM simulation. By default, we will fill each cell with 8 material points.

The method about "ray" is modified based on this work: [https://link.springer.com/article/10.1007/s40571-024-00813-z](https://link.springer.com/article/10.1007/s40571-024-00813-z).