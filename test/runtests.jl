using DataFlows
using Test
using BenchmarkTools

import DataFlows: Graph, getoperationtype, Node

function collectgraph(g::Graph)
    c = []
    map((_, _, x) -> push!(c, x), g)
    c
end

sink(arg::Node) = sink(identity, arg)
function sink(f::Function, args::Node...)
    T = Base._return_type(f, Tuple{(getoperationtype(a) for a in args)...})
    v = Vector{T}()
    map(args...) do x::Vararg
        push!(v, f(x...))
        nothing
    end
    v
end

@testset "graph" begin
    g1 = Graph()
    @test g1 == merge!(g1)

    push!(g1, :a, (), 1)
    push!(g1, :b, (), 2)
    @test collectgraph(g1) == [1, 2]

    g2 = Graph()
    push!(g2, :c, (), 3)
    merge!(g1, g2)
    @test g1 == g2

    @test collectgraph(g1) == [1, 2, 3]
end

@testset "input" begin
    @testset "1 input" begin
        n1 = input(Int)
        c = sink(x -> 2x, n1)
        s = Source(n1)
        push!(s, 2)
        @test c == [4]
    end

    @testset "2 inputs" begin
        n1 = input(Int)
        n2 = input(Int)
        c = sink(+, n1, n2)
        s = Source(n1, n2)
        push!(s, 1, 2)
        push!(s, 3, 2)
        @test c == [3, 5]
    end

    @testset "1 mutable input" begin
        n1 = input(Ref(0))
        c = sink(x -> 2x[], n1)
        s = Source(n1)
        push!(s, x -> x[] = 2)
        @test c == [4]
    end
end

@testset "map" begin
    @testset "map - 2 inputs" begin
        n1 = input(Int)
        n2 = input(Int)
        c = sink(+, n1, n2)
        s1 = Source(n1)
        s2 = Source(n2)
        push!(s1, 1)
        push!(s2, 2)
        push!(s1, 3)
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
        s1 = Source(n1)
        s2 = Source(n2)
        push!(s1, 1)
        push!(s2, 2)
        push!(s1, 3)
        @test c == [3, 5]
    end

    @testset "map - 2 inputs, 2 maps parallel" begin
        n1 = input(Int)
        n2 = input(Int)
        c1 = sink(+, n1, n2)
        c2 = sink((x, y) -> -(x + y), n1, n2)
        s1 = Source(n1)
        s2 = Source(n2)
        push!(s1, 1)
        push!(s2, 2)
        push!(s1, 3)
        @test c1 == [3, 5]
        @test c2 == [-3, -5]
    end
end

@testset "foldl" begin
    @testset "foldl immutable" begin
        n1 = input(Int)
        n2 = foldl(+, 1, n1)
        c = sink(n2)
        s = Source(n1)
        push!(s, 2)
        push!(s, 3)
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
        s = Source(n1)
        push!(s, 2)
        push!(s, 3)
        @test c == [3, 6]
    end
end

@testset "inlinedmap" begin
    n1 = input(Int)
    n2 = input(Int)
    n3 = inlinedmap(+, n1, n2)
    c = sink(n3)
    s1 = Source(n1)
    s2 = Source(n2)
    push!(s1, 1)
    push!(s2, 2)
    @test c == [3]
end

@testset "filter" begin
    @testset "filter - node" begin
        n1 = input(Int)
        n2 = input(Bool)
        n3 = filter(n1, n2)
        c = sink(n3)
        s1 = Source(n1)
        s2 = Source(n2)
        push!(s1, 2)
        push!(s2, false)
        push!(s1, 3)
        push!(s2, true)
        push!(s1, 4)
        push!(s2, false)
        push!(s1, 5)
        @test c == [3, 4]
    end

    @testset "filter - function" begin
        n1 = input(Int)
        n2 = filter(iseven, n1)
        c = sink(n2)
        s1 = Source(n1)
        for i = 1:4
            push!(s1, i)
        end
        @test c == [2, 4]
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
        s1 = Source(n1)
        s2 = Source(n2)
        s4 = Source(n4)
        push!(s1, 1)
        push!(s2, false)
        push!(s4, 2)
        push!(s2, true)
        push!(s1, 3)
        push!(s4, 4)
        push!(s2, false)
        push!(s1, 5)
        push!(s4, 6)
        @test c == [3, 5, 7]
    end

    @testset "selecter - function" begin
        n1 = input(Int)
        n2 = select(iseven, n1)
        c = sink(n2)
        s1 = Source(n1)
        for i = 1:7
            push!(s1, i)
        end
        @test c == [2, 4, 6]
    end
end

@testset "constant" begin
    n1 = input(Int)
    n2 = constant(1)
    c = sink(+, n1, n2)
    s = Source(n1)
    push!(s, 2)
    @test c == [3]

    n1 = input(Bool)
    n2 = constant(true)
    c = sink(&, n1, n2)
    s = Source(n1)
    push!(s, true)
    push!(s, false)
    @test c == [true, false]
end

@testset "quiet" begin
    n1 = input(Int)
    n2 = input(Int)
    n3 = quiet(n2)
    c = sink(+, n1, n3)
    s1 = Source(n1)
    s2 = Source(n2)
    push!(s1, 1)
    push!(s2, 2)
    push!(s1, 3)
    push!(s2, 4)
    push!(s1, 5)
    @test c == [5, 9]
end

@testset "lag" begin
    n1 = input(Int)
    n2 = lag(2, n1)
    c = sink(n2)
    s1 = Source(n1)
    for i = 1:10
        push!(s1, i)
    end
    @test c == 1:8
end
