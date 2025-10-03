# re-define functions
const pip_query     = FastPointQuery.pip_query
const readasc       = FastPointQuery.readasc
const read_polygon  = FastPointQuery.read_polygon
const write_polygon = FastPointQuery.write_polygon
const saveply       = FastPointQuery.saveply
const readply       = FastPointQuery.readply
const readSTL2D     = FastPointQuery.readSTL2D
const readSTL3D     = FastPointQuery.readSTL3D
const readtiff      = FastPointQuery.readtiff
const savexyz       = FastPointQuery.savexyz
const savexy        = FastPointQuery.savexy
const readxyz       = FastPointQuery.readxyz
const readxy        = FastPointQuery.readxy
const get_polygon   = FastPointQuery.get_polygon
const get_normals   = FastPointQuery.get_normals
const meshbuilder   = FastPointQuery.meshbuilder
const gridbuilder   = FastPointQuery.gridbuilder
const filling_pts   = FastPointQuery.filling_pts
const sort_pts      = FastPointQuery.sort_pts
const py2ju         = FastPointQuery.py2ju
const pyfun         = FastPointQuery.pyfun

# re-define structs
const QueryPolygon = FastPointQuery.QueryPolygon
const STLInfo2D    = FastPointQuery.STLInfo2D
const STLInfo3D    = FastPointQuery.STLInfo3D

# re-export functions
export pip_query, readasc, read_polygon, write_polygon, saveply, readply,
       readSTL2D, readSTL3D, readtiff, readxy, readxyz, savexy, savexyz,
       get_polygon, get_normals, meshbuilder, gridbuilder, filling_pts, sort_pts

# re-export structs       
export QueryPolygon, STLInfo2D, STLInfo3D

# re-define but not export functions
const _get_pts       = FastPointQuery._get_pts
const _get_pts_voxel = FastPointQuery._get_pts_voxel
const _get_pts_ray   = FastPointQuery._get_pts_ray