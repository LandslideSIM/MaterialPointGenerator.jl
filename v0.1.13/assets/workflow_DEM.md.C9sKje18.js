import{_ as r,C as n,c as l,o as d,az as i,j as t,a,G as o}from"./chunks/framework.BgUxWNKU.js";const p="/MaterialPointGenerator.jl/v0.1.13/assets/image4.BEPi5y89.png",w=JSON.parse('{"title":"DEM","description":"","frontmatter":{},"headers":[],"relativePath":"workflow/DEM.md","filePath":"workflow/DEM.md","lastUpdated":null}'),h={name:"workflow/DEM.md"},c={class:"jldocstring custom-block",open:""},u={class:"jldocstring custom-block",open:""},m={class:"jldocstring custom-block",open:""},f={class:"jldocstring custom-block",open:""},T={class:"jldocstring custom-block",open:""};function b(g,e,M,k,E,y){const s=n("Badge");return d(),l("div",null,[e[15]||(e[15]=i('<h1 id="dem" tabindex="-1">DEM <a class="header-anchor" href="#dem" aria-label="Permalink to &quot;DEM&quot;">​</a></h1><div class="tip custom-block"><p class="custom-block-title">Note</p><p>Here we assume that the DEM file only includes the three-dimensional coordinates of points. The input format for the DEM is a three-column array, where the first column represents the x-coordinate, the second column represents the corresponding y-coordinate, and the third column is the z-coordinate.</p></div><p>The Digital Elevation Model (DEM) is a special 3D case. Typically, for landslide simulations, we obtain a DEM file composed of surface data, which consists of three-dimensional scatter points, with each x-y coordinate corresponding to a unique z value. Before generating the material points, we need to perform a simple processing step by rasterizing it on the x-y plane using inverse distance weighting (IDW). We then proceed to generate the material points based on our requirements.</p><h2 id="DEM-file-pre-processing" tabindex="-1">DEM file pre-processing <a class="header-anchor" href="#DEM-file-pre-processing" aria-label="Permalink to &quot;DEM file pre-processing {#DEM-file-pre-processing}&quot;">​</a></h2><p>The DEM file is a simple three-column array. Each DEM must be rasterized to ensure it is structured (regular) in the x-y plane.</p>',5)),t("details",c,[t("summary",null,[e[0]||(e[0]=t("a",{id:"MaterialPointGenerator.rasterizeDEM-Union{Tuple{T2}, Tuple{T1}, Tuple{Matrix{T2}, T2}} where {T1, T2}",href:"#MaterialPointGenerator.rasterizeDEM-Union{Tuple{T2}, Tuple{T1}, Tuple{Matrix{T2}, T2}} where {T1, T2}"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.rasterizeDEM")],-1)),e[1]||(e[1]=a()),o(s,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),e[2]||(e[2]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rasterizeDEM</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dem, h; k</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, p</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, trimbounds</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.0</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 0.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], dembounds</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><p><strong>Description:</strong></p><p>Rasterize the DEM file to generate particles. <code>dem</code> is a coordinates Array with three columns <code>(x, y, z)</code>. <code>h</code> is the space of the cloud points in <code>x</code> and <code>y</code> directions, normally it is equal to the grid size in the MPM simulation. <code>k</code> is the number of nearest neighbors (10 by default), <code>p</code> is the power parameter (2 by default), <code>trimbounds</code> is the boundary of the particles, <code>dembounds</code> is the boundary of the DEM.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/dem.jl#L62-L72" target="_blank" rel="noreferrer">source</a></p>',4))]),e[16]||(e[16]=t("p",null,[a("Through this function, we can rasterize the input DEM file and specify the spacing between each point (which is the same as the grid size in the MPM simulation). The "),t("code",null,"trimbounds"),a(" parameter is used to define the shape of the DEM file in the x-y plane; it is a two-dimensional array where each row represents a vertex of the shape in the x-y plane. The "),t("code",null,"dembounds"),a(" parameter can be used to specify the range of the DEM in the x-y plane; it is a vector that represents "),t("code",null,"[xmin, xmax, ymin, ymax]"),a(". This can be utilized to process two DEMs of the same area at different times, ensuring they have completely consistent x-y coordinates.")],-1)),e[17]||(e[17]=t("h2",{id:"DEM-with-a-flat-bottom-surface",tabindex:"-1"},[a("DEM with a flat bottom surface "),t("a",{class:"header-anchor",href:"#DEM-with-a-flat-bottom-surface","aria-label":'Permalink to "DEM with a flat bottom surface {#DEM-with-a-flat-bottom-surface}"'},"​")],-1)),e[18]||(e[18]=t("p",null,"Suppose we have a DEM and we want to close it with a base plane, for example, at z=0.",-1)),t("details",u,[t("summary",null,[e[3]||(e[3]=t("a",{id:"MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, T2}} where T2",href:"#MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, T2}} where T2"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.dem2particle")],-1)),e[4]||(e[4]=a()),o(s,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),e[5]||(e[5]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dem2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dem, h, bottom)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Generate particles from a given DEM file. <code>dem</code> is a coordinates Array with three columns (x, y, z). <code>h</code> is the space of particles in <code>z</code> direction, normally it is equal to the grid size in the MPM simulation. <code>bottom</code> is a value, which means the plane <code>z = bottom</code>.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/dem.jl#L124-L132" target="_blank" rel="noreferrer">source</a></p>',4))]),e[19]||(e[19]=t("h2",{id:"DEM-with-a-given-bottom-surface",tabindex:"-1"},[a("DEM with a given bottom surface "),t("a",{class:"header-anchor",href:"#DEM-with-a-given-bottom-surface","aria-label":'Permalink to "DEM with a given bottom surface {#DEM-with-a-given-bottom-surface}"'},"​")],-1)),e[20]||(e[20]=t("p",null,"If the base used to close DEM-1 is not a flat surface, we can designate another DEM-2 to serve as the base for closing DEM-1.",-1)),t("details",m,[t("summary",null,[e[6]||(e[6]=t("a",{id:"MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, Matrix{T2}}} where T2",href:"#MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, Matrix{T2}}} where T2"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.dem2particle")],-1)),e[7]||(e[7]=a()),o(s,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),e[8]||(e[8]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dem2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dem, h, bottom)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Generate particles from a given DEM file and a bottom surface file. <code>dem</code> is a coordinates Array with three columns (x, y, z), which has to be initialized with the struct <code>DEMSurface</code>. <code>bottom::DEMSurface</code> should have the same x and y coordinates as the DEM, and the z value should be lower than the dem. <code>h</code> is the space of grid size in <code>z</code> direction used in the MPM simulation.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/dem.jl#L281-L290" target="_blank" rel="noreferrer">source</a></p>',4))]),e[21]||(e[21]=i('<div class="tip custom-block"><p class="custom-block-title">Info</p><p>DEM-2 and DEM-1 should have exactly the same coordinates in the x-y plane. This can be achieved using <a href="/MaterialPointGenerator.jl/v0.1.13/workflow/DEM#MaterialPointGenerator.rasterizeDEM-Union{Tuple{T2}, Tuple{T1}, Tuple{Matrix{T2}, T2}} where {T1, T2}"><code>rasterizeDEM</code></a>.</p></div><h2 id="advanced" tabindex="-1">Advanced <a class="header-anchor" href="#advanced" aria-label="Permalink to &quot;Advanced&quot;">​</a></h2><p>Here, we consider attaching geological structures (material properties) to the filled material points. The output of this workflow consists of two files: the first, as before, is a 3D scatter coordinate file in .xyz format, and the second is a material ID file (.nid) with the same number of points as the scatter file.</p><p>To prepare for this, you need to have layered surface files in DEM format, which should have exactly the same x-y coordinates as the input DEM surface file (this can be achieved using parameters a and b). They should look like the following:</p><p><img src="'+p+'" alt=""></p>',5)),t("details",f,[t("summary",null,[e[9]||(e[9]=t("a",{id:"MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, T2, Array{Matrix{T2}, 1}}} where T2",href:"#MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, T2, Array{Matrix{T2}, 1}}} where T2"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.dem2particle")],-1)),e[10]||(e[10]=a()),o(s,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),e[11]||(e[11]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dem2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dem, h, bottom, layer)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Generate particles from a given DEM file and a bottom value (flat bottom surface). <code>dem</code> is a coordinates Array with three columns (x, y, z), and the <code>bottom</code> value should be lower than the dem. <code>h</code> is the space of grid size in <code>z</code> direction used in the MPM simulation. <code>layer</code> is a Vector of Matrix with three columns (x, y, z), which represents the layer surfaces. Note that layers are sorted from top to bottom.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/dem.jl#L175-L185" target="_blank" rel="noreferrer">source</a></p>',4))]),e[22]||(e[22]=t("p",null,"Assuming that we have processed each layered DEM(s), they should be saved in the layer Vector in order from top to bottom along the z-direction as input. Please refer to the usage in the Example section.",-1)),e[23]||(e[23]=t("p",null,"This workflow also supports the case where a bottom DEM is provided:",-1)),t("details",T,[t("summary",null,[e[12]||(e[12]=t("a",{id:"MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, Matrix{T2}, Array{Matrix{T2}, 1}}} where T2",href:"#MaterialPointGenerator.dem2particle-Union{Tuple{T2}, Tuple{Matrix{T2}, T2, Matrix{T2}, Array{Matrix{T2}, 1}}} where T2"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.dem2particle")],-1)),e[13]||(e[13]=a()),o(s,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),e[14]||(e[14]=i('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dem2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dem, h, bottom, layer)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Generate particles from a given DEM file and a bottom surface file. <code>dem</code> is a coordinates Array with three columns (x, y, z), and the z value should be lower than the <code>dem</code>. <code>h</code> is the space of grid size in <code>z</code> direction used in the MPM simulation. <code>layer</code> is a Vector of Matrix with three columns (x, y, z), which represents the layer surfaces. Note that layers are sorted from top to bottom.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/dem.jl#L340-L350" target="_blank" rel="noreferrer">source</a></p>',4))])])}const v=r(h,[["render",b]]);export{w as __pageData,v as default};
