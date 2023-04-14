using DataFlows
using Test
using BenchmarkTools

import DataFlows: Graph, getoperationtype, Node

function collectgraph(g::Graph)
    c = []
    map((_,_,x)->push!(c, x), g)
    c
end

sink(arg::Node) = sink(identity, arg)
function sink(f::Function, args::Node...)
    T = Base._return_type(f, Tuple{(getoperationtype(a) for a in args)...})
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

    @testset "map - initialvalue" begin
        n1 = input(Int)
        n2 = map(+, n1; initialvalue=1)
        c = sink(n2)
        s = Source(n1)
        s[] = 2
        s[] = 3
        @test c == [3, 6]
    end

    @testset "map - state" begin
        n1 = input(Int)
        n2 = map((state, x)->(state+x, state-x), n1; state=1)
        c = sink(n2)
        s = Source(n1)
        s[] = 2
        s[] = 3
        s[] = 4
        @test c == [3, 2, 0]
    end

    @testset "map - state and initialvalue" begin
        n1 = input(Int)
        n2 = map((x, state, arg)->(state+x, arg), n1; initialvalue=1, state=2)
        c = sink(n2)
        s = Source(n1)
        # (x, state) == (1, 2)
        s[] = 3 # (x, state) == (3, 3) 
        s[] = 4 # (x, state) == (6, 4)
        s[] = 5 # (x, state) == (10, 5)
        @test c == [3, 6, 10]
    end

    @testset "map! - no state" begin
        n1 = input(Int)
        n2 = map!((x, arg)->(x[] += arg), n1; initialvalue=Ref(1))
        n3 = map(x->x[], n2)
        c = sink(n3)
        s = Source(n1)
        s[] = 2
        s[] = 3
        @test c == [3, 6]
    end

    @testset "map! - state" begin
        n1 = input(Int)
        n2 = map!(n1; initialvalue = Ref(1), state=Ref(1)) do x, state, arg
            state[] += arg
            x[] += state[] + arg 
        end
        n3 = map(x->x[], n2)
        c = sink(n3)
        s = Source(n1)
        s[] = 2
        s[] = 3
        @test c == [6, 15]
    end
end

@testset "filter" begin
    n1 = input(Int)
    n2 = input(Bool)
    n3 = filter(n1, n2)
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

@testset "selecter" begin
    n1 = input(Int)
    n2 = input(Bool)
    n3 = select(n1, n2)
    n4 = input(Int)
    n5 = map(+, n3, n4)
    c = sink(n5)
    s1 = Source(n1)
    s2 = Source(n2)
    s4 = Source(n4)
    s1[] = 1
    s2[] = false
    s4[] = 2
    s2[] = true
    s1[] = 3
    s4[] = 4
    s2[] = false
    s1[] = 5
    s4[] = 6
    @test c == [3, 5, 7]
end

@testset "constant" begin
    n1 = input(Int)
    n2 = constant(1)
    c = sink(+, n1, n2)
    s = Source(n1)
    s[] = 2
    @test c == [3]

    n1 = input(Bool)
    n2 = constant(true)
    c = sink(&, n1, n2)
    s = Source(n1)
    s[] = true
    s[] = false
    @test c == [true, false]
end

@testset "quiet" begin
    n1 = input(Int)
    n2 = input(Int)
    n3 = quiet(n2)
    c = sink(+, n1, n3)
    s1 = Source(n1)
    s2 = Source(n2)
    s1[] = 1
    s2[] = 2
    s1[] = 3
    s2[] = 4
    s1[] = 5
    @test c == [5, 9]
end
