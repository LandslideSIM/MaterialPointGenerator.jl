using CondaPkg

if Sys.ARCH ≠ :aarch64
    CondaPkg.withenv() do
        cmd = `python -c "import embreex"`
        try
            run(cmd)
            return nothing
        catch
            CondaPkg.add_pip("embreex")
            return nothing
        end
    end
end

using MaterialPointGenerator
using Test

MaterialPointGenerator.__init__()

@test !isnothing(MaterialPointGenerator.trimesh[])
@test !isnothing(MaterialPointGenerator.np[])
@test !isnothing(MaterialPointGenerator.meshio[])
@test !isnothing(MaterialPointGenerator.voxelize_fn[])

if Sys.ARCH ≠ :aarch64
    @test !isnothing(MaterialPointGenerator.embreex[])
end