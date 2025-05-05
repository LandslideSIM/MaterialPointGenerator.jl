#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : slbl.jl                                                                    |
|  Description: SLBL implementation                                                        |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. getlongwidth                                                           |
|               02. gui_available                                                          |
+==========================================================================================#

export getlongwidth
export gui_available

"""
    getlongwidth(points; convex_threshold::Int=2000, scan_samples::Int=600)

Description:
---
Compute the longest internal axis (diameter) of a 2‑D polygon and the widest internal axis
perpendicular to it. The polygon is defined by its vertices in arbitrary order.
The function returns the length of the longest axis, its endpoints, the length of the widest
axis, and its endpoints.

Example:
---
```julia
points = [0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0]
a, b, c, d, e f = getlongwidth(points)
```
"""
function getlongwidth(points; convex_threshold::Int=2000, scan_samples::Int=600)
    size(points, 2) == 2 || throw(ArgumentError("points must be a Nx2 array"))
    size(points, 1) > 3 || throw(ArgumentError("points must be a Nx2 array with N > 3"))
    pypoints = np.array(points)

    @pyexec """
    # ───────────────────────────────────────────────────────────────
    #  公共函数
    # ───────────────────────────────────────────────────────────────
    def py_getlongwidth(points, convex_threshold, scan_samples,
                        Polygon, LineString, rotate, pyTuple, np
    ):
        # Compute the longest internal axis (diameter) of a 2‑D polygon and the
        # widest internal axis perpendicular to it.

        # Parameters
        # ----------
        # points : array‑like, shape (N, 2)
        #     Vertex coordinates **in arbitrary order**.  Column 0 is x, column 1 is y.
        # convex_threshold : int, default 2000
        #     If the polygon is convex *and* vertex count > threshold, an O(h)
        #     rotating‑calipers algorithm is used for the diameter; otherwise an
        #     O(n²) brute‑force search is applied.
        # scan_samples : int, default 600
        #     Extra uniformly spaced vertical scan lines (besides vertex‑based ones)
        #     used when searching for the width axis.

        # Returns
        # -------
        # (long_len, long_p, long_q, wide_len, wide_p, wide_q)
        #     long_len  – length of the longest axis
        #     long_p,q  – its endpoints as (x, y)
        #     wide_len  – length of the widest axis (⊥ long axis)
        #     wide_p,q  – its endpoints as (x, y)

        # ── input check ─────────────────────────────────────────────
        pts = np.asarray(points, dtype=float)
        if pts.ndim != 2 or pts.shape[1] != 2:
            raise ValueError("`points` must be an array of shape (N, 2)")

        # ── helpers ────────────────────────────────────────────────
        def make_polygon(arr):
            # Return a valid Polygon from unordered (N,2) array.
            ctr = arr.mean(axis=0)
            ang = np.arctan2(arr[:, 1] - ctr[1], arr[:, 0] - ctr[0])
            poly = Polygon(arr[np.argsort(ang)])
            if not poly.is_valid:
                poly = poly.buffer(0)          # attempt self‑fix
            if not poly.is_valid:
                poly = Polygon(arr).convex_hull
            return poly

        def diameter_rotating_calipers(poly):
            p = np.asarray(poly.exterior.coords[:-1])
            h = len(p)
            j, best_d = 1, 0.0
            best_i, best_j = 0, 1
            for i in range(h):
                ni = (i + 1) % h
                while True:
                    nj = (j + 1) % h
                    if abs(np.cross(p[ni] - p[i], p[nj] - p[i])) > \
                    abs(np.cross(p[ni] - p[i], p[j] - p[i])):
                        j = nj
                    else:
                        break
                d = np.linalg.norm(p[i] - p[j])
                if d > best_d:
                    best_d, best_i, best_j = d, i, j
            return LineString([p[best_i], p[best_j]])

        def diameter_bruteforce(poly):
            v = list(poly.exterior.coords)[:-1]
            n = len(v)
            best_len, best_seg = -1.0, None
            for i in range(n):
                for j in range(i + 1, n):
                    if j == i + 1 or (i == 0 and j == n - 1):
                        continue
                    seg = LineString([v[i], v[j]])
                    if poly.covers(seg):
                        l = seg.length
                        if l > best_len:
                            best_len, best_seg = l, seg
            return best_seg or LineString([v[0], v[-1]])

        def width_axis(poly, long_seg):
            (x0, y0), (x1, y1) = long_seg.coords
            theta = -np.degrees(np.arctan2(y1 - y0, x1 - x0))
            poly_r = rotate(poly, theta, origin=(0, 0), use_radians=False)

            xs = np.unique([p[0] for p in poly_r.exterior.coords[:-1]])
            mids = (xs[:-1] + xs[1:]) / 2.0
            uni = np.linspace(xs.min(), xs.max(), scan_samples)
            xs_all = np.unique(np.concatenate([xs, mids, uni]))

            ymin, ymax = poly_r.bounds[1], poly_r.bounds[3]
            best_seg_r, best_len = None, -1.0
            for x in xs_all:
                line = LineString([(x, ymin - 1e3), (x, ymax + 1e3)])
                inter = poly_r.intersection(line)
                if inter.is_empty:
                    continue
                segments = (inter.geoms
                            if inter.geom_type == "MultiLineString" else [inter])
                for seg in segments:
                    l = seg.length
                    if l > best_len:
                        best_len, best_seg_r = l, seg
            if best_seg_r is None:                 # degenerate very thin polygon
                best_seg_r = LineString([(xs_all[0], ymin), (xs_all[0], ymax)])
            return rotate(best_seg_r, -theta, origin=(0, 0), use_radians=False)

        # ── main flow ──────────────────────────────────────────────
        poly = make_polygon(pts)
        n = len(poly.exterior.coords) - 1
        convex = poly.equals(poly.convex_hull)

        if convex and n > convex_threshold:
            long_seg = diameter_rotating_calipers(poly)
        else:
            long_seg = diameter_bruteforce(poly)
        long_len = long_seg.length

        wide_seg = width_axis(poly, long_seg)
        wide_len = wide_seg.length

        long_p, long_q = map(tuple, long_seg.coords)
        wide_p, wide_q = map(tuple, wide_seg.coords)

        return long_len, long_p, long_q, wide_len, wide_p, wide_q
    """ => py_getlongwidth

    a, b, c, d, e, f = py_getlongwidth(pypoints, convex_threshold, scan_samples, Polygon,
        LineString, rotate, pyTuple, np)

    return pyconvert(Float64, a), collect(pyconvert(Tuple, b)), collect(pyconvert(Tuple, c)), 
           pyconvert(Float64, d), collect(pyconvert(Tuple, e)), collect(pyconvert(Tuple, f))
end