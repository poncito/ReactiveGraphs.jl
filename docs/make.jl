push!(LOAD_PATH, "../src/")
using Documenter
using DataFlows

DocMeta.setdocmeta!(DataFlows, :DocTestSetup, :(using DataFlows); recursive = true)

makedocs(
    modules = [DataFlows],
    pages = ["Home" => "index.md"],
    sitename = "DataFlows.jl",
    authors = "Romain Poncet",
    strict = true,
)

deploydocs(repo = "github.com/poncito/DataFlows.jl")
