using MaterialPointGenerator

stl_file = joinpath(testassets, "polyhedron2particle.stl")
output_file = joinpath(testassets, "polyhedron2particle.xyz")
polyhedron2particle(stl_file, output_file, 2)
rst = readxyz(joinpath(testassets, "polyhedron2particle.xyz"))
pts = [-0.5   0.5   0.5; -0.5  -0.5   0.5; 0.5   0.5   0.5; 0.5  -0.5   0.5;
       -0.5   0.5  -0.5; -0.5  -0.5  -0.5; 0.5   0.5  -0.5; 0.5  -0.5  -0.5]
@test pts ≈ rst
rm(output_file)