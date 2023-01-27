using MaterialPointGenerator

pts = polyhedron2particle(joinpath(testassets, "test.msh"), 5, 5, 5, Val(:CPU))
rst = readxyz(joinpath(testassets, "test.xyz"))
@test pts ≈ rst