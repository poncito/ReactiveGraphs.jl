mutable struct Updated <: Operation{Bool}
    updated::Bool
end

"""
    updated(arg::Node; name)

Creates a node that contains true when the node arg has been updated,
false otherwise.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function updated(arg::Node; name = nothing)
    uniquename = genname(name)
    op = Updated(false)
    Node(uniquename, op, arg)
end

@inline function update!(x::Updated, updated::Bool)
    x.updated = updated
    nothing
end

function generate(::Any, name::Symbol, parentnames::NTuple{<:Any,Symbol}, ::Type{<:Updated})
    @assert length(parentnames) == 1
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    condition_updated = Symbol(:updated, first(parentnames))
    condition_initialized = Symbol(:initialized, first(parentnames))
    nodename_s = Symbol(:node, name)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $condition_initialized & $condition_updated
        $nodename_s = getnode(list, $(TypeSymbol(name)))
        $(Expr(:call, :update!, nodename_s, updated_s))
    end
end

@inline getvalue(x::Updated) = x.updated
@inline getvalue(::ListNode, element::Updated) = getvalue(element)
