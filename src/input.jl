mutable struct Input{T} <: Operation{T}
    isinitialized::Bool
    x::T
    Input{T}() where {T} = new{T}(false)
    Input(x::T) where {T} = new{T}(false, x)
end

getvalue(x::Input) = x.x
isinitialized(i::Input) = i.isinitialized

function update!(i::Input, x)
    i.isinitialized = true
    i.x = x
end

function update!(i::Input, f!::Function)
    i.isinitialized = true
    f!(i.x)
end

function input(::Type{T}; name::Union{Nothing,Symbol} = nothing) where {T}
    uniquename = genname(name)
    op = Input{T}()
    Node(uniquename, op)
end

function input(x::T; name::Union{Nothing,Symbol} = nothing) where {T}
    uniquename = genname(name)
    op = Input(x)
    Node(uniquename, op)
end

getvalue(::ListNode, element::Input) = getvalue(element)

function generate(inputname::Symbol, name::Symbol, ::NTuple{<:Any,Symbol}, ::Type{<:Input})
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Symbol(:node, name)
    expr = Expr(:quote)
    push!(expr.args, :($updated_s = $(name == inputname)))
    push!(expr.args, :($nodename_s = getnode(list, $(TypeSymbol(name)))))
    if name == inputname
        push!(expr.args, :($(Expr(:call, :update!, nodename_s, :x))))
    end
    push!(expr.args, :($initialized_s = $(name == inputname ? true : :(isinitialized($nodename_s)))))
    expr
end
