struct Quiet{T} <: Operation{T} end

function getvalue(node::ListNode, ::Quiet)
    node_name = getparentnames(node)
    getvalue(node, node_name) # todo: avoid starting from the leaf
end

function quiet(node::Node; name::Union{Nothing,Symbol}=nothing)
    filter(node, constant(false); name)
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::Tuple{Symbol},
    ::Type{<:Quiet},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = false
    end
end

