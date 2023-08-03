struct CompiledNode{name,parentnames,Op<:Operation}
    operation::Op
    function CompiledNode(
        name::Symbol,
        parentnames::NTuple{N,Symbol},
        operation::Operation,
    ) where {N}
        new{name,parentnames,typeof(operation)}(operation)
    end
end

getname(::TypeOrValue{CompiledNode{name}}) where {name} = name
getparentnames(::TypeOrValue{CompiledNode{name,parentnames}}) where {name,parentnames} =
    parentnames
getoperationtype(
    ::TypeOrValue{CompiledNode{name,parentnames,Op}},
) where {name,parentnames,Op} = Op
getoperation(n::CompiledNode) = n.operation

struct CompiledGraph{N,T<:NTuple{N,CompiledNode},Tr<:AbstractGraphTracker}
    nodes::T
    tracker::Tr
end

nodetypes(::TypeOrValue{CompiledGraph{N,T}}) where {N,T} = T.parameters
gettrackingnodes(g::CompiledGraph) = gettrackingnodes(g.tracker)

@generated function Base.getindex(g::CompiledGraph{N}, ::TypeSymbol{name}) where {N,name}
    for (i, node) in nodetypes(g) |> enumerate
        getname(node) == name && return :(g.nodes[$i])
    end
    throw(ErrorException("symbol $name not found in graph $g"))
end

"""
    Source{inputname,T}

An empty object that indexes an `Input` node within a `CompiledGraph`.
"""
struct Source{inputname,T} end

Base.eltype(::TypeOrValue{Source{inputname,T}}) where {inputname,T} = T
getinputname(::TypeOrValue{Source{inputname,T}}) where {inputname,T} = inputname

function Source(node::Node)
    @assert node.operation isa Input
    Source{node.name,eltype(node.operation)}()
end

"""
    compile(inputs::Node....; tracker::AbstractGraphTracker=NullGraphTracker)

This library does not optimize for the construction of the graph, but once
built, updating it should be as fast as possible, and allocation free.

In practice, the user first creates a computation graph iteratively, by creating nodes.
Then, in order to generate efficient methods to update such a graph, this library
requires the user to "compile" those nodes.
This simply amounts to build an object that whose type completely encodes the topology of the graph.
This way, it is possible to generate update methods based on the type of graph object, which
is quite idiomatic in Julia.

This conversion from a collection of node, to a strongly typed graph is done by this function.
It needs to be called on all the inputs of the graph.
The methods returns:
- a compiled graph object
- a `Source` for each of the inputs

```jldoctest
julia> i = input(String)
       map(println, i)
       g, s = compile(i)
       push!(g, s, "example")
example

julia> i = input(Ref(0))
       map(x->println(x[]), i)
       g, s = compile(i)
       push!(g, s, ref -> ref[] = 123)
123
```

It is also possible to update several inputs simultaneously

```jldoctest
julia> i1 = input(Int)
       i2 = input(Int)
       m = map(+, i1, i2)
       map(print, m)
       g, s1, s2 = compile(i1, i2)
       push!(g, s1 => 1, s2 => 2)
       push!(g, s1 => 3, s2 => 4)
37
```

"""
function compile(inputs::Node...; tracker::AbstractGraphTracker = NullGraphTracker())
    @assert !isempty(inputs)
    sources = Source.(inputs)

    @assert allequal(map(x -> x.graph.ref, inputs))
    nodes = inputs[1].graph.ref[]
    compilednodes = Tuple(
        CompiledNode(node.name, Tuple(node.parentnames), node.operation) for node in nodes
    )
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
        on_update_start!(graph.tracker)
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
    push!(
        expr.args,
        :(on_update_node!(graph.tracker, $(Meta.quot(name)), $(name in inputnames))),
    )
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
getvalue(::CompiledGraph, ::CompiledNode, op::Operation) = getvalue(op) # default implementaion. Concrete operations should dispatch on this method
