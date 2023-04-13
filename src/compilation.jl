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

function getvalue(list::ListNode, name::Symbol)
    node = getnode(list, name)
    getvalue(node, getelement(node)) 
end


