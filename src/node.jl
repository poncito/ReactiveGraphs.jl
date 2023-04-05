struct Args{names}
    Args() = new{()}()
    Args(names::Symbol...) = new{names}()
end

getnames(::TypeOrValue{Args{names}}) where {names} = names

struct Node{name,A<:Args,O<:Operation}
    graph::Graph
    args::A
    operation::O
end

function Node(name::Symbol, op::Operation, args::Node...)
    graph = if isempty(args)
        Graph()
    else
        merge!((n.graph for n in args)...) # return Root() if empty
    end
    args_ = Args((getname(a) for a in args)...)
    node = Node{name,typeof(args_),typeof(op)}(graph, args_, op)
    push!(graph, node)
    node
end

getname(::TypeOrValue{Node{name,A,O}}) where {name,A,O} = name
getnames(::TypeOrValue{<:Node{name,A}}) where {name,A} = getnames(A)
Base.eltype(nodetype::TypeOrValue{<:Node}) = eltype(getoperation(nodetype))
getvalue(x::Node) = getvalue(x.operation)
getstate(x::Node) = getstate(x.operation)
getoperation(node::Node) = node.operation
getgraph(node::Node) = node.graph

getname(::TypeOrValue{<:ListNode{X}}) where {X} = getname(X)

update!(node, args...) = update!(getoperation(node), args...)
isinitialized(node, args...) = isinitialized(getoperation(node), args...)
Args(nodes::Node...) = Args(getname.(nodes)...)
(node::Node)(args...) = node.operation(args...)
