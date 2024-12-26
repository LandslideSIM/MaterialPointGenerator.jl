# DEM

!!! note

    Here we assume that the DEM file only includes the three-dimensional coordinates of points. 
    The input format for the DEM is a three-column array, where the first column represents the x-coordinate, the second column represents the corresponding y-coordinate, and the third 
    column is the z-coordinate.

The Digital Elevation Model (DEM) is a special 3D case. Typically, for landslide simulations, we obtain a DEM file composed of surface data, which consists of three-dimensional scatter points, with each x-y coordinate corresponding to a unique z value. Before generating the material points, we need to perform a simple processing step by rasterizing it on the x-y plane using inverse distance weighting (IDW). We then proceed to generate the material points based on our requirements.

## DEM file pre-processing

The DEM file is a simple three-column array, but we need to instantiate it using the structure provided internally.

```@docs
DEMSurface(coord; ϵ="FP64")
```

Each DEM must be rasterized to ensure it is structured (regular) in the x-y plane.

```@docs
rasterizeDEM(
    dem       ::DEMSurface{T1, T2},
    h         ::T2; 
    k         ::T1        = 10, 
    p         ::T1        = 2, 
    trimbounds::Matrix{T2}= [0.0 0.0], 
    dembounds ::Vector{T2}= [0.0, 0.0]
) where {T1, T2}
```

Through this function, we can rasterize the input DEM file and specify the spacing between each point (which is the same as the grid size in the MPM simulation). The `trimbounds` parameter is used to define the shape of the DEM file in the x-y plane; it is a two-dimensional array where each row represents a vertex of the shape in the x-y plane. The `dembounds` parameter can be used to specify the range of the DEM in the x-y plane; it is a vector that represents `[xmin, xmax, ymin, ymax]`. This can be utilized to process two DEMs of the same area at different times, ensuring they have completely consistent x-y coordinates.

## DEM with a flat bottom surface

Suppose we have a DEM and we want to close it with a base plane, for example, at z=0.

```@docs
dem2particle(
    dem   ::DEMSurface{T1, T2}, 
    h     ::T2, 
    bottom::T2
) where {T1, T2}
```

## DEM with a given bottom surface

If the base used to close DEM-1 is not a flat surface, we can designate another DEM-2 to serve as the base for closing DEM-1.

```@docs
dem2particle(
    dem   ::DEMSurface{T1, T2}, 
    h     ::T2, 
    bottom::DEMSurface{T1, T2}
) where {T1, T2}
```

!!! info

    DEM-2 and DEM-1 should have exactly the same coordinates in the x-y plane. This can be achieved using [`rasterizeDEM`](@ref).