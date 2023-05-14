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

```jldoctest
julia> i = input(String)
       map(println, i)
       s = Source(i)
       push!(s, "example")
example

julia> i = input(Ref(0))
       map(x->println(x[]), i)
       s = Source(i)
       push!(s, ref -> ref[] = 123)
123
```

Sources can also be used simultaneously,

```jldoctest
julia> i1 = input(Int)
       i2 = input(Int)
       m = map(+, i1, i2)
       map(print, m)
       s1 = Source(i1)
       s2 = Source(i2)
       push!(s1 => 1, s2 => 2)
       push!(s1 => 3, s2 => 4)
37
```
"""
Source(node::Node) = Source(getgraph(node)[], getname(node))

function Base.show(io::IO, s::Source{inputname,T}) where {inputname,T}
    print(io, "Source($inputname, $T)")
end

getlisttype(::TypeOrValue{Source{inputname,T,LN}}) where {inputname,T,LN} = LN
getinputname(::TypeOrValue{Source{inputname,T,LN}}) where {inputname,T,LN} = inputname

Base.push!(src::Source, x) = push!(src=>x)

@generated function Base.push!(p::Pair{<:Source,<:Any}...)
    src_types = p .|> fieldtypes .|> first
    inputnames = getinputname.(src_types)
    listtypes = getlisttype.(src_types)

    if !allequal(listtypes)
        throw(ErrorException("nodes do not belong to the same graph"))
    end
    LN = first(listtypes)

    expr = quote
        x = Base.Cartesian.@ncall $(length(p)) tuple i->p[i][2]
        list = p[1][1].list
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
