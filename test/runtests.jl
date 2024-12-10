using MaterialPointGenerator
using Test

@test !isnothing(MaterialPointGenerator.trimesh[])
@test !isnothing(MaterialPointGenerator.np[])
@test !isnothing(MaterialPointGenerator.meshio[])
@test !isnothing(MaterialPointGenerator.embreex[])
@test !isnothing(MaterialPointGenerator.voxelize_fn[])