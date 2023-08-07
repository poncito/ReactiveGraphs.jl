mutable struct Graph{N}
    ref::Base.RefValue{Vector{N}}
end

Graph{N}() where {N} = Graph(Ref(N[]))
Base.push!(g::Graph{N}, n::N) where {N} = push!(g.ref[], n)

mutable struct Node
    graph::Graph{Node}
    @tryconst name::Symbol
    @tryconst parentnames::Vector{Symbol}
    @tryconst operation::Operation
end

# todo: make sure name is unique
function Node(name::Symbol, op::Operation, parents::Node...)
    graph = mergegraphs!(parents...)
    parentnames = [a.name for a in parents]
    node = Node(graph, name, parentnames, op)
    push!(graph, node)
    node
end

Base.eltype(node::Node) = eltype(node.operation)

function Base.show(io::IO, node::Node)
    name = node.name
    type = eltype(node)
    print(io, "Node($name,$type)")
end

mergegraphs!() = Graph{Node}()
mergegraphs!(node::Node) = node.graph
function mergegraphs!(node1::Node, node2::Node, nodes::Node...)
    if node1.graph.ref != node2.graph.ref
        append!(node1.graph.ref[], node2.graph.ref[])
        empty!(node2.graph.ref[])
        node2.graph.ref = node1.graph.ref
    end
    mergegraphs!(node1, nodes...)
end
