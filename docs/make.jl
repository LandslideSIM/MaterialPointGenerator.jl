using Documenter, DocumenterVitepress, MaterialPointGenerator

makedocs(
    modules = [MaterialPointGenerator],
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/LandslideSIM/MaterialPointGenerator.jl",
        devbranch = "main",
        devurl = "dev"
    ),
    sitename = "MaterialPointGenerator.jl",
    authors = "Zenan Huo",
    pages = [
        "Home" => "index.md",
        "getstarted.md",
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
    repo = "github.com/LandslideSIM/MaterialPointGenerator.jl",
    target = "build",
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true
)