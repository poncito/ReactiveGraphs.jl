abstract type Operation{T} end

Base.eltype(::TypeOrValue{Operation{T}}) where {T} = T


