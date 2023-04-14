# DataFlows 

Computational graph, optimized for low latency.

## When is it useful?
> A dataflow program is a graph, where nodes represent operations and edges represent data paths. 

Dataflows architectures are particularly relevant for building programs that process multiple data
sources asynchronously.

## What is this 

This module provides the components required to build a computational graph architecture.
The emphasize is on latency.
To achieve high performance, the graph is compiled to avoid dynamic dispatching of the operations.

## Example

### mapping

This example shows how to create a graph that contains two inputs, and a node that sums their value.
```julia
input_1 = input(Int)
input_2 = input(Int)
node_sum = map(+, input_1, input_2)
node_print = map(println, node_sum)
```
To ensure type stability, the type of the nodes is resolved at this stage:
```julia
julia> eltype(node_sum)
Int64
```

To use this graph, we need to push values into the two inputs.
```julia
s1 = Source(input_1) # compiles the graph. Nodes must not be added afterwards.
s2 = Source(input_2) # compiles the graph. Nodes must not be added afterwards.
s1[] = 1 # cannot print since s2 is not initialized
s2[] = 2 # prints 3
s3[] = 3 # prints 5
```
Each time an input is updated, the data will flow down the graph, 
updating all children nodes.

### filtering

One can stop the flow of data using `Base.filter`.
```julia
input_1 = input(Int)
input_2 = input(Bool)
node_filtered = filter(input_1, input_2)
```
The node `node_filtered` contains the value of `input_1`,
but will only trigger when `input_2` is `true`.

### Selecting
In the previous filtering example, the node `node_filtered` always contains the value of `input_1`,
and can be used to compute another node.
To disable any node that would consume it, one can use `select`.
```julia
input_1 = input(Int)
input_2 = input(Bool)
input_3 = input(Int)
node_selected = select(input_1, input_2)
node_filtered = filter(input_1, input_2)
map((x, y) -> println("node_selected"), node_selected, input_3)
map((x, y) -> println("node_filtered"), node_filtered, input_3)
s1 = Source(input_1) # compiles the graph. Nodes must not be added afterwards.
s2 = Source(input_2) # compiles the graph. Nodes must not be added afterwards.
s3 = Source(input_3) # compiles the graph. Nodes must not be added afterwards.
s1[] = 1
s2[] = true
s3[] = 2 # prints "node_selected" and "node_filtered"
s2[] = false
s3[] = 3 # prints "node_filtered" only
```

### Constants

To create a node that contains a constant, and never propagates, use `constant`.
The boolean constants are propagated by Julia's compiler.

