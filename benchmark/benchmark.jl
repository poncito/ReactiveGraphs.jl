using ReactiveGraphs
using BenchmarkTools

i1 = input(Int)
i2 = input(Bool)
i3 = input(Bool)
i1f = filter(i1, i2)
i1s = select(i1, i3)
n2 = map(x -> x + 1, i1f)
n3 = foldl((state, x) -> state + x, 1, i1s)
n4 = inlinedmap(+, n2, n3)
n5 = lag(1, n4)

g, s1, s2, s3 = compile(i1, i2, i3)
push!(g, s1, 1)
push!(g, s2, true)
push!(g, s3, true)

@benchmark push!($g, $s1, 1)
