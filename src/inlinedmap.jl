struct InlinedMap{T,F} <: Operation{T}
    f::F
end

InlinedMap(::Type{T}, f::F) where {T,F} = InlinedMap{T,F}(f)

# todo: can we have an linedmap with no argument?
# if so, could we remove the constants?
"""julia
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
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:InlinedMap},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Meta.quot(name)
    args = (:(getvalue(list, $(Meta.quot(n)))) for n in parentnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    quote
        $updated_s = $condition_initialized & $condition_updated
        $initialized_s = $updated_s
    end
end

function getvalue(node::ListNode, imap::InlinedMap)
    imap.f((getvalue(node, name) for name in getparentnames(node))...)
end
