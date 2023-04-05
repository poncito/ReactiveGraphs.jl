using DataFlows
using Test
using BenchmarkTools

import DataFlows: Graph

function collectgraph(g::Graph)
    c = []
    map((_,_,x)->push!(c, x), g)
    c
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

@testset "map - 1 input" begin
    c = []
    n1 = input(Int)
    map(x->push!(c, 2x), n1)
    s = Source(n1)
    s[] = 2
    @test c == [4]
end

@testset "map - 2 inputs" begin
    c = []
    n1 = input(Int)
    n2 = input(Int)
    map((x,y)->push!(c, x+y), n1, n2)
    s1 = Source(n1)
    s2 = Source(n2)
    s1[] = 1
    s2[] = 2
    s1[] = 3
    @test c == [3, 5]
end

@testset "map - 2 inputs, 2 maps sequential" begin
    c = []
    n1 = input(Int)
    n2 = input(Int)
    m = map((x,y)->x+y, n1, n2)
    map(z->push!(c, z), m)
    s1 = Source(n1)
    s2 = Source(n2)
    s1[] = 1 
    s2[] = 2
    s1[] = 3
    @test c == [3, 5]
end

@testset "map - 2 inputs, 2 maps parallel" begin
    # This test rely on the priority order set at the construction of the graph.
    # TODO: we may want to be able to set the priority independently from the construction order.
    c = []
    n1 = input(Int)
    n2 = input(Int)
    map((x,y)->push!(c, x+y), n1, n2)
    map((x,y)->push!(c, -(x+y)), n1, n2)
    s1 = Source(n1)
    s2 = Source(n2)
    s1[] = 1
    s2[] = 2
    s1[] = 3
    @test c == [3, -3, 5, -5]
end

@testset "filter" begin
    c = []
    n1 = input(Int)
    n2 = input(Bool)
    n3 = filter(n2, n1)
    n4 = map(x -> push!(c,x), n3)
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

