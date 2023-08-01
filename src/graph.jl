mutable struct Node
    ref::Base.RefValue{Vector{Node}}
    @tryconst name::Symbol
    @tryconst parentnames::Vector{Symbol}
    @tryconst operation::Operation
end

# todo: make sure name is unique
function Node(name::Symbol, op::Operation, parents::Node...)
    ref = mergegraphs!(parents...)
    parentnames = [a.name for a in parents]
    node = Node(ref, name, parentnames, op)
    push!(ref[].nodes, node)
    node
end

Base.eltype(node::Node) = eltype(node.operation)

function Base.show(io::IO, node::Node)
    name = node.name
    type = eltype(node)
    print(io, "Node($name,$type)")
end

mergegraphs!() = Graph(Node[], nothing)
mergegraphs!(node::Node) = node.ref
function mergegraphs!(node1::Node, node2::Node, nodes::Node...)
    if node1.ref != node2.ref
        append!(node1.ref[], node2.ref[])
        node2.ref = node1.ref
    end
    mergegraphs!(node1, nodes...)
end

# """
#     Node{name}

# Objects of type `Node` correspond to the nodes of the computational graph.
# Each node is identified by a uniquely generated name `name`.
# """
# struct Node{name}
#     graph::GraphRef
#     Node(name::Symbol, graph::GraphRef) = new{name}(graph)
# end

# function Base.show(io::IO, node::Node)
#     name = getname(node)
#     type = eltype(node)
#     print(io, "Node($name,$type)")
# end

# Base.eltype(node::Node) = node |> getedge |> eltype
# getname(::TypeOrValue{Node{name}}) where {name} = name
# getgraph(node::Node) = node.graph
# getedge(node::Node) = getedge(getgraph(node), TypeSymbol(getname(node)))

# function Node(name::Symbol, op::Op, parents::Node...) where {Op <: Operation}
#     graph = if isempty(parents)
#         GraphRef()
#     else
#         merge!((n.graph for n in parents)...) # return Root() if empty
#     end
#     parentnames = Tuple(getname(a) for a in parents)
#     push!(graph, name, parentnames, op)
#     Node(name, graph)
# end

# update!(node, args...) = update!(getedge(node), args...)
# # isinitialized(node, args...) = isinitialized(getedge(node), args...)
# (node::Node)(args...) = getedge(node)(args...)

# @inline getvalue(::Graph, element::Operation) = getvalue(element)
# getoperationtype(node::Node) = getedge(node) |> getoperationtype
