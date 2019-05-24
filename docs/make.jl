push!(LOAD_PATH,"../src/")

using Documenter, Baseball

makedocs(;
    modules=[Baseball],
    format=Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/benelsen/Baseball.jl/blob/{commit}{path}#L{line}",
    sitename="Baseball.jl",
    authors="Ben Elsen",
    # assets=[],
)

deploydocs(;
    repo="github.com/benelsen/Baseball.jl",
)
