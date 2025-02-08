import{_ as n,C as o,c as r,o as p,j as t,a as i,az as a,G as l}from"./chunks/framework.mzTpsqEJ.js";const C=JSON.parse('{"title":"Useful tools","description":"","frontmatter":{},"headers":[],"relativePath":"utils.md","filePath":"utils.md","lastUpdated":null}'),d={name:"utils.md"},h={class:"jldocstring custom-block",open:""},k={class:"jldocstring custom-block",open:""},c={class:"jldocstring custom-block",open:""},g={class:"jldocstring custom-block",open:""},u={class:"jldocstring custom-block",open:""};function b(_,s,y,f,T,E){const e=o("Badge");return p(),r("div",null,[s[15]||(s[15]=t("h1",{id:"Useful-tools",tabindex:"-1"},[i("Useful tools "),t("a",{class:"header-anchor",href:"#Useful-tools","aria-label":'Permalink to "Useful tools {#Useful-tools}"'},"​")],-1)),t("details",h,[t("summary",null,[s[0]||(s[0]=t("a",{id:"MaterialPointGenerator.sortbycol-Union{Tuple{T}, Tuple{Any, T}} where T<:Int64",href:"#MaterialPointGenerator.sortbycol-Union{Tuple{T}, Tuple{Any, T}} where T<:Int64"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.sortbycol")],-1)),s[1]||(s[1]=i()),l(e,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),s[2]||(s[2]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">sortbycol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(pts, col</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">T</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">where</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> T </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&lt;:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Int</span></span></code></pre></div><p><strong>Description:</strong></p><p>Sort the points in <code>pts</code> according to the column <code>col</code>.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/5492ff4c4a509ec952b1ab3f9a87666c248dffd6/src/utils.jl#L112-L118" target="_blank" rel="noreferrer">source</a></p>',4))]),t("details",k,[t("summary",null,[s[3]||(s[3]=t("a",{id:"MaterialPointGenerator.csv2geo2d-Tuple{String, String}",href:"#MaterialPointGenerator.csv2geo2d-Tuple{String, String}"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.csv2geo2d")],-1)),s[4]||(s[4]=i()),l(e,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),s[5]||(s[5]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">csv2geo2d</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(csv_file</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">String</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, geo_file</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">String</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Convert the CSV file (.csv) to the Gmsh geo (.geo) file.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/5492ff4c4a509ec952b1ab3f9a87666c248dffd6/src/utils.jl#L128-L134" target="_blank" rel="noreferrer">source</a></p>',4))]),t("details",c,[t("summary",null,[s[6]||(s[6]=t("a",{id:"MaterialPointGenerator.sort_pts-Tuple{Matrix}",href:"#MaterialPointGenerator.sort_pts-Tuple{Matrix}"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.sort_pts")],-1)),s[7]||(s[7]=i()),l(e,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),s[8]||(s[8]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">sort_pts</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(pts</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Matrix</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Sort the points in pts by the (z-), y-, and x-coordinates, in that order (2/3D).</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/5492ff4c4a509ec952b1ab3f9a87666c248dffd6/src/utils.jl#L153-L159" target="_blank" rel="noreferrer">source</a></p>',4))]),t("details",g,[t("summary",null,[s[9]||(s[9]=t("a",{id:"MaterialPointGenerator.sort_pts_xy",href:"#MaterialPointGenerator.sort_pts_xy"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.sort_pts_xy")],-1)),s[10]||(s[10]=i()),l(e,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[11]||(s[11]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">sort_pts_xy</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(pts</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Matrix</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Sort the points in pts by the x- and y-coordinates, in that order.</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/5492ff4c4a509ec952b1ab3f9a87666c248dffd6/src/utils.jl#L172-L178" target="_blank" rel="noreferrer">source</a></p>',4))]),t("details",u,[t("summary",null,[s[12]||(s[12]=t("a",{id:"MaterialPointGenerator.populate_pts-Union{Tuple{T}, Tuple{Matrix{T}, T}} where T",href:"#MaterialPointGenerator.populate_pts-Union{Tuple{T}, Tuple{Matrix{T}, T}} where T"},[t("span",{class:"jlbinding"},"MaterialPointGenerator.populate_pts")],-1)),s[13]||(s[13]=i()),l(e,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),s[14]||(s[14]=a('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">populate_pts</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(pts_cen, h)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Populate the points around the center points <code>pts_cen</code> with the spacing <code>h/4</code> (2/3D).</p><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/5492ff4c4a509ec952b1ab3f9a87666c248dffd6/src/utils.jl#L184-L190" target="_blank" rel="noreferrer">source</a></p>',4))])])}const m=n(d,[["render",b]]);export{C as __pageData,m as default};
