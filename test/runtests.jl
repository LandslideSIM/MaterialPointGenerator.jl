using MaterialPointGenerator
using Test

@test !isnothing(MaterialPointGenerator.trimesh[])
@test !isnothing(MaterialPointGenerator.np[])
@test !isnothing(MaterialPointGenerator.meshio[])
@test !isnothing(MaterialPointGenerator.voxelize_fn[])
@test Sys.ARCH ≠ :aarch64 && !isnothing(MaterialPointGenerator.embreex[])