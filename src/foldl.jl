mutable struct Foldl{TState,F} <: Operation{TState}
    f::F
    state::TState
end
@inline getvalue(x::Foldl) = x.state
@inline getvalue(::ListNode, element::Foldl) = getvalue(element)

@inline function update!(m::Foldl, args...)
    @tryinline state = m.f(m.state, args...)
    if typeof(state) != typeof(m.state)
        throw(E)
    end
    m.state = state
    nothing
end

# todo: can we have an linedmap with no argument?
# if so, could we remove the constants?
"""
    foldl(f, state, arg::Node, args::Node...; name)

Creates a node that contains a state initialized by `state`.
When any of the arguments are updated, the state is updated by calling
`state_updated = f(state, arg, args...)`.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function Base.foldl(
    f::Function,
    state::TState,
    arg::Node,
    args::Node...;
    name = nothing,
) where {TState}
    Node(genname(name), Foldl(f, state), arg, args...)
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Foldl},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = (:(getvalue(list, $(TypeSymbol(n)))) for n in parentnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n in parentnames)...)
    condition_initialized =
        Expr(:call, :&, (Symbol(:initialized, n) for n in parentnames)...)
    nodename_s = Symbol(:node, name)
    quote
        $updated_s = if $condition_initialized & $condition_updated
            $nodename_s = getnode(list, $(TypeSymbol(name)))
            $(Expr(:call, :update!, nodename_s, args...))
            true
        else
            false
        end
        $initialized_s = $updated_s
    end
end
