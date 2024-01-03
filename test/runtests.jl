using MaterialPointGenerator
using Test

@testset "MaterialPointGenerator.jl" begin
    # num_x           = length(1:1:20)
    # num_y           = length(1:1:20)
    # x_tmp           = repeat((1.0:1.0:20.0)', num_y, 1) |> vec
    # y_tmp           = repeat((1.0:1.0:20.0) , 1, num_x) |> vec
    # z_tmp           = 6*ones(length(x_tmp))
    # z_tmp[1:100]   .= 2.0
    # z_tmp[101:200] .= 8.0
    data_path = joinpath(@__DIR__, "input.xyz")
    output_path = joinpath(@__DIR__, "output.xyz")
    data = read_pointcloud(data_path)
    @test data.min_x == 1
    @test data.max_x == 20
    @test data.min_y == 1
    @test data.max_y == 20
    @test data.min_z == 2
    @test data.max_z == 8
    @test data.num == 400
    @test data.space == 1
    rst = mp_generate(data, 0.0)
    write_pointcloud(rst, output_path)
end