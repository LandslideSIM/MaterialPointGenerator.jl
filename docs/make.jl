using Documenter, DocumenterTools, DocumenterVitepress, MaterialPointGenerator

makedocs(
    modules = [MaterialPointGenerator],
    repo = Remotes.GitHub("LandslideSIM", "MaterialPointGenerator.jl"),
    authors = "Zenan Huo",
    sitename = "MaterialPointGenerator.jl",
    format = DocumenterVitepress.MarkdownVitepress(
        #assets = ["assets/favicon.ico"],
        repo = "github.com/LandslideSIM/MaterialPointGenerator.jl",
        devbranch = "main",
        devurl = "dev";
    ),
    source = "src",
    build = "build",
    pages = [
        "MaterialPointGenerator.jl" => "index.md",
        "Workflow" => Any[
            "workflow/simple_mesh.md",
            "workflow/polygon.md",
            "workflow/polyhedron.md",
            "workflow/DEM.md"
        ],
        "Example" => Any[
            "example/polygon.md",
            "example/polyhedron.md",
            "example/DEM.md"
        ],
        "utils.md"
    ],
    warnonly = [:missing_docs, :cross_references],
)

deploydocs(
    repo = "github.com/LandslideSIM/MaterialPointGenerator.jl.git",
    target = "build",
    devbranch="main",
    branch = "gh-pages",
    push_preview = true
)