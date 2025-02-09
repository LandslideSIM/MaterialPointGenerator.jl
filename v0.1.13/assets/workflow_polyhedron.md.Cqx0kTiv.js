import{_ as a,C as l,c as n,o,j as s,a as e,az as r,G as h}from"./chunks/framework.BgUxWNKU.js";const m=JSON.parse('{"title":"Polyhedron","description":"","frontmatter":{},"headers":[],"relativePath":"workflow/polyhedron.md","filePath":"workflow/polyhedron.md","lastUpdated":null}'),p={name:"workflow/polyhedron.md"},d={class:"jldocstring custom-block",open:""};function k(g,i,c,u,y,f){const t=l("Badge");return o(),n("div",null,[i[3]||(i[3]=s("h1",{id:"polyhedron",tabindex:"-1"},[e("Polyhedron "),s("a",{class:"header-anchor",href:"#polyhedron","aria-label":'Permalink to "Polyhedron"'},"​")],-1)),i[4]||(i[4]=s("p",null,"In addition to the standard 3D model, we recommend obtaining a surface model file directly through other preprocessing software (there is no need for mesh discretization within the model). Using this STL file, we will voxelize it and fill it with uniform material points.",-1)),s("details",d,[s("summary",null,[i[0]||(i[0]=s("a",{id:"MaterialPointGenerator.polyhedron2particle-Tuple{String, String, Real}",href:"#MaterialPointGenerator.polyhedron2particle-Tuple{String, String, Real}"},[s("span",{class:"jlbinding"},"MaterialPointGenerator.polyhedron2particle")],-1)),i[1]||(i[1]=e()),h(t,{type:"info",class:"jlObjectType jlMethod",text:"Method"})]),i[2]||(i[2]=r(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">polyhedron2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(stl_file</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">String</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, output_file, h; method</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">String</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;voxel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    verbose</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Bool</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><strong>Description:</strong></p><p>Convert a polyhedron (<code>.stl</code>) to a set of particles. The function will write the populated particles of each voxel into a <code>.xyz</code> file. The voxel size is defined by <code>h</code>, it is suggest to be equal to the MPM background grid size. <code>method</code> can be &quot;voxel&quot; or &quot;ray&quot; in string.The <code>verbose</code> is a flag to show the time consumption of each step.</p><p><strong>Example:</strong></p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">stl_file </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;/path/to/your/model.stl&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output_file </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;/path/to/your/model.xyz&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">h </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 0.1</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">polyhedron2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(stl_file, output_file, h, verbose</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl/blob/1f6b213e09d0afcfe6afb8125f6dd1f59cc9bf13/src/polyhedron.jl#L26-L45" target="_blank" rel="noreferrer">source</a></p>`,6))]),i[5]||(i[5]=s("p",null,[e("Note that "),s("code",null,"h"),e(" refers to the size of the grid in the MPM simulation. By default, we will fill each cell with 8 material points.")],-1)),i[6]||(i[6]=s("p",null,[e('The method about "ray" is modified based on this work: '),s("a",{href:"https://link.springer.com/article/10.1007/s40571-024-00813-z",target:"_blank",rel:"noreferrer"},"https://link.springer.com/article/10.1007/s40571-024-00813-z"),e(".")],-1))])}const F=a(p,[["render",k]]);export{m as __pageData,F as default};
