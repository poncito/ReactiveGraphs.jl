module DataFlows

export input
export Source
export constant

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

function buildmap(f, argtypes, initialvalue, state)
    T, TState = typeof(initialvalue), typeof(state)
    if isnothing(initialvalue) && isnothing(state)
        T = Base._return_type(f, Tuple{argtypes...})
        Map{T}(Stateless(f), nothing)
    elseif isnothing(initialvalue) && !isnothing(state)
        T, T2 = Base._return_type(f, Tuple{TState, argtypes...}) |> _splittuple
        if T2 != TState
            throw(ErrorException("type deduction error: expected $TState got $T2"))
        end
        Map{T}(Stateful(f), state)
    elseif !isnothing(initialvalue) && isnothing(state)
        T2 = Base._return_type(f, Tuple{T, argtypes...})
        if T != T2
            throw(ErrorException("type deduction error: expected $T got $T2"))
        end
        Map(Markov(f), nothing, initialvalue)
    else
        T1, T2 = Base._return_type(f, Tuple{T, TState, argtypes...}) |> _splittuple
        if T1 != T
            throw(ErrorException("type deduction error: expected $T got $T1"))
        end
        if T2 != TState
            throw(ErrorException("type deduction error: expected $TState got $T2"))
        end
        Map(MarkovStateful(f), state, initialvalue)
    end
end

function buildmap!(f, argtypes, initialvalue, state=nothing)
    if !ismutable(initialvalue)
        throw(ErrorException("initialvalue must be mutable, got $initialvalue"))
    end
    if isnothing(state)
        Map(Markov!(f), nothing, initialvalue)
    else
        if !ismutable(state)
            throw(ErrorException("state must be mutable, got $state"))
        end
        Map(MarkovStateful!(f), state, initialvalue)
    end
end

function Base.map(f::Function, arg::Node, args::Node...; name::Union{Nothing,Symbol}=nothing, initialvalue=nothing, state=nothing)
    uniquename = genname(name)
    argtypes = getoperationtype.((arg, args...))
    op = buildmap(f, argtypes, initialvalue, state)
    Node(uniquename, op, arg, args...)
end

function Base.map!(f::Function, initialvalue, arg::Node, args::Node...; name::Union{Nothing,Symbol}=nothing, state=nothing)
    uniquename = genname(name)
    argtypes = getoperationtype.((arg, args...))
    op = buildmap!(f, argtypes, initialvalue, state)
    Node(uniquename, op, arg, args...)
end

function Base.filter(condition::Node, x::Node; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Filter{getoperationtype(x)}()
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

