#==========================================================================================+
|        MaterialPointGenerator.jl: Generate structured material particles in Julia        |
+------------------------------------------------------------------------------------------+
|  File Name  : slbl_gui.jl                                                                |
|  Description: SLBL GUI implementation                                                    |
|  Programmer : Zenan Huo                                                                  |
|  Start Date : 01/01/2022                                                                 |
|  Affiliation: Risk Group, UNIL-ISTE                                                      |
|  Functions  : 01. SLBL3D_gui                                                             |
+==========================================================================================#

export SLBL3D_gui

"""
    SLBL3D_gui(; remote::Bool=false)
    
Description:
---
This function starts a web server to serve the SLBL3D GUI. The GUI is used to visualize the
SLBL algorithm and its results. The server can be accessed remotely or locally.
"""
function SLBL3D_gui(; remote::Bool=false)
    host = remote==true ? "0.0.0.0" : "127.0.0.1"
    serve(host=host, dir=@__DIR__)
end 