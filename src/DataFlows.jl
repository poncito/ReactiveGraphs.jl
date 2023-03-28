module DataFlows

export input
export Source

TypeOrValue{X} = Union{X,Type{X}}

include("graph.jl")
include("operations.jl")
include("node.jl")
include("compilation.jl")

genname(::Nothing) = gensym()
genname(s::Symbol) = gensym(s)

function input(::Type{T}; name::Union{Nothing,Symbol}=nothing) where {T}
    uniquename = genname(name)
    op = Input{T}()
    Node(uniquename, op)
end

function Base.map(f::Function, args::Node...; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    T = Base._return_type(f, Tuple{(eltype(a) for a in args)...})
    op = Map{T}(Stateless(f), nothing)
    Node(uniquename, op, args...)
end

function Base.filter(condition::Node, x::Node; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Filter()
    Node(uniquename, op, condition, x)
end

end # module

