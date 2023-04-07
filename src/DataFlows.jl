module DataFlows

export input
export Source
export constant
export mapmarkov, mapstateful, mapmarkovstateful

TypeOrValue{X} = Union{X,Type{X}}

include("graph.jl")
include("operations.jl")
include("compilation.jl")

genname(::Nothing) = gensym()
genname(s::Symbol) = gensym(s)

getoperationtype(node::Node) = getnode(node) |> getelement |> eltype

function input(::Type{T}; name::Union{Nothing,Symbol}=nothing) where {T}
    uniquename = genname(name)
    op = Input{T}()
    Node(uniquename, op)
end

function Base.map(f::Function, args::Node...; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    T = Base._return_type(f, Tuple{(getoperationtype(a) for a in args)...})
    op = Map{T}(Stateless(f), nothing)
    Node(uniquename, op, args...)
end

function mapmarkov(f::Function, initialvalue::T, args::Node...; name::Union{Nothing,Symbol}=nothing) where {T}
    uniquename = genname(name)
    T2 = Base._return_type(f, Tuple{T, (getoperationtype(a) for a in args)...})
    if T != T2
        throw(ErrorException("type deduction error: expected $T got $T2"))
    end
    op = Map(Markov(f), nothing, initialvalue)
    Node(uniquename, op, args...)
end

function mapstateful(f::Function, state::TState, args::Node...; name::Union{Nothing,Symbol}=nothing) where {TState}
    uniquename = genname(name)
    T, T2 = Base._return_type(f, Tuple{TState, (getoperationtype(a) for a in args)...}) |> _splittuple
    if T2 != TState
        throw(ErrorException("type deduction error: expected $TState got $T2"))
    end
    op = Map{T}(Stateful(f), state)
    Node(uniquename, op, args...)
end

function mapmarkovstateful(f::Function, initialvalue::T, state::TState, args::Node...; name::Union{Nothing,Symbol}=nothing) where {T, TState}
    uniquename = genname(name)
    T1, T2 = Base._return_type(f, Tuple{T, TState, (getoperationtype(a) for a in args)...}) |> _splittuple
    if T1 != T
        throw(ErrorException("type deduction error: expected $T got $T1"))
    end
    if T2 != TState
        throw(ErrorException("type deduction error: expected $TState got $T2"))
    end
    op = Map(MarkovStateful(f), state, initialvalue)
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

_splittuple(T::Type{<:Any}) = T, Nothing
_splittuple(::Type{Tuple{T1,T2}}) where {T1,T2} = T1, T2

end # module

