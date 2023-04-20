# Dataflows.jl Documentation

```@contents
Depth=3
```

## Getting Started

This library provides the following fundamental methods to build a graph
(input, map, inlinemap and foldl),
to control its flow (filter, select).

It also provides some convenient methods:
- quiet
- constant

To build a graph, one needs to start with some inputs, which are roots of the graph.
```julia
input_1 = input(Int64)
input_2 = input(Int64)
```

Then, derived nodes can be build with `map`
```julia
node_1 = map(input_1) do x
    println("node 1: $(2x)")
    2x 
end
node_2 = map(node_1, input_1, input_2) do x, y, z
    println("node 2: $(x + y + z)")
    x + y + z
end
```

!!! note
    To ensure type stability, and performance,
    the types of the nodes are resolved at this stage.
    Hence the methods used in map must already be defined at this stage.
    We can verify that node_sum contains an `Int`.
    ```julia
    julia> eltype(node_sum)
    Int64
    ```

To use this graph, we need to push values into the two inputs.
```julia
s1 = Source(input_1) # compiles the graph. Nodes must not be added afterwards.
s2 = Source(input_2) # compiles the graph. Nodes must not be added afterwards.
s1[] = 1 # prints "node 1: 2". The second node cannot be evaluated since the data is missing
s2[] = 2 # prints "node 2: 5"
s1[] = 3 # prints "node 1: 6" "node 2: 11".
```
Each time an input is updated, the data will flow down the graph, 
updating all children nodes.
!!! note
    We can notice how updating the first input only updates `node_2` once.
    This differs with simple _reactive programming_ implementations,
    where the graph is generally traversed in a depth-first manner,
    with repetitions (typycally if the graph is not a tree).
    Here the graph is traversed in the topologic order of the construction.

## Controlling the flow of the graph

This package provides a way to avoid direct (`filter`) and indirect (`select`)
triggering of children.

### Filtering
Consider the following case:
```julia
input_1 = input(Float64)
n = map(x->println("new update: $x"), input_1)
```
To avoid triggering node `n` when the value of `input_1` is `NaN`,
one can use `filter`.
```julia
input_1 = input(Float64)
filtered = filter(x->!isnan(x), input_1)
n = map(x->println("new update: $x"), filtered)

s1 = Source(input_1) # compiles the graph. Nodes must not be added afterwards.
s1[] = 1.0 # prints "new update: 1.0"
s1[] = NaN # prints nothing 
```

### Selecting
Consider now the following case:
```julia
input_1 = input(Float64)
input_2 = input(Float64)
filtered = filter(x->!isnan(x), input_1)
n = map(filtered, input_2) do x, y
    println("new update: $(x+y)")
    x + y
end
```
Even if `input_1` if filtered, when `input_2` is triggered, the value of `filtered` will be
used, whether the filtering condition is activated or not.
To prevent the computation of `n`, users should use `select` instead:
```julia
input_1 = input(Float64)
input_2 = input(Nothing)
filtered = select(x->!isnan(x), input_1)
selected = select(x->!isnan(x), input_1)
map((x,y) -> println("filtered"), filtered, input_2)
map((x,y) -> println("selected"), selected, input_2)
    
s1 = Source(input_1) # compiles the graph. Nodes must not be added afterwards.
s2 = Source(input_2) # compiles the graph. Nodes must not be added afterwards.
s1[] = 1.0 # prints nothing 
s2[] = nothing # prints "filtered" and then "selected"
s1[] = NaN # prints nothing 
s2[] = nothing # prints "filtered" only
```

## More functionnalities
The user should also read the documentation of
- foldl (to update a state)
- inlinedmap (to avoid copying a state)
- quiet (to prevent direct propagation)
- constant
- lag (to build nodes that contain previous values)

## API
```@docs
input
Source
Base.map(::Function,::DataFlows.Node,::Vararg{DataFlows.Node})
```

## Comparison with Observables.jl
Observables provides a nice API 

## Benchmark 
```julia
julia>i1 = input(Int)
      i2 = input(Bool)
      i3 = input(Bool)
      i1f = filter(i1, i2)
      i1s = select(i1, i3)
      n2 = map(x->x+1, i1f)
      n3 = foldl((state, x)-> state + x, 1, i1s)
      n4 = inlinedmap(+,n2,n3)
      n5 = lag(1, n4)
      
      s1 = Source(i1)
      s2 = Source(i2)
      s3 = Source(i3)
      s1[] = 1
      s2[] = true
      s3[] = true
      v = 1
      @benchmark setindex!($s1, $v)
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  5.240 ns … 128.238 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     5.400 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   5.774 ns ±   1.958 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▅█▇▂    ▁          ▁       ▁                                ▁
  ████▄▄▄▇█▄▅▅▅▄▃▅▆▇▇█▇▆▆▄▅▅▅█▇▆▆▅▅▅▆▆▆▆▆▇▆▆▇▆▇▇▆▆▇█▇▆▆▆▆▆▆▆▆ █
  5.24 ns      Histogram: log(frequency) by time      10.1 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

