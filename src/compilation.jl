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
    ::Type{ListNode{X,Next}},
    inputname::Symbol,
) where {X, Next}
    generate!(expr, Next, inputname) 
    generate!(expr, X, inputname) 
    expr
end

NodeInput{T,nodename,A,O<:Input} = Node{T,nodename,A,O}
NodeMap{T,nodename,A,O<:Map} = Node{T,nodename,A,O}
NodeFilter{T,nodename,A,O<:Filter} = Node{T,nodename,A,O}

function generate!(
    expr::Expr,
    nodetype::Type{<:NodeInput},
    inputname::Symbol,
)
    nodename = getname(nodetype)
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    nodename_s = Meta.quot(nodename)
    e = quote
        $updated_s = $(nodename == inputname) 
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
    nodetype::Type{<:NodeMap},
    ::Symbol,
)
    nodename = getname(nodetype)
    argnames = getnames(nodetype)
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    nodename_s = Meta.quot(nodename)
    args = (:(getvalue(list, $(Meta.quot(name)))) for name in argnames)
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in argnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in argnames)...)
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
    nodetype::Type{<:NodeFilter},
    ::Symbol,
)
    nodename = getname(nodetype)
    argnames = getnames(nodetype)
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    args = [:(getvalue(list, $(Meta.quot(name)))) for name in argnames]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in argnames)...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in argnames)...)
    e = quote
        $initialized_s = $condition_initialized
        $updated_s = $initialized_s & $condition_updated & $(args[1])
    end
    append!(expr.args, e.args) # appending to the function body
end

function getvalue(list::ListNode, name::Symbol)
    node = getnode(list, name)
    if node.operation isa Filter
        _, node_name = getnames(node)
        getvalue(list, node_name) # todo: avoid starting from the leaf
    else
        getvalue(node)
    end
end

