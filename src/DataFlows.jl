module DataFlows

export input
export Source
export constant
export Stateless, Stateful, Markov, MarkovStateful

TypeOrValue{X} = Union{X,Type{X}}

include("graph.jl")
include("operations.jl")
include("compilation.jl")

genname(::Nothing) = gensym()
genname(s::Symbol) = gensym(s)

function input(::Type{T}; name::Union{Nothing,Symbol}=nothing) where {T}
    uniquename = genname(name)
    op = Input{T}()
    Node(uniquename, op)
end

function Base.map(f::Function, args::Node...; name::Union{Nothing,Symbol}=nothing)
    map(Stateless(f), args...; name)
end

_first(T::Type{<:Any}) = T
_first(::Type{Tuple{T1,T2}}) where {T1,T2} = T1

function Base.map(f::Union{Stateless,Markov,Stateful,MarkovStateful}, args::Node...; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    T = Base._return_type(f.f, Tuple{(eltype(a) for a in args)...}) |> _first
    op = Map{T}(f, nothing)
    Node(uniquename, op, args...)
end

function Base.filter(condition::Node, x::Node; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Filter()
    Node(uniquename, op, condition, x)
end

function constant(x; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Constant(x)
    Node(uniquename, op)
end

end # module

