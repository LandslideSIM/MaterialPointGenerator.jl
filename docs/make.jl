using CondaPkg

if Sys.ARCH ≠ :aarch64
    CondaPkg.withenv() do
        cmd = `python -c "import embreex"`
        try
            run(cmd)
            return nothing
        catch
            CondaPkg.add_pip("embreex")
            return nothing
        end
    end
end

using Documenter, DocumenterTools, MaterialPointGenerator

MaterialPointGenerator.__init__()

makedocs(
    modules = [MaterialPointGenerator],
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    clean = false,
    sitename = "MaterialPointGenerator.jl",
    authors = "Zenan Huo",
    pages = [
        "Home" => "index.md",
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
    branch = "gh-pages",
    versions=["stable" => "v^", "dev" => "dev"]
)
