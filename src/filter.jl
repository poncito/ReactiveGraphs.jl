struct Filter{T} <: Operation{T} end

"""
    filter(x::Node, condition::Node; name)

Bulds a node that contains the same value as node `x`,
but that does not update its children when
the value of `condition` is true.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function Base.filter(x::Node, condition::Node; name = nothing)
    if eltype(condition) != Bool
        throw(ErrorException("eltype(condition) is $(eltype(condition)), expected Bool"))
    end
    uniquename = genname(name)
    op = Filter{eltype(x)}()
    Node(uniquename, op, x, condition)
end

"""
    filter(f::function, x::Node; name)

Bulds a node that contains the same value as node `x`,
but that only forwards an update when the function `f`
is returns `true`, while evaluated on the value of node `x`. 

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function Base.filter(f::Function, x::Node; name = nothing)
    condition = inlinedmap(f, x; name)
    if eltype(condition) != Bool
        throw(ErrorException("map(f, x) is not a boolean node"))
    end
    filter(x, condition; name)
end

function getvalue(graph::CompiledGraph, node::CompiledNode, ::Filter)
    parent_name = getparentnames(node) |> first |> TypeSymbol
    getvalue(graph, parent_name)
end

function generate(::Any, name::Symbol, parentnames::NTuple{<:Any,Symbol}, ::Type{<:Filter})
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(graph, $(TypeSymbol(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[2])
    end
end
