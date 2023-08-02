using BenchmarkTools
using ReactiveGraphs
using Test

import ReactiveGraphs: getoperationtype, Node

macro testnoalloc(expr, kws...)
    esc(quote
        t = @benchmark $expr samples = 1 evals = 1
        @test(t.allocs == 0, $(kws...))
    end)
end

# function collectgraph(g::Graph)
#     c = []
#     map((_, _, x) -> push!(c, x), g)
#     c
# end

sink(arg::Node) = sink(identity, arg)
function sink(f::Function, args::Node...)
    m = inlinedmap(f, args...)
    T = eltype(m)
    v = Vector{T}()
    foldl(push!, v, m)
    v
end

# @testset "graph" begin
#     g1 = mergegraphs!()
#     @test g1 == merge!(g1)

#     push!(g1, :a, (), 1)
#     push!(g1, :b, (), 2)
#     @test collectgraph(g1) == [1, 2]

#     g2 = Graph()
#     push!(g2, :c, (), 3)
#     merge!(g1, g2)
#     @test g1 == g2

#     @test collectgraph(g1) == [1, 2, 3]
# end

@testset "input" begin
    @testset "1 input" begin
        n1 = input(Int)
        c = sink(x -> 2x, n1)
        g, s = compile(n1)
        push!(g, s => 2)
        @test c == [4]
    end

    @testset "2 inputs" begin
        n1 = input(Int)
        n2 = input(Int)
        c = sink(+, n1, n2)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1 => 1, s2 => 2)
        push!(g, s1 => 3, s2 => 4)
        @test c == [3, 7]
    end

    @testset "1 mutable input" begin
        n1 = input(Ref(0))
        c = sink(x -> 2x[], n1)
        g, s = compile(n1)
        push!(g, s, x -> x[] = 2)
        @test c == [4]
    end

    @testset "mutable and immutable inputs" begin
        n1 = input(Ref(0))
        n2 = input(Int)
        c = sink((x, y) -> 2x[] + y, n1, n2)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1 => x -> x[] = 2, s2 => 3)
        @test c == [7]
    end

    @testset "disjoint graphs" begin
        n1 = input(Int)
        n2 = input(Int)
        @test_throws AssertionError compile(n1, n2)
    end
end

@testset "map" begin
    @testset "map - 2 inputs" begin
        n1 = input(Int)
        n2 = input(Int)
        c = sink(+, n1, n2)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1, 1)
        push!(g, s2, 2)
        push!(g, s1, 3)
        @test c == [3, 5]
    end

    @testset "map - 2 inputs, 2 maps sequential" begin
        n1 = input(Int)
        n2 = input(Int)
        m = map((x, y) -> x + y, n1, n2)
        @test eltype(n1) == Int
        @test eltype(n2) == Int
        @test eltype(m) == Int
        c = sink(m)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1, 1)
        push!(g, s2, 2)
        push!(g, s1, 3)
        @test c == [3, 5]
    end

    @testset "map - 2 inputs, 2 maps parallel" begin
        n1 = input(Int)
        n2 = input(Int)
        c1 = sink(+, n1, n2)
        c2 = sink((x, y) -> -(x + y), n1, n2)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1, 1)
        push!(g, s2, 2)
        push!(g, s1, 3)
        @test c1 == [3, 5]
        @test c2 == [-3, -5]
    end
end

@testset "foldl" begin
    @testset "foldl immutable" begin
        n1 = input(Int)
        n2 = foldl(+, 1, n1)
        c = sink(n2)
        g, s = compile(n1)
        push!(g, s, 2)
        push!(g, s, 3)
        @test c == [3, 6]
    end

    @testset "fold mutable" begin
        n1 = input(Int)
        n2 = foldl(Ref(1), n1) do state, x
            state[] += x
            state
        end
        n3 = map(x -> x[], n2)
        c = sink(n3)
        g, s = compile(n1)
        push!(g, s, 2)
        push!(g, s, 3)
        @test c == [3, 6]
    end
end

@testset "inlinedmap" begin
    n1 = input(Int)
    n2 = input(Int)
    n3 = inlinedmap(+, n1, n2)
    c = sink(n3)
    g, s1, s2 = compile(n1, n2)
    push!(g, s1, 1)
    push!(g, s2, 2)
    @test c == [3]
end

@testset "filter" begin
    @testset "filter - node" begin
        n1 = input(Int)
        n2 = input(Bool)
        n3 = filter(n1, n2)
        c = sink(n3)
        g, s1, s2 = compile(n1, n2)
        push!(g, s1, 2)
        push!(g, s2, false)
        push!(g, s1, 3)
        push!(g, s2, true)
        push!(g, s1, 4)
        push!(g, s2, false)
        push!(g, s1, 5)
        @test c == [3, 4]
    end

    @testset "filter - function" begin
        n1 = input(Int)
        n2 = filter(iseven, n1)
        c = sink(n2)
        g, s1 = compile(n1)
        for i = 1:4
            push!(g, s1, i)
        end
        @test c == [2, 4]
    end

    @testset "filter non-boolean condition" begin
        n1 = input(Int)
        n2 = input(Int)
        @test_throws ErrorException filter(n1, n2)
        @test_throws ErrorException filter(identity, n1)
    end
end

@testset "selecter" begin
    @testset "selecter - node" begin
        n1 = input(Int)
        n2 = input(Bool)
        n3 = select(n1, n2)
        n4 = input(Int)
        n5 = map(+, n3, n4)
        c = sink(n5)
        g, s1, s2, s4 = compile(n1, n2, n4)
        push!(g, s1, 1)
        push!(g, s2, false)
        push!(g, s4, 2)
        push!(g, s2, true)
        push!(g, s1, 3)
        push!(g, s4, 4)
        push!(g, s2, false)
        push!(g, s1, 5)
        push!(g, s4, 6)
        @test c == [3, 5, 7]
    end

    @testset "selecter - function" begin
        n1 = input(Int)
        n2 = select(iseven, n1)
        c = sink(n2)
        g, s1 = compile(n1)
        for i = 1:7
            push!(g, s1, i)
        end
        @test c == [2, 4, 6]
    end

    @testset "selecter non-boolean condition" begin
        n1 = input(Int)
        n2 = input(Int)
        @test_throws ErrorException select(n1, n2)
        @test_throws ErrorException select(identity, n1)
    end
end

@testset "constant" begin
    n1 = input(Int)
    n2 = constant(1)
    c = sink(+, n1, n2)
    g, s = compile(n1)
    push!(g, s, 2)
    @test c == [3]

    n1 = input(Bool)
    n2 = constant(true)
    c = sink(&, n1, n2)
    g, s = compile(n1)
    push!(g, s, true)
    push!(g, s, false)
    @test c == [true, false]
end

@testset "quiet" begin
    n1 = input(Int)
    n2 = input(Int)
    n3 = quiet(n2)
    c = sink(+, n1, n3)
    g, s1, s2 = compile(n1, n2)
    push!(g, s1, 1)
    push!(g, s2, 2)
    push!(g, s1, 3)
    push!(g, s2, 4)
    push!(g, s1, 5)
    @test c == [5, 9]
end

@testset "lag" begin
    n1 = input(Int)
    n2 = lag(2, n1)
    c = sink(n2)
    g, s1 = compile(n1)
    for i = 1:10
        push!(g, s1, i)
    end
    @test c == 1:8
end

@testset "updated" begin
    n1 = input(Int)
    n2 = filter(iseven, n1)
    n3 = updated(n2)
    c1 = sink(identity, n3)
    c2 = sink((x, y) -> x, n3, n1)

    g, s = compile(n1)
    for i = 1:4
        push!(g, s, i)
    end
    @test c1 == [true, true]
    @test c2 == [false, true, false, true]
end

@testset "no allocation" begin
    i1 = input(Int)
    i2 = input(Bool)
    i3 = input(Bool)
    i1f = filter(i1, i2)
    i1s = select(i1, i3)
    n2 = map(x -> x + 1, i1f)
    n3 = foldl((state, x) -> state + x, 1, i1s)
    n4 = inlinedmap(+, n2, n3)
    n5 = lag(1, n4)
    n6 = updated(n5)

    g, s1, s2, s3 = compile(i1, i2, i3)
    push!(g, s1, 1)
    push!(g, s2, true)
    push!(g, s3, true)
    @testnoalloc push!($g, $s1, 1)
end

@testset "PerformanceTrackers" begin
    i1 = input(Int; name = "input1")
    i2 = input(Int; name = "input2")
    n1 = map(x -> 2x, i1)
    n2 = map(+, n1, i2)

    g, s1, s2 = compile(i1, i2)
    push!(g, s1, 1)
    push!(g, s2, 2)
    g, s1, s2 = compile(i1, i2; tracker=PerformanceGraphTracker())
    push!(g, s1, 2)
    push!(g, s2, 2)
    push!(g, s1 => 3, s2 => 3)
    nodes = gettrackingnodes(g)
    @test length(nodes) == 3 * 4
    @test map(x -> x.id, nodes) == [i for i = 1:3 for _ = 1:4]
    @test map(x -> x.bytes_allocated, nodes) == [0 for i = 1:3 for _ = 1:4]
    @test map(x -> x.isinput, nodes) == [(i in x) for x in [(1,), (3,), (1,3)] for i = 1:4]
end
