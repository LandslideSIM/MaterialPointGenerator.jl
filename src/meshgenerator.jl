#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : meshgenerator.jl                                                           |
|  Description: Generate structured mesh in 2D/3D space                                    |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : meshbuilder                                                                |
+==========================================================================================#

export meshbuilder

"""
    meshbuilder(x::T, y::T; ϵ="FP64") where T <: AbstractRange

Description:
---
Generate structured mesh in 2D space.
"""
function meshbuilder(x::T, y::T; ϵ::String="FP64") where T <: AbstractRange
    x_tmp = repeat(x', length(y), 1) |> vec
    y_tmp = repeat(y , 1, length(x)) |> vec
    T1 = ϵ == "FP32" ? Float32 : Float64
    return T1.(hcat(x_tmp, y_tmp))
end

"""
    meshbuilder(x::T, y::T, z::T; precision::String="FP64") where T <: AbstractRange

Description:
---
Generate structured mesh in 3D space.
"""
function meshbuilder(x::T, y::T, z::T; ϵ::String="FP64") where T <: AbstractRange
    vx      = x |> collect
    vy      = y |> collect
    vz      = z |> collect
    m, n, o = length(vy), length(vx), length(vz)
    vx      = reshape(vx, 1, n, 1)
    vy      = reshape(vy, m, 1, 1)
    vz      = reshape(vz, 1, 1, o)
    om      = ones(Int, m)
    on      = ones(Int, n)
    oo      = ones(Int, o)
    x_tmp   = vec(vx[om, :, oo])
    y_tmp   = vec(vy[:, on, oo])
    z_tmp   = vec(vz[om, on, :])
    T1 = ϵ == "FP32" ? Float32 : Float64
    return T1.(hcat(x_tmp, y_tmp, z_tmp))
end