module DataFlows

export input
export Source
export constant
export inlinedmap
export quiet
export select
export lag

TypeOrValue{X} = Union{X,Type{X}}

include("graph.jl")
include("operations.jl")
include("compilation.jl")

genname(::Nothing) = gensym()
genname(s::Symbol) = gensym(s)
getoperationtype(node::Node) = getnode(node) |> getelement |> eltype

include("input.jl")
include("map.jl")
include("inlinedmap.jl")
include("filter.jl")
include("selecter.jl")
include("constant.jl")
include("quiet.jl")
include("lag.jl")

_splittuple(T::Type{<:Any}) = T, Nothing
_splittuple(::Type{Tuple{T1,T2}}) where {T1,T2} = T1, T2

end # module
