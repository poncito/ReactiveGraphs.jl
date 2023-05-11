using Revise
using DataFlows
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

s1 = Source(i1)
s2 = Source(i2)
s3 = Source(i3)
s1[] = 1
s2[] = true
s3[] = true
v = 1
@benchmark setindex!($s1, $v)

# DataFlows.debugsource(s1)
