abstract type AbstractConstant{T} <: Operation{T} end
struct TypeConstant{x,T} <: AbstractConstant{T}
    TypeConstant(x::T) where {T} = new{x,T}()
end
getvalue(::TypeConstant{trueorfalse}) where {trueorfalse} = trueorfalse

struct Constant{T} <: AbstractConstant{T}
    x::T
end
getvalue(c::Constant) = c.x

function constant(x; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = Constant(x)
    Node(uniquename, op)
end

function constant(x::Bool; name::Union{Nothing,Symbol}=nothing)
    uniquename = genname(name)
    op = TypeConstant(x)
    Node(uniquename, op)
end

getvalue(::ListNode, element::AbstractConstant) = getvalue(element)

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::Tuple{},
    ::Type{<:AbstractConstant},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    quote
        $initialized_s = true
        $updated_s = false
    end
end

