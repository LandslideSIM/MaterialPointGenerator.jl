# test dem2particle by a z value
tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
pts = dem2particle(dem, 0.5, -1.0)
rst = readxyz(joinpath(testassets, "dem1.xyz"))
@test rst ≈ pts
# test dem2particle by a bottom surface
tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
bot = copy(dem)
bot[:, 3] .-= 1.0
pts = dem2particle(dem, 0.5, bot)
rst = readxyz(joinpath(testassets, "dem2.xyz"))
@test rst ≈ pts
# test DEM interpolation by surrogate method (RBF)
tmp = meshbuilder(0 : 0.5 : 5, 0 : 0.5 : 5)
dem = hcat(tmp, cos.(tmp[:, 1]) .* sin.(tmp[:, 2]))
pts = surrogateDEM(0.6, 0.6, dem)
rst = readxyz(joinpath(testassets, "dem3.xyz"))
@test rst ≈ pts