import{_ as i,c as a,o as e,az as t}from"./chunks/framework.mzTpsqEJ.js";const l="/MaterialPointGenerator.jl/dev/assets/image3.i-le8B72.png",n="/MaterialPointGenerator.jl/dev/assets/image4.BO8-UNHM.png",g=JSON.parse('{"title":"Polyhedron","description":"","frontmatter":{},"headers":[],"relativePath":"example/polyhedron.md","filePath":"example/polyhedron.md","lastUpdated":null}'),p={name:"example/polyhedron.md"};function h(r,s,k,o,d,E){return e(),a("div",null,s[0]||(s[0]=[t(`<h1 id="polyhedron" tabindex="-1">Polyhedron <a class="header-anchor" href="#polyhedron" aria-label="Permalink to &quot;Polyhedron&quot;">​</a></h1><div class="tip custom-block"><p class="custom-block-title">Note</p><p>All example files can be found at <code>assets/3d_simple</code> <a href="https://github.com/LandslideSIM/MaterialPointGenerator.jl" target="_blank" rel="noreferrer">https://github.com/LandslideSIM/MaterialPointGenerator.jl</a>.</p></div><p>Here, we only need to provide the <code>.stl</code> file and specify the cell size <code>h</code>.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> MaterialPointGenerator</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">src_dir     </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">@__DIR__</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;assets/3d_simple&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">stl_file    </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(src_dir, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;wedge.stl&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output_file </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(src_dir, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;3d_simple.xyz&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">polyhedron2particle</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(stl_file, output_file, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, verbose</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+l+'" alt=""></p><p>A partially enlarged image:</p><p><img src="'+n+'" alt=""></p>',7)]))}const y=i(p,[["render",h]]);export{g as __pageData,y as default};
