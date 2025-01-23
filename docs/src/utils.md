# Useful tools

```@docs
fastvtp(coords; vtp_file="output.vtp", data::T=NamedTuple()) where T <: NamedTuple
sortbycol(pts, col::T) where T <: Int
csv2geo2d(csv_file::String, geo_file::String)
sort_pts(pts::Matrix)
sort_pts_xy
populate_pts(pts_cen::Matrix{T}, h::T) where T
```