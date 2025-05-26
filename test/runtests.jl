using MaterialPointGenerator
using PythonCall
using Test

@test !PythonCall.pyisnull(MaterialPointGenerator.trimesh     )
@test !PythonCall.pyisnull(MaterialPointGenerator.np          )
@test !PythonCall.pyisnull(MaterialPointGenerator.rasterio    )
@test !PythonCall.pyisnull(MaterialPointGenerator.pygmsh      )
@test !PythonCall.pyisnull(MaterialPointGenerator.pytime      )
@test !PythonCall.pyisnull(MaterialPointGenerator.Polygon     )
@test !PythonCall.pyisnull(MaterialPointGenerator.Point       )
@test !PythonCall.pyisnull(MaterialPointGenerator.mapping     )
@test !PythonCall.pyisnull(MaterialPointGenerator.unary_union )
@test !PythonCall.pyisnull(MaterialPointGenerator.rasterize   )
@test !PythonCall.pyisnull(MaterialPointGenerator.pyKDTree    )
@test !PythonCall.pyisnull(MaterialPointGenerator.MultiPolygon)

if Sys.ARCH == :x86_64 && !Sys.isapple()
    @test !PythonCall.pyisnull(MaterialPointGenerator.embreex)
end