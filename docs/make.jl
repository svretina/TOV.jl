using TOV
using Documenter

DocMeta.setdocmeta!(TOV, :DocTestSetup, :(using TOV); recursive=true)

makedocs(;
    modules=[TOV],
    authors="Stamatis Vretinaris, Gabriele Bozzola",
    sitename="TOV.jl",
    format=Documenter.HTML(;
        canonical="https://svretina.github.io/TOV.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/svretina/TOV.jl",
    devbranch="master",
)
