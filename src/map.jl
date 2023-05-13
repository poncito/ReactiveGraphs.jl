mutable struct Map{T,F} <: Operation{T}
    f::F
    x::T
    Map{T}(f::F) where {T,F} = new{T,F}(f)
end

@inline getvalue(x::Map) = x.x
@inline getvalue(::ListNode, element::Map) = getvalue(element)

@inline function update!(m::Map, args...)
    @tryinline m.x = m.f(args...)
    nothing
end
"""
    map(f, arg::Node, args::Node...; name)

Creates a node whose value is given by
calling `f` with the values of the nodes `(arg, arg...)`.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function Base.map(f::Function, arg::Node, args::Node...; name = nothing)
    uniquename = genname(name)
    argtypes = getoperationtype.((arg, args...))
    T = Base._return_type(f, Tuple{argtypes...})
    op = Map{T}(f)
    Node(uniquename, op, arg, args...)
end


function generate(::Symbol, name::Symbol, parentnames::NTuple{<:Any,Symbol}, ::Type{<:Map})
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = (:(getvalue(list, $(TypeSymbol(n)))) for n in parentnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    nodename_s = Symbol(:node, name)
    quote
        $initialized_s = $condition_initialized
        $updated_s = if $condition_initialized & $condition_updated
            $nodename_s = getnode(list, $(TypeSymbol(name)))
            $(Expr(:call, :update!, nodename_s, args...))
            true
        else
            false
        end
    end
end
