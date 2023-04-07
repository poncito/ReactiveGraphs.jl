using DataFlows
using Test
using BenchmarkTools

import DataFlows: Graph

function collectgraph(g::Graph)
    c = []
    map((_,_,x)->push!(c, x), g)
    c
end

sink(args...) = sink(identity, args...)
function sink(f::Function, args...)
    T = Base._return_type(f, Tuple{(eltype(a) for a in args)...})
    v = Vector{T}()
    map(x::Vararg->push!(v, f(x...)), args...)
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

@testset "map" begin
    @testset "map - 1 input" begin
        n1 = input(Int)
        c = sink(x->2x, n1)
        s = Source(n1)
        s[] = 2
        @test c == [4]
    end

    @testset "map - 2 inputs" begin
        n1 = input(Int)
        n2 = input(Int)
        c = sink(+, n1, n2)
        s1 = Source(n1)
        s2 = Source(n2)
        s1[] = 1
        s2[] = 2
        s1[] = 3
        @test c == [3, 5]
    end

    @testset "map - 2 inputs, 2 maps sequential" begin
        n1 = input(Int)
        n2 = input(Int)
        m = map((x,y)->x+y, n1, n2)
        c = sink(m)
        s1 = Source(n1)
        s2 = Source(n2)
        s1[] = 1 
        s2[] = 2
        s1[] = 3
        @test c == [3, 5]
    end

    @testset "map - 2 inputs, 2 maps parallel" begin
        n1 = input(Int)
        n2 = input(Int)
        c1 = sink(+, n1, n2)
        c2 = sink((x,y) -> -(x+y), n1, n2)
        s1 = Source(n1)
        s2 = Source(n2)
        s1[] = 1
        s2[] = 2
        s1[] = 3
        @test c1 == [3, 5]
        @test c2 == [-3, -5]
    end

    @testset "markov" begin
        n1 = input(Int)
        n2 = mapmarkov(+, 1, n1)
        c = sink(n2)
        s = Source(n1)
        s[] = 2
        s[] = 3
        @test c == [3, 6]
    end

    @testset "stateful" begin
        n1 = input(Int)
        n2 = mapstateful((state, x)->(state+x, state-x), 1, n1)
        c = sink(n2)
        s = Source(n1)
        s[] = 2
        s[] = 3
        s[] = 4
        @test c == [3, 2, 0]
    end

    @testset "markovstateful" begin
        n1 = input(Int)
        n2 = mapmarkovstateful((x, state, arg)->(state+x, arg), 1, 2, n1)
        c = sink(n2)
        s = Source(n1)
        # (x, state) == (1, 2)
        s[] = 3 # (x, state) == (3, 3) 
        s[] = 4 # (x, state) == (6, 4)
        s[] = 5 # (x, state) == (10, 5)
        @test c == [3, 6, 10]
    end
end

@testset "filter" begin
    n1 = input(Int)
    n2 = input(Bool)
    n3 = filter(n2, n1)
    c = sink(n3)
    s1 = Source(n1)
    s2 = Source(n2)
    s1[] = 2
    s2[] = false
    s1[] = 3
    s2[] = true 
    s1[] = 4
    s2[] = false
    s1[] = 5
    @test c == [3, 4]
end

@testset "constant" begin
    n1 = input(Int)
    n2 = constant(1)
    c = sink(+, n1, n2)
    s = Source(n1)
    s[] = 2
    @test c == [3]
end

