mutable struct Map{T,TState,F} <: Operation{T}
    f::F
    state::TState
    x::T
    Map{T}(f::F, state::TState) where {T, TState, F} = new{T,TState,F}(f, state)
    Map(f::F, state::TState, x::T) where {T, TState, F} = new{T,TState,F}(f, state, x)
end
getvalue(x::Map) = x.x
getstate(x::Map) = x.state

# marginals of the generic map
struct Stateless{F<:Function}
    f::F
end
MapStateless{T,TState} = Map{T,TState,<:Stateless}

struct Markov{F<:Function}
    f::F
end
MapMarkov{T,TState} = Map{T,TState,<:Markov}

struct Stateful{F<:Function}
    f::F
end
MapStateful{T,TState} = Map{T,TState,<:Stateful}

struct MarkovStateful{F<:Function}
    f::F
end
MapMarkovStateful{T,TState} = Map{T,TState,<:MarkovStateful}

struct Markov!{F<:Function}
    f::F
end
MapMarkov!{T,TState} = Map{T,TState,<:Markov!}

struct MarkovStateful!{F<:Function}
    f::F
end
MapMarkovStateful!{T,TState} = Map{T,TState,<:MarkovStateful!}

function update!(m::MapMarkovStateful, args...)
    m.x, m.state = m.f.f(m.x, m.state, args...)
end

function update!(m::MapStateless, args...)
    m.x = m.f.f(args...)
end

function update!(m::MapMarkov, args...)
    m.x = m.f.f(m.x, args...)
end

function update!(m::MapStateful, args...)
    m.x, m.state = m.f.f(m.state, args...)
end

update!(m::MapMarkov!, args...) = m.f.f(m.x, args...)
update!(m::MapMarkovStateful!, args...) = m.f.f(m.x, m.state, args...)

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

function buildmap!(f, argtypes, initialvalue, state)
    if isnothing(initialvalue) && isnothing(state)
        throw(ErrorException("at least initialvalue or state must be different from nothing"))
    end

    if !ismutable(initialvalue) && !isnothing(initialvalue)
        # we can use nothing when the state contains the node value
        throw(ErrorException("initialvalue must be mutable or nothing, got $initialvalue"))
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

function Base.map!(f::Function, arg::Node, args::Node...; name::Union{Nothing,Symbol}=nothing, initialvalue=nothing, state=nothing)
    uniquename = genname(name)
    argtypes = getoperationtype.((arg, args...))
    op = buildmap!(f, argtypes, initialvalue, state)
    Node(uniquename, op, arg, args...)
end

getvalue(::ListNode, element::Map) = getvalue(element)
getvalidity(::ListNode, ::Map) = true

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Map},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Meta.quot(name)
    args = (:(getvalue(list, $(Meta.quot(n)))) for n in parentnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = if $initialized_s & $condition_updated
            node = getnode(list, $nodename_s)
            $(Expr(:call, :update!, :node, args...))
            getvalidity(node)
        else
            false
        end
    end
end
