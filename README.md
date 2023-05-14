[![CI](https://github.com/poncito/DataFlows.jl/workflows/CI/badge.svg)](https://github.com/poncito/DataFlows.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/poncito/DataFlows.jl/branch/main/graph/badge.svg?token=DZ7SSICAG6)](https://codecov.io/gh/poncito/DataFlows.jl)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://poncito.github.io/DataFlows.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://poncito.github.io/DataFlows.jl/dev)

# DataFlows.jl

This package provides a framework to run computations in a topological order of the dependency graph.
It aims to be fast and allocation free, for low-latency applications.

## TL;DR

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
      push!(s1 => true, s2 => true, s3 => 1)
      v = 1
      @benchmark push!($s1, $v)
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.                                      
Range (min … max):  8.708 ns … 27.625 ns  ┊ GC (min … max): 0.00% … 0.00%                      
Time  (median):     8.792 ns              ┊ GC (median):    0.00%                              
Time  (mean ± σ):   8.800 ns ±  0.252 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%                      

 ▂       ▆       █       ▄▃       ▂       ▂                 ▁                                  
 █▁▁▁▁▁▁▁█▁▁▁▁▁▁▁█▁▁▁▁▁▁▁██▁▁▁▁▁▁▁█▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▆▁▁▁▁▁▁▁▆ █                                  
 8.71 ns      Histogram: log(frequency) by time        9 ns <                                  

Memory estimate: 0 bytes, allocs estimate: 0.    
```
