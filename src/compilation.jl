# todo: ensure that the node exists, and is an input
struct Source{inputname,LN<:ListNode}
    list::LN
    Source(inputname::Symbol, list::LN) where {LN<:ListNode} = new{inputname,LN}(list)
end

"""
    Source(::Node)

Transforms an input node into a `Source`, which is a type stable version of the former.
This type is used to `push!` values into the computational graph.
The input objects are not used directly, for performance considerations.

```julia
julia> i = input(String)
       m = map(println, i)
       s = Source(i)
       push!(s, "example")
example
```
"""
Source(node::Node) = Source(getname(node), getgraph(node)[])

function Base.show(io::IO, s::Source{inputname}) where {inputname}
    type = eltype(s.list)
    print(io, "Source($inputname, $type)")
end

@generated function Base.setindex!(src::Source{inputname,LN}, x) where {inputname,LN}
    expr = quote
        list = src.list
    end
    generate!(expr, LN, inputname)
    push!(expr.args, nothing)
    expr
end

generate!(::Expr, ::Type{Root}, ::Symbol) = nothing
function generate!(
    expr::Expr,
    ::Type{ListNode{name,parentnames,X,Next}},
    inputname::Symbol,
) where {name,parentnames,X,Next}
    generate!(expr, Next, inputname)
    e = generate(inputname, name, parentnames, X)
    append!(expr.args, e.args)
    expr
end

# getvalue(list::ListNode, name::Symbol) = getnode(list, name) |> getvalue
getvalue(list::ListNode, v::TypeSymbol) = getnode(list, v) |> getvalue
getvalue(node::ListNode) = getvalue(node, getelement(node))

function debugsource(src::Source{inputname,LN}) where {inputname,LN}
    generate!(Expr(:block), LN, inputname)
end
