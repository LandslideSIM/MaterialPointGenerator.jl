# Simple Mesh

Here, we consider generating rectangular domain nodes (2D) and cuboidal domain nodes (3D) by controlling the starting range and step size in each direction.

## 2D

Consider a rectangular area where the range in the x-direction is from 0 to 10 and in the 
y-direction from 0 to 6. The step size in the x-direction is 1, and in the y-direction, it 
is 2. Therefore, we can do:

```julia
pts = meshbuilder(0.0 : 1.0 : 10.0, 0.0: 2.0 : 6.0)
```

This way, we can obtain the results shown in the figure. The variable `pts` is an array 
where the first column contains the x-coordinates of all the nodes, and the second column 
contains the corresponding y-coordinates.

![Figure1](../figure/figure1.png)

## 3D

```julia
pts = meshbuilder(0.0 : 1.0 : 10.0, 0.0: 2.0 : 6.0, 0.0 : 2.0 : 4.0)
```

MaterialPointGenerator.jl提供了一个非常便利的函数来导出三维点集以方便可视化:

```julia
savexyz(output_dir, pts)
```

其中output_dir您想要导出的路, pts是三维点集，我们可以设置为：

```julia
savexyz(joinpath(homedir(), "tmp.xyz"), pts)
```

![Figure2](../figure/figure2.png)