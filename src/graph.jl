struct Root end

struct ListNode{X,Next}
    x::X
    next::Next
end

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
    f(n.x)
end

function Base.push!(graph::Graph, x)
    graph[] = ListNode(x, graph[])
    graph
end

Base.merge!(graph::Graph) = graph
function Base.merge!(graph1::Graph, graph2::Graph, graphs...)
    if graph1 != graph2
        map(graph2) do x
            push!(graph1, x)
        end
        graph2.last = graph1.last
    end
    merge!(graph1, graphs...)
end

# the error should be arise at the highest level of the recursion
getnode(::Root, name::Symbol) = throw(ErrorException("symbol $(name) not found in graph"))
function getnode(x::ListNode, name::Symbol)
    if getname(x.x) == name
        x.x
    else
        getnode(x.next, name)
    end
end
