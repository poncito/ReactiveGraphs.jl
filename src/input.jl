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
       s[] = 1
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
       s[] = x -> x[] = 1
```
"""
function input(x::T; name::Union{Nothing,Symbol} = nothing) where {T}
    uniquename = genname(name)
    op = Input(x)
    Node(uniquename, op)
end

getvalue(::ListNode, element::Input) = getvalue(element)

function generate(inputname::Symbol, name::Symbol, ::NTuple{<:Any,Symbol}, ::Type{<:Input})
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Symbol(:node, name)
    expr = Expr(:quote)
    push!(expr.args, :($updated_s = $(name == inputname)))
    push!(expr.args, :($nodename_s = getnode(list, $(TypeSymbol(name)))))
    if name == inputname
        push!(expr.args, :($(Expr(:call, :update!, nodename_s, :x))))
    end
    push!(expr.args, :($initialized_s = $(name == inputname ? true : :(isinitialized($nodename_s)))))
    expr
end
