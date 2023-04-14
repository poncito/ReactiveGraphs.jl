struct Filter{T} <: Operation{T} end

function getvalue(node::ListNode, ::Filter)
    node_name, _ = getparentnames(node)
    getvalue(node, node_name) # todo: avoid starting from the leaf
end

function Base.filter(x::Node, condition::Node; name::Union{Nothing,Symbol} = nothing)
    uniquename = genname(name)
    op = Filter{getoperationtype(x)}()
    Node(uniquename, op, x, condition)
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Filter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(Meta.quot(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[2])
    end
end
