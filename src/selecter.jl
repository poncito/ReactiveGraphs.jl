struct Selecter{T} <: Operation{T} end

"""
    select(x::Node, condition::Node; name)

Bulds a node that contains the same value as node `x`,
but that prevents updating its children when
the value of `condition` is `false`.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function select(x::Node, condition::Node; name::Union{Nothing,Symbol} = nothing)
    uniquename = genname(name)
    op = Selecter{getoperationtype(x)}()
    Node(uniquename, op, x, condition)
end

"""
    select(f::Function, x::Node; name)

Bulds a node that contains the same value as node `x`,
but that prevents updating its children when
the value of `map(f, x)` is `false`.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function select(f::Function, x::Node; name::Union{Nothing,Symbol} = nothing)
    condition = inlinedmap(f, x)
    if eltype(condition) != Bool
        throw(ErrorException("map(f, x) is not a boolean node"))
    end
    select(x, condition; name)
end

function getvalue(node::ListNode, ::Selecter)
    node_name, _ = getparentnames(node)
    getvalue(node, TypeSymbol(node_name)) # todo: avoid starting from the leaf
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Selecter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(TypeSymbol(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $initialized_s = $condition_initialized & $(args[2])
        $updated_s = $initialized_s & $condition_updated
    end
end
