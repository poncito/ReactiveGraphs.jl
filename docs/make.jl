push!(LOAD_PATH, "../src/")
using Documenter
using ReactiveGraphs

DocMeta.setdocmeta!(
    ReactiveGraphs,
    :DocTestSetup,
    :(using ReactiveGraphs);
    recursive = true,
)

makedocs(
    modules = [ReactiveGraphs],
    pages = ["Home" => "index.md"],
    sitename = "ReactiveGraphs.jl",
    authors = "Romain Poncet",
    strict = true,
)

deploydocs(repo = "github.com/poncito/ReactiveGraphs.jl")
