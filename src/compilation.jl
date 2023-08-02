struct CompiledNode{name,parentnames,Op<:Operation}
    operation::Op
    function CompiledNode(name::Symbol, parentnames::NTuple{N,Symbol}, operation::Operation) where {N}
        new{name, parentnames, typeof(operation)}(operation)
    end
end

getname(::TypeOrValue{CompiledNode{name}}) where {name} = name
getparentnames(::TypeOrValue{CompiledNode{name,parentnames}}) where {name,parentnames} =
    parentnames
getoperationtype(::TypeOrValue{CompiledNode{name,parentnames,Op}}) where {name,parentnames,Op} = Op
getoperation(n::CompiledNode) = n.operation

# function CompiledNode(node::Node)
#     CompiledNode(node.name, Tuple(node.parentnames), node.operation)
# end

struct CompiledGraph{N,T<:NTuple{N,CompiledNode},Tr<:AbstractGraphTracker}
    nodes::T
    tracker::Tr
end

# CompiledGraph(node::Node) = CompiledGraph(node.ref[])
# function CompiledGraph(nodes::Vector{Node})
#     Tuple(CompiledNode(n) for n in nodes) |> CompiledGraph
# end

nodetypes(::TypeOrValue{CompiledGraph{N,T}}) where {N,T} = T.parameters

@generated function Base.getindex(g::CompiledGraph{N}, ::TypeSymbol{name}) where {N, name}
    for (i, node) in nodetypes(g) |> enumerate
        getname(node) == name && return :(g.nodes[$i])
    end
    throw(ErrorException("symbol $name not found in graph $g"))
end

struct Source{inputname,T} end

Base.eltype(::TypeOrValue{Source{inputname,T}}) where {inputname,T} = T
getinputname(::TypeOrValue{Source{inputname,T}}) where {inputname,T} = inputname

"""
    Source(::Node)

Transforms an input node into a `Source`, which is a type stable version of the former.
This type is used to update the roots of the graph with `Base.push!`.
The input objects are not used directly, for performance considerations.

```jldoctest
julia> i = input(String)
       map(println, i)
       s = Source(i)
       push!(s, "example")
example

julia> i = input(Ref(0))
       map(x->println(x[]), i)
       s = Source(i)
       push!(s, ref -> ref[] = 123)
123
```

Sources can also be used simultaneously,

```jldoctest
julia> i1 = input(Int)
       i2 = input(Int)
       m = map(+, i1, i2)
       map(print, m)
       s1 = Source(i1)
       s2 = Source(i2)
       push!(s1 => 1, s2 => 2)
       push!(s1 => 3, s2 => 4)
37
```
"""
function Source(node::Node)
    @assert node.operation isa Input
    Source{node.name, eltype(node.operation)}()
end

function compile(inputs::Node...; tracker::AbstractGraphTracker=NullGraphTracker())
    @assert !isempty(inputs) 
    sources = Source.(inputs)

    @assert allequal(map(x->x.graph.ref, inputs))
    nodes = inputs[1].graph.ref[]
    compilednodes = Tuple(CompiledNode(node.name, Tuple(node.parentnames), node.operation) for node in nodes)
    compiledgraph = CompiledGraph(compilednodes, tracker)

    compiledgraph, sources...
end

@inline Base.push!(graph::CompiledGraph, src::Source, x) = push!(graph, src => x)
@generated function Base.push!(graph::CompiledGraph, p::Pair{<:Source,<:Any}...)
    sources = p .|> fieldtypes .|> first
    generate(graph, sources...)
end

function generate(graph::Type{<:CompiledGraph}, sources::Type{<:Source}...)
    inputnames = getinputname.(sources)
    expr = quote
        on_update_start!(graph.tracker, $(inputnames))
    end
    for compilednodetype in nodetypes(graph)
        generate!(expr, compilednodetype, inputnames...)
    end
    push!(expr.args, :(on_update_stop!(graph.tracker)))
    push!(expr.args, nothing)
    expr
end

function generate!(
    expr::Expr,
    ::Type{CompiledNode{name,parentnames,Op}},
    inputnames::Symbol...,
) where {name,parentnames,Op}
    e = generate(inputnames, name, parentnames, Op)
    append!(expr.args, e.args)
    push!(expr.args, :(on_update_node!(graph.tracker, $(Meta.quot(name)))))
    expr
end

function debugsource(graph::CompiledGraph, sources::Source...)
    generate(graph, sources...)
end

getoperation(graph::CompiledGraph, name::TypeSymbol) = graph[name].operation
function getvalue(graph::CompiledGraph, name::TypeSymbol)
    node = graph[name]
    getvalue(graph, node, getoperation(node))
end
getvalue(::CompiledGraph, ::CompiledNode, op::Operation) = getvalue(op) # specific implementations should dispatch on this method
