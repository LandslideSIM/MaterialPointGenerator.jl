module MaterialPointGenerator

using Interpolations
using DelimitedFiles
using Printf

export PointCloud
export read_pointcloud
export write_pointcloud
export mp_generate

const TInt   = Union{  Int32,   Int64}
const TFloat = Union{Float32, Float64}

"""
    PointCloud{T1<:TInt, T2<:TFloat}

Description:
---
Point cloud data structure. Coordinates x, y, z are parameters that must be input.
"""
@kwdef struct PointCloud{T1<:TInt, T2<:TFloat}
    x    ::Array{T2}
    y    ::Array{T2}
    z    ::Array{T2}
    min_x::T2 = T2(0)
    max_x::T2 = T2(0)
    min_y::T2 = T2(0)
    max_y::T2 = T2(0)
    min_z::T2 = T2(0)
    max_z::T2 = T2(0)
    num  ::T1 = T1(1)
    space::T2 = T2(0)
    function PointCloud{T1, T2}(x, y, z, min_x, max_x, min_y, max_y, min_z, max_z, num, 
        space) where {T1, T2}
        min_x = minimum(x)
        max_x = maximum(x)
        min_y = minimum(y)
        max_y = maximum(y)
        min_z = minimum(z)
        max_z = maximum(z)
        num   = length(x)
        space_x = space_y = 0
        @inbounds for i in unique(y)
            if count(==(i), y) ≥ 5
                idx = findall(j->y[j]==i, 1:num)
                @show tmp = unique(abs.(diff(x[idx])))
                length(tmp)==1 ? nothing : error("X axis space data error.")
                space_x = tmp[1]
                break
            end
        end
        @inbounds for i in unique(x)
            if count(==(i), x) ≥ 5
                idx = findall(j->x[j]==i, 1:num)
                tmp = unique(abs.(diff(y[idx])))
                length(tmp)==1 ? nothing : error("Y axis space data error.")
                space_y = tmp[1]
                break
            end
        end
        space_x==space_y ? nothing : error("X[$space_x] and Y[$space_y] axis space are different.")
        space = abs(space_x)
        new(x, y, z, min_x, max_x, min_y, max_y, min_z, max_z, num, space)
    end
end

function Base.show(io::IO, data::PointCloud)
    min_x = @sprintf("%.2e", data.min_x)
    max_x = @sprintf("%.2e", data.max_x)
    min_y = @sprintf("%.2e", data.min_y)
    max_y = @sprintf("%.2e", data.max_y)
    min_z = @sprintf("%.2e", data.min_z)
    max_z = @sprintf("%.2e", data.max_z)
    print(io, typeof(data)                    , "\n")
    print(io, "─"^length(string(typeof(data))), "\n")
    print(io, "pts num: ", data.num           , "\n")
    print(io, "space  : ", data.space         , "\n")
    print(io, "x range: ", min_x, " ~ ", max_x, "\n")
    print(io, "y range: ", min_y, " ~ ", max_y, "\n")
    print(io, "z range: ", min_z, " ~ ", max_z, "\n")
    return nothing
end

"""
    read_pointcloud(data_path::String; precision::Symbol=:FP64)

Description:
---
Read point cloud data from file. Users can also specify the precision of the data, available
options are :FP64 and :FP32.
"""
function read_pointcloud(data_path::String; precision::Symbol=:FP64)
    if precision==:FP64 
        T1 = Int64
        T2 = Float64
    elseif precision==:FP32
        T1 = Int32
        T2 = Float32
    else
        error("Precision error: $(precision).")
    end
    pts = Array{Float64, 2}(readdlm(data_path))
    size(pts, 1) == length(readlines(data_path)) ? nothing : error("Data read error.")
    return PointCloud{T1, T2}(x=pts[:, 1], y=pts[:, 2], z=pts[:, 3])
end

"""
    write_pointcloud(data::AbstractArray, output_path::String)

Description:
---
Write point cloud data to file. The output file can be read as `.xyz` file in other software.
"""
function write_pointcloud(data::AbstractArray, output_path::String)
    open(output_path, "w") do io
        writedlm(io, data)
    end
    @info "Write point cloud to $(output_path)."
    return nothing
end

"""
    mp_generate(data::PointCloud{T1, T2}, min_z::T2) where {T1, T2}

Description:
---
Generate a point set with a minimum z value. The minimum z value is specified by the user.
"""
function mp_generate(data::PointCloud{T1, T2}, min_z::T2) where {T1, T2}
    min_z≤data.min_z ? nothing : error("Min z [$(min_z)] error: minimum z from point cloud is $(data.min_z).")
    mp = [[data.x[i],data.y[i],data.z[i]] for i in 1:data.num]
    @inbounds for i in 1:data.num
        if data.z[i] ≤ min_z
            nothing
        elseif data.z[i] > min_z
            current_z = min_z
            while current_z≤data.z[i]
                push!(mp, [data.x[i], data.y[i], current_z])
                current_z += data.space
            end
        end
    end
    num = length(mp)
    x_tmp = zeros(T2, num)
    y_tmp = zeros(T2, num)
    z_tmp = zeros(T2, num)
    @inbounds for i in 1:num
        x_tmp[i] = mp[i][1]
        y_tmp[i] = mp[i][2]
        z_tmp[i] = mp[i][3]
    end
    return [x_tmp y_tmp z_tmp]
end

end