struct Root end

struct ListNode{name,parentnames,X,Next}
    x::X
    next::Next
    function ListNode(
        name::Symbol,
        parentnames::NTuple{<:Any,Symbol},
        x,
        next::Union{Root,ListNode},
    )
        new{name,parentnames,typeof(x),typeof(next)}(x, next)
    end
end

getname(::TypeOrValue{ListNode{name}}) where {name} = name
getparentnames(::TypeOrValue{ListNode{name,parentnames}}) where {name,parentnames} =
    parentnames
getelementtype(::TypeOrValue{ListNode{name,parentnames,X}}) where {name,parentnames,X} = X
getelement(n::ListNode) = n.x
getnext(n::ListNode) = n.next
Base.eltype(x::TypeOrValue{<:ListNode}) = eltype(getelementtype(x))

mutable struct Graph
    last::Ref{Union{Root,ListNode}}
end

Graph() = Graph(Ref{Union{Root,ListNode}}(Root()))

Base.:(==)(g1::Graph, g2::Graph) = g1.last == g2.last

Base.getindex(g::Graph) = g.last[]
function Base.setindex!(g::Graph, x::Union{Root,ListNode})
    g.last[] = x
    g
end

Base.map(f::Function, g::Graph) = map(f, g.last[])
Base.map(::Function, ::Root) = nothing
function Base.map(f::Function, n::ListNode)
    map(f, n.next)
    f(getname(n), getparentnames(n), n.x)
end

function Base.push!(graph::Graph, name, parentnames, x)
    graph[] = ListNode(name, parentnames, x, graph[])
    graph
end

Base.merge!(graph::Graph) = graph
function Base.merge!(graph1::Graph, graph2::Graph, graphs...)
    if graph1 != graph2
        map(graph2) do name, parentnames, x
            push!(graph1, name, parentnames, x)
        end
        graph2.last = graph1.last
    end
    merge!(graph1, graphs...)
end

# the error should be arise at the highest level of the recursion
getnode(graph::Graph, name::Symbol) = getnode(graph[], name)
getnode(::Root, name::Symbol) = throw(ErrorException("symbol $(name) not found in graph"))
function getnode(x::ListNode, name::Symbol)
    if getname(x) == name
        x
    else
        getnode(x.next, name)
    end
end

"""
    Node{name}

Objects of type `Node` correspond to the nodes of the computational graph.
Each node is identified by a uniquely generated name `name`.
"""
struct Node{name}
    graph::Graph
    Node(name::Symbol, graph::Graph) = new{name}(graph)
end

function Base.show(io::IO, node::Node)
    name = getname(node)
    type = eltype(node)
    print(io, "Node($name,$type)")
end

Base.eltype(node::Node) = node |> getnode |> eltype
getname(::TypeOrValue{Node{name}}) where {name} = name
getgraph(node::Node) = node.graph
getnode(node::Node) = getnode(getgraph(node), getname(node))

function Node(name::Symbol, x::X, parents::Node...) where {X}
    graph = if isempty(parents)
        Graph()
    else
        merge!((n.graph for n in parents)...) # return Root() if empty
    end
    parentnames = Tuple(getname(a) for a in parents)
    push!(graph, name, parentnames, x)
    Node(name, graph)
end

update!(node, args...) = update!(getelement(node), args...)
isinitialized(node, args...) = isinitialized(getelement(node), args...)
(node::Node)(args...) = getelement(node)(args...)
