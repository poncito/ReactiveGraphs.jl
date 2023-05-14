# todo: ensure that the node exists, and is an input
struct Source{inputname,T,LN<:ListNode}
    list::LN
    function Source(listnode::LN, inputname::Symbol) where {LN<:ListNode}
        node = getnode(listnode, TypeSymbol(inputname))
        T = eltype(node)
        new{inputname,T,LN}(listnode)
    end
end

"""
    Source(::Node)

Transforms an input node into a `Source`, which is a type stable version of the former.
This type is used to update the roots of the graph with `Base.push!`.
The input objects are not used directly, for performance considerations.

```julia
julia> i = input(String)
       m = map(println, i)
       s = source(i)
       push!(s, "example")
example

julia> i = input(Ref(0))
       m = map(println, i)
       s = Source(i)
       push!(s, ref -> ref[] = 123)
123
```

Sources can also be used simultaneously,

```julia
julia> i1 = input(Int)
       i2 = input(Int)
       m1 = map(+, i1, i2)
       map(print, m)
       s1 = source(i1)
       s2 = source(i2)
       push!(s1, s2, 1, 2)
       push!(s1, s2, 3, 4)
37
```
"""
Source(node::Node) = Source(getgraph(node)[], getname(node))

function Base.show(io::IO, s::Source{inputname,T}) where {inputname,T}
    print(io, "Source($inputname, $T)")
end

getlisttype(::TypeOrValue{Source{inputname,T,LN}}) where {inputname,T,LN} = LN
getinputname(::TypeOrValue{Source{inputname,T,LN}}) where {inputname,T,LN} = inputname

Base.push!(src::Source, x) = push!((src,), (x,))

@generated function Base.push!(src::NTuple{N,Source}, x::NTuple{N,Any}) where {N}
    src_types = fieldtypes(src)
    inputnames = getinputname.(src_types)
    listtypes = getlisttype.(src_types)

    if !allequal(listtypes)
        throw(ErrorException("nodes do not belong to the same graph"))
    end
    LN = first(listtypes)

    expr = quote
        list = first(src).list
    end
    generate!(expr, LN, inputnames...)
    push!(expr.args, nothing)
    expr
end

generate!(::Expr, ::Type{Root}, ::Symbol...) = nothing
function generate!(
    expr::Expr,
    ::Type{ListNode{name,parentnames,X,Next}},
    inputnames::Symbol...,
) where {name,parentnames,X,Next}
    generate!(expr, Next, inputnames...)
    e = generate(inputnames, name, parentnames, X)
    append!(expr.args, e.args)
    expr
end

# getvalue(list::ListNode, name::Symbol) = getnode(list, name) |> getvalue
getvalue(list::ListNode, v::TypeSymbol) = getnode(list, v) |> getvalue
getvalue(node::ListNode) = getvalue(node, getelement(node))

function debugsource(src::Source{inputnames,LN}) where {inputnames,LN}
    generate!(Expr(:block), LN, inputnames...)
end
