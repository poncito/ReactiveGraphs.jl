struct Filter{T} <: Operation{T} end

"""
    filter(x::Node, condition::Node; name)

Bulds a node that contains the same value as node `x`,
but that only forwards an update when the value of node `condition` 
is true.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function Base.filter(x::Node, condition::Node; name = nothing)
    uniquename = genname(name)
    op = Filter{getoperationtype(x)}()
    Node(uniquename, op, x, condition)
end

function Base.filter(f::Function, x::Node; name::Union{Nothing,Symbol} = nothing)
    condition = map(f, x; name)
    if eltype(condition) != Bool
        throw(ErrorException("condition is not a boolean"))
    end
    filter(x, condition; name)
end

function getvalue(node::ListNode, ::Filter)
    node_name, _ = getparentnames(node)
    getvalue(node, node_name) # todo: avoid starting from the leaf
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Filter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(TypeSymbol(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[2])
    end
end
