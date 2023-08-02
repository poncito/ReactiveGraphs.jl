module ReactiveGraphs

export input
export Source
export constant
export inlinedmap
export quiet
export select
export lag
export updated

export PerformanceGraphTracker
export gettrackingnodes, gettrackingtriggers
export compile

macro tryinline(e)
    @static if VERSION >= v"1.8"
        :(@inline $(esc(e)))
    else
        esc(e)
    end
end

macro tryconst(e)
    @static if VERSION >= v"1.8"
        Expr(:const, esc(e))
    else
        esc(e)
    end
end

@static if VERSION < v"1.8"
    allequal(itr) = isempty(itr) ? true : all(isequal(first(itr)), itr)
end

TypeOrValue{X} = Union{X,Type{<:X}}

struct TypeSymbol{x}
    TypeSymbol(x::Symbol) = new{x}()
end

getsymbol(::TypeOrValue{TypeSymbol{x}}) where {x} = x

include("operations.jl")
include("graph.jl")
include("trackers.jl")
include("compilation.jl")

genname(::Nothing) = gensym()
genname(s::Symbol) = gensym(s)
genname(s::AbstractString) = gensym(string(s))

include("input.jl")
include("map.jl")
include("foldl.jl")
include("inlinedmap.jl")
include("filter.jl")
include("selecter.jl")
include("constant.jl")
include("quiet.jl")
include("lag.jl")
include("updated.jl")

_splittuple(T::Type{<:Any}) = T, Nothing
_splittuple(::Type{Tuple{T1,T2}}) where {T1,T2} = T1, T2

end # module
