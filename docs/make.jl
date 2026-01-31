using TOV
using Documenter

DocMeta.setdocmeta!(TOV, :DocTestSetup, :(using TOV); recursive=true)

makedocs(;
    modules=[TOV],
    authors="Stamatis Vretinaris, Gabriele Bozzola",
    repo="https://github.com/YOUR_USERNAME/TOV.jl/blob/{commit}{path}#{line}",
    sitename="TOV.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://YOUR_USERNAME.github.io/TOV.jl",
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
    repo="github.com/YOUR_USERNAME/TOV.jl",
    devbranch="main",
)
