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
    generate!(expr, inputname, name, parentnames, X) 
    expr
end

function generate!(
    expr::Expr,
    inputname::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Input},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    nodename_s = Meta.quot(name)
    e = quote
        $updated_s = $(name == inputname) 
        node = getnode(list, $nodename_s)
        if $updated_s
            $(Expr(:call, :update!, :node, :x))
        end
        $initialized_s = isinitialized(node) 
    end
    append!(expr.args, e.args)
end

function generate!(
    expr::Expr,
    inputname::Symbol,
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
    e = quote
        $initialized_s = $condition_initialized
        $updated_s = if $initialized_s & $condition_updated
            node = getnode(list, $nodename_s)
            $(Expr(:call, :update!, :node, args...))
            true
        else
            false
        end
    end
    append!(expr.args, e.args)
end

function generate!(
    expr::Expr,
    inputname::Symbol,
    name::Symbol,
    parentnames::NTuple{<:Any,Symbol},
    ::Type{<:Filter},
)
    updated_s = Symbol(:updated, name)
    initialized_s = Symbol(:initialized, name)
    args = [:(getvalue(list, $(Meta.quot(n)))) for n in parentnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in parentnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in parentnames)...)
    e = quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[1])
    end
    append!(expr.args, e.args) # appending to the function body
end

function getvalue(list::ListNode, name::Symbol)
    node = getnode(list, name)
    if getelement(node) isa Filter
        _, node_name = getparentnames(node)
        getvalue(list, node_name) # todo: avoid starting from the leaf
    else
        node |> getelement |> getvalue
    end
end

