mutable struct Lag{T}
    const x::Vector{T}
    const n::Int
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

function lag(n::Integer, node::Node; name::Union{Nothing,Symbol} = nothing)
    T = getoperationtype(node)
    lagnode = map!(Lag(T, n), node) do x0, x
        push!(x0, x)
    end
    lagnode_initialized = select(lagnode, inlinedmap(lag -> lag.initialized, lagnode))
    inlinedmap(lag -> lag[], lagnode_initialized; name)
end
