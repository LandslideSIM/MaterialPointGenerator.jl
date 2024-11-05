# DEM

!!! note

    Here we assume that the DEM file only includes the three-dimensional coordinates of points. 
    The input format for the DEM is a three-column array, where the first column represents the x-coordinate, the second column represents the corresponding y-coordinate, and the third 
    column is the z-coordinate.

## DEM with a flat bottom surface

假设我们有了一个DEM文件，然后想以底面，例如z=0这个平面对这个DEM模型闭合，那么可以做：

```julia
pts = dem2particle(dem, lpz, bottom)
```

其中dem是拥有三列的数组，lpz是沿z方向布置物质点时的步长，bottom是一个标量值，表示底平面z的高度。

```julia
pts = dem2particle(dem, 0.1, 0)
savexyz(joinpath(homedir(), "tmp.xyz"), pts)
```

![Figure3](../figure/figure3.png)

## DEM with a given bottom surface

如果说用来闭合DEM1的底面并不是一个平面，那么我们可以指定另一个DEM2文件作为用来闭合DEM1的底面。

```julia
pts = dem2particle(dem, lpz, bottom_surf)
```

!!! warning

    DEM2与DEM1应该在x-y平面具有完全相同的坐标。这可以通过[`rasterizeDEM`](@ref)来实现。

例如：

```julia
pts = dem2particle(dem, 0.1, bottom_surf)
savexyz(joinpath(homedir(), "tmp.xyz"), pts)
```

![Figure4](../figure/figure4.png)

## DEM interpolation

这里的插值是指DEM中的点集在x-y平面上进行插值，并根据相邻点的z坐标来计算对应的z值。有些时候滑坡的DEM文件可能在x-y平面并不是
一个矩形，因此我们可能需要对形状进行裁剪。

### DEM为矩形

### DEM非矩形

