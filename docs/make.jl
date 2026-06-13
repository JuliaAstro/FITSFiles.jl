using Documenter, FITSFiles
using Documenter.Remotes: GitHub

makedocs(;
    modules = [FITSFiles],
    sitename = "FITSFiles.jl",
    authors = "Paul Barrett",
    repo = GitHub("JuliaAstro/FITSFiles.jl"),
    format = Documenter.HTML(;
        assets = ["assets/custom.css"],
        sidebar_sitename = false,
        collapselevel = 1,
        warn_outdated = true,
        canonical = "https://juliaastro.org/FITSFiles/stable/",
    ),
    warnonly = [:missing_docs],
    pages = [
        "FITSFiles" => "index.md",
    ],
)

deploydocs(;
    repo = "github.com/JuliaAstro/FITSFiles.jl",
    devbranch = "main",
    push_preview = true,
    versions = ["stable" => "v^", "v#.#"], # Restrict to minor releases
)
