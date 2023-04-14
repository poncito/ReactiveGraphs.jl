struct InlinedMap{T,F} <: Operation{T}
    f::F
end

InlinedMap(::Type{T}, f::F) where {T,F} = InlinedMap{T,F}(f)

function inlinedmap(f, arg::Node, args::Node...; name=nothing)
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
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $updated_s = $condition_initialized & $condition_updated
        $initialized_s = $updated_s
    end
end

function getvalue(node::ListNode, imap::InlinedMap)
    imap.f((getvalue(node, name) for name in getparentnames(node))...)
end
