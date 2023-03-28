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
    @info "expr" expr
    expr
end

generate!(::Expr, ::Type{Root}, ::Symbol) = nothing
function generate!(
    expr::Expr,
    ::Type{ListNode{X,Next}},
    inputname::Symbol,
) where {X, Next}
    generate!(expr, Next, inputname) 
    generate!(expr, X, Next, inputname) 
    expr
end

function generate!(
    expr::Expr,
    ::Type{<:Node{T,nodename,A,O}},
    nexttype::Type{<:Union{Root,ListNode}},
    inputname::Symbol,
) where {T,nodename,A,O<:Input}
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    nodename_s = Meta.quot(nodename)
    e = if nodename == inputname
        quote
            $updated_s = true 
            $initialized_s = true 
            node = getnode(list, $nodename_s)
            $(Expr(:call, :update!, :node, :x))
        end
    else
        quote
            $updated_s = false
            node = getnode(list, $nodename_s)
            $initialized_s = isinitialized(node) 
        end
    end
    append!(expr.args, e.args)
end

function generate!(
    expr::Expr,
    ::Type{<:Node{T,nodename,A,O}},
    nexttype::Type{<:Union{Root,ListNode}},
    inputname::Symbol,
) where {T,nodename,A,O<:Map}
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    nodename_s = Meta.quot(nodename)
    args = (:(getvalue(list, $(Meta.quot(name)))) for name in getnames(A))
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in getnames(A))...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in getnames(A))...)
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
    ::Type{<:Node{T,nodename,A,O}},
    nexttype::Type{<:Union{Root,ListNode}},
    inputname::Symbol,
) where {T,nodename,A,O<:Filter}
    updated_s = Symbol(:updated, nodename)
    initialized_s = Symbol(:initialized, nodename)
    args = [:(getvalue(list, $(Meta.quot(name)))) for name in getnames(A)]
    condition_updated = Expr(:call, :|, (Symbol(:updated, n) for n  in getnames(A))...)
    condition_initialized = Expr(:call, :&, (Symbol(:initialized, n) for n  in getnames(A))...)
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

