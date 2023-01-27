using MPMPtsGen

# define the input and output path
data_path = joinpath(@__DIR__, "../examples/test_input.xyz")
output_path = joinpath(@__DIR__, "../examples/test_output.xyz")

# read the point cloud data
data = read_pointcloud(data_path)

# generate the material points
mp = mp_generate(data, 0.0)

# write the material points to the output path
write_pointcloud(mp, output_path)