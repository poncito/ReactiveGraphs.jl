mutable struct Input{T} <: Operation{T}
    isinitialized::Bool
    x::T
    Input{T}() where {T} = new{T}(false)
    Input(x::T) where {T} = new{T}(false, x)
end

getvalue(x::Input) = x.x
isinitialized(i::Input) = i.isinitialized

function update!(i::Input, x)
    i.isinitialized = true
    i.x = x
end

function update!(i::Input, f!::Function)
    i.isinitialized = true
    f!(i.x)
end


"""
    input(::Type{T}; name)

Creates a node that will contain a element of type `T`.
To push a value in the node, one need to wrap it in a `Source`,
and call `setindex!`. See [`Source`](@ref).

If `name` is provided, it will be appended to the
generated symbol that identifies the node.

Example:
```julia
julia> i = input(Int)
       s = Source(i)
       push!(s, 1)
```
"""
function input(::Type{T}; name = nothing) where {T}
    uniquename = genname(name)
    op = Input{T}()
    Node(uniquename, op)
end

"""
    input(x; name)

Creates a node that contains `x`.
This should be used when `x` is mutable.
To push a value in the node, one need to wrap it in a `Source`,
and call `setindex!`.  See [`Source`](@ref).

If `name` is provided, it will be appended to the
generated symbol that identifies the node.

Example:
```julia
julia> i = input(Ref(0))
       s = Source(i)
       push!(s, x -> x[] = 1)
```
"""
function input(x::T; name::Union{Nothing,Symbol} = nothing) where {T}
    uniquename = genname(name)
    op = Input(x)
    Node(uniquename, op)
end

getvalue(::Graph, element::Input) = getvalue(element)

function generate(
    inputnames::NTuple{<:Any,Symbol},
    name::Symbol,
    ::NTuple{<:Any,Symbol},
    ::Type{<:Input},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Symbol(:node, name)
    i = findfirst(==(name), inputnames)
    updated = !isnothing(i)

    expr = Expr(:quote)
    push!(expr.args, :($updated_s = $updated))
    push!(expr.args, :($nodename_s = getedge(list, $(TypeSymbol(name)))))
    if updated
        push!(
            expr.args,
            :($(Expr(:call, :update!, nodename_s, Expr(:ref, Expr(:ref, :p, i), 2)))),
        )
    end
    push!(expr.args, :($initialized_s = $(updated ? true : :(isinitialized($nodename_s)))))
    expr
end
