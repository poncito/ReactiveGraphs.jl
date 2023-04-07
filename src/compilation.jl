struct Source{inputname,LN<:ListNode}
    list::LN
    Source(inputname::Symbol, list::LN) where {LN<:ListNode} = new{inputname,LN}(list)
end

Source(node::Node) = Source(getname(node), getgraph(node)[])

@generated function Base.setindex!(src::Source{inputname,LN}, x) where {inputname,LN}
    expr = quote
        list = src.list
    end
    generate!(expr, LN, inputname)
    expr
end

generate!(::Expr, ::Type{Root}, ::Symbol) = nothing
function generate!(
    expr::Expr,
    ::Type{ListNode{name, parentnames, X, Next}},
    inputname::Symbol,
) where {name, parentnames, X, Next}
    generate!(expr, Next, inputname) 
    e = generate(inputname, name, parentnames, X) 
    append!(expr.args, e.args)
    expr
end

function generate(
    inputname::Symbol,
    name::Symbol,
    ::NTuple{<:Any,Symbol},
    ::Type{<:Input},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Meta.quot(name)
    quote
        $updated_s = $(name == inputname) 
        node = getnode(list, $nodename_s)
        if $updated_s
            $(Expr(:call, :update!, :node, :x))
        end
        $initialized_s = $(name == inputname ? true : :(isinitialized(node)))
    end
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Map},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Meta.quot(name)
    args = (:(getvalue(list, $(Meta.quot(n)))) for n in parentnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = if $initialized_s & $condition_updated
            node = getnode(list, $nodename_s)
            $(Expr(:call, :update!, :node, args...))
            true
        else
            false
        end
    end
end

function generate(
    ::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Filter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(Meta.quot(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[2])
    end
end

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

function getvalue(list::ListNode, name::Symbol)
    node = getnode(list, name)
    if getelement(node) isa Filter
        node_name, _ = getparentnames(node)
        getvalue(list, node_name) # todo: avoid starting from the leaf
    elseif getelement(node) isa Quiet
        node_name = getparentnames(node)
        getvalue(list, node_name) # todo: avoid starting from the leaf
    else
        node |> getelement |> getvalue
    end
end

