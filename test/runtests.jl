using MaterialPointGenerator
using DelimitedFiles
using Test

const testassets = joinpath(@__DIR__, "testsuit/testassets")
@testset "trigonometric identities" begin
    include(joinpath(@__DIR__, "testsuit/testdem.jl"))
    include(joinpath(@__DIR__, "testsuit/testmeshgenerator.jl"))
    include(joinpath(@__DIR__, "testsuit/testpolygon.jl"))
    #include(joinpath(@__DIR__, "testsuit/testpolyhedron.jl"))
    include(joinpath(@__DIR__, "testsuit/testutils.jl"))
end;