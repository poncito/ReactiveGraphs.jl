struct Selecter{T} <: Operation{T} end

function getvalue(node::ListNode, ::Selecter)
    node_name, _ = getparentnames(node)
    getvalue(node, node_name) # todo: avoid starting from the leaf
end

function select(x::Node, condition::Node; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Selecter{getoperationtype(x)}()
    Node(uniquename, op, x, condition)
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Selecter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(Meta.quot(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $initialized_s = $condition_initialized  & $(args[2])
        $updated_s = $initialized_s & $condition_updated
    end
end

