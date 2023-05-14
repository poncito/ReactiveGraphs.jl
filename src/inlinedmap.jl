struct InlinedMap{T,F} <: Operation{T}
    f::F
end

InlinedMap(::Type{T}, f::F) where {T,F} = InlinedMap{T,F}(f)

# todo: can we have an inlinedmap with no argument?
# if so, could we remove the constants?
"""
    inlinedmap(f, arg::Node, args::Node...; name)

Similarly to `map`, creates a node whose value is given by
calling `f` with the values of the nodes `(arg, arg...)`.
Contrarily to map, the value is not stored, and the function
call is performed each time the value of the node is required.

See the implementation of `lag` for a use case example.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function inlinedmap(f, arg::Node, args::Node...; name = nothing)
    uniquename = genname(name)
    argtypes = getoperationtype.((arg, args...))
    T = Base._return_type(f, Tuple{argtypes...})
    op = InlinedMap(T, f)
    Node(uniquename, op, arg, args...)
end

function generate(
    ::Any,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:InlinedMap},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $condition_initialized & $condition_updated
    end
end

@generated function getvalue(node::ListNode, imap::InlinedMap)
    names = getparentnames(node)
    quote
        Base.@ncall $(length(names)) imap.f i -> (getvalue(node, TypeSymbol($names[i])))
    end
end
