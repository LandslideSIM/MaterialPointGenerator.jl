using WGLMakie
using MaterialPointGenerator

#=-----------------------------------------------------------------------------------------+
| step 1. load the data and get the longest and widest axes of the polygon                 |
+-----------------------------------------------------------------------------------------=#

# this is the result from cloudcompare, which is used to trim the boundary of the DEM
data = readxyz(joinpath(@__DIR__, "aft.xyz"))

# get the polygon vertices, try different ratio values
polygon_pts = getpolygon(data, ratio=0.05)

let 
    set_theme!(theme_latexfonts())
    fig = Figure()
    ax = Axis(fig[1, 1], aspect=DataAspect())
    scatter!(ax, data[:, 1:2], color =:green, markersize=1)
    lines!(ax, polygon_pts, color=:red, linewidth=2)
    display(fig)
end

h = 10.0 # DEM resolution
dem = sort_pts_xy(rasterizeDEM(data, h, polygon_pts)) # rasterize the DEM
a, b, c, d = getlongwidth(polygon_pts) # get the longest and widest axes

let 
    set_theme!(theme_latexfonts())
    fig = Figure()
    ax = Axis(fig[1, 1], aspect=DataAspect())
    lines!(ax, polygon_pts, color =:green)
    lines!(ax, b', color=:red, linewidth=2)
    lines!(ax, d', color=:blue, linewidth=2)
    display(fig)
end

#=-----------------------------------------------------------------------------------------+
| step 2. use SLBL algorithm, try different parameters                                     |
+-----------------------------------------------------------------------------------------=#

# perform the SLBL to get the failure surface
zmax = -120*3
failure = sort_pts_xy(SLBL3D(dem, h, zmax, a))
v = zmax > 0 ? maximum(dem[:, 3] - failure[:, 3]) : maximum(failure[:, 3] - dem[:, 3])
@info "maximum vertical difference: $(v)"

let
    fig = Figure()
    ax = LScene(fig[1, 1])
    scatter!(ax, dem, color=:red, markersize=2)
    scatter!(ax, failure, color=:blue, markersize=2)
    display(fig)
end

#=-----------------------------------------------------------------------------------------+
| step 3. generate the MPM particles based on the raw DEM and the failure surface from SLBL|
+-----------------------------------------------------------------------------------------=#

# get material points, i.e. remove the boundary particles
pid = findall(i-> dem[i, 3] ≠ failure[i, 3], 1:size(dem, 1))
pts = dem2particle(dem[pid, :], h, failure[pid, :])

let 
    fig = Figure()
    ax = LScene(fig[1, 1])
    scatter!(ax, pts, color=pts[:, 3], markersize=1)
    display(fig)
end