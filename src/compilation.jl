# todo: ensure that the node exists, and is an input
struct Source{inputnames,LN<:ListNode}
    list::LN
    function Source(listnode::LN, inputnames::Symbol...) where {LN<:ListNode}
        @assert !isempty(inputnames)
        new{inputnames,LN}(listnode)
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
       s = Source(i)
       push!(s, "example")
example

julia> i = input(Ref(0))
       m = map(println, i)
       s = Source(i)
       push!(s, ref -> ref[] = 123)
123
```
"""
Source(node::Node) = Source(getgraph(node)[], getname(node))

"""
    Source(::Node, ::Node...)

Transforms a set of input nodes into a `Source`, which is a type stable version of a set of nodes.
This type is used to update the roots of the graph with `push!`.
The input objects are not used directly, for performance considerations.

```julia
julia> i1 = input(String)
       i2 = input(String)
       m1 = map(x->println(join(x, " ")), i1, i2)
       s = Source(i1, i2)
       push!(s, "a", "b")
"a b"

julia> i1 = input(Ref(0))
       i2 = input(Ref(0))
       m = map((x, y) -> println(x+y), i1, i2)
       s = Source(i1, i2)
       push!(s, ref -> ref[] = 123, ref -> ref[] = 321)
444
```
"""
function Source(node::Node)
    nodes = (node, nodes...)
    aregraphsequal = allequal(map(getgraph, nodes))
    if !aregraphsequal
        throw(ErrorException("Nodes do not belong to the same graphs"))
    end
    Source(getgraph(node)[], map(getname, nodes)...)
end

function Base.show(io::IO, s::Source{inputnames}) where {inputnames}
    print(io, "Source($(join(inputnames, ", ")))")
end

@generated function Base.push!(src::Source{inputnames,LN}, x...) where {inputnames,LN}
    @assert length(x) == length(inputnames)

    expr = quote
        list = src.list
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
