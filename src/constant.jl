abstract type AbstractConstant{T} <: Operation{T} end
struct TypeConstant{x,T} <: AbstractConstant{T}
    TypeConstant(x::T) where {T} = new{x,T}()
end
getvalue(::TypeConstant{trueorfalse}) where {trueorfalse} = trueorfalse

struct Constant{T} <: AbstractConstant{T}
    x::T
end
getvalue(c::Constant) = c.x

"""
    constant(x; name)

Bulds a node that contains the constant value x,
and that does not propagate directly.
If `x` is a `Bool`, then the constant value will be propagated
by Julia's compiler.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function constant(x; name = nothing)
    uniquename = genname(name)
    op = if x isa Bool
        TypeConstant(x)
    else
        Constant(x)
    end
    Node(uniquename, op)
end

getvalue(::ListNode, element::AbstractConstant) = getvalue(element)

function generate(::Symbol, name::Symbol, parentnames::Tuple{}, ::Type{<:AbstractConstant})
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    quote
        $initialized_s = true
        $updated_s = false
    end
end
