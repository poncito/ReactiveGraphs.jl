using Revise
using DataFlows
using BenchmarkTools

n1 = input(Float64)
n2 = input(Float64)
n3 = map((x, y) -> x + y, n1, n2)
s1 = Source(n1)
s2 = Source(n2)
a1 = 1.0
a2 = 2.0
s1[] = a1

function ftest(a1, a2)
    if isnan(a1) | isnan(a2)
        NaN
    else
        a1 + a2
    end
end

# @info DataFlows.generate!(quote end, typeof(n1.graph[]), DataFlows.getname(n1))
@benchmark setindex!($s2, $a2)
@benchmark ftest($a1, $a2)
