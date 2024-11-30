using MaterialPointGenerator

pts = polyhedron2particle(joinpath(testassets, "polyhedron2particle.stl"), 0.5)
rst = readxyz(joinpath(testassets, "polyhedron2particle.xyz"))
@test pts ≈ rst