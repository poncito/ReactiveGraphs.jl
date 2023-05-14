mutable struct Lag{T}
    @tryconst x::Vector{T}
    @tryconst n::Int
    i::Int
    initialized::Bool
end

Lag(::Type{T}, n::Integer) where {T} = Lag(Vector{T}(undef, n + 1), n, 1, false)

function Base.push!(lag::Lag{T}, x::T) where {T}
    lag.x[lag.i] = x
    if lag.i == lag.n + 1
        lag.i = 1
        lag.initialized = true
    else
        lag.i += 1
    end
    lag
end

function Base.getindex(lag::Lag)
    lag.initialized || throw(ErrorException("lag not initialized"))
    lag.x[lag.i]
end

"""
    lag(n::Integer, node::Node; name)

Creates a node that contains the `n`-th lagged value of `node`.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.

Example:
```julia
julia> i = input(Int)
       n = lag(2, i)
       map(print, n)
       s = Source(i)
       for x = 1:7
           push!(s, x)
       end
12345
```
"""
function lag(n::Integer, node::Node; name = nothing)
    T = getoperationtype(node)
    lagnode = foldl(Lag(T, n), node; name) do state, x
        push!(state, x)
        state
    end
    condition = inlinedmap(lag -> lag.initialized, lagnode; name)
    lagnode_initialized = select(lagnode, condition; name)
    inlinedmap(lag -> lag[], lagnode_initialized; name)
end
