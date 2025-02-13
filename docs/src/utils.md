# Useful tools

```@docs
sortbycol(pts, col::T) where T <: Int
csv2geo2d(csv_file::String, geo_file::String)
sort_pts(pts::Matrix)
sort_pts_xy
populate_pts(pts_cen::Matrix{T}, h::T) where T
insolidbase(mp::Matrix{T2}, surf::Matrix{T2}, nv::Matrix{T2}) where T2
```