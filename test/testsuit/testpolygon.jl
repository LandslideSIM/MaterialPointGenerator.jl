# test polygon
polygon = [0. 0.; 1  0; 1  1; 0  1]
@test particle_in_polygon(0.5, 0.5, polygon) == true
pts = polygon2particle(polygon, 0.2, 0.2)
rst = readdlm(joinpath(testassets, "polygon.csv"))
@test rst ≈ pts