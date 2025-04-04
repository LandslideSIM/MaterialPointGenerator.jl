using MaterialPointGenerator
using PythonCall
using Test

@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.trimesh     ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.np          ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.rasterio    ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.pygmsh      ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.pytime      ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.Polygon     ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.Point       ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.mapping     ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.unary_union ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.rasterize   ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.pyKDTree    ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.MultiPolygon))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.ConvexHull  ))
@test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.v_contains  ))

if Sys.ARCH == :x86_64 && !Sys.isapple()
    @test !pyconvert(Bool, PythonCall.pyisnull(MaterialPointGenerator.embreex))
end