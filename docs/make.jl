using TOV
using Documenter
using CairoMakie

DocMeta.setdocmeta!(TOV, :DocTestSetup, :(using TOV); recursive=true)

makedocs(;
    modules=[TOV],
    authors="Stamatis Vretinaris, Gabriele Bozzola",
    repo=Remotes.GitHub("svretina", "TOV.jl"),
    sitename="TOV.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://svretina.github.io/TOV.jl",
        assets=String[],
        sidebar_sitename=false # Use logo if provided in index.md or custom css
    ),
    pages=[
        "Home" => "index.md",
        "Theory" => "theory.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/svretina/TOV.jl",
    devbranch="master",
)
