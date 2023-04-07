abstract type Operation{T} end

Base.eltype(::TypeOrValue{Operation{T}}) where {T} = T

mutable struct Input{T} <: Operation{T}
    isinitialized::Bool
    x::T
    Input{T}() where {T} = new{T}(false)
    Input(x::T) where {T} = new{T}(true, x)
end

getvalue(x::Input) = x.x
isinitialized(i::Input) = i.isinitialized

function update!(i::Input, x)
    i.isinitialized = true
    i.x = x
end

mutable struct Map{T,TState,F} <: Operation{T}
    f::F
    state::TState
    x::T
    Map{T}(f::F, state::TState) where {T, TState, F} = new{T,TState,F}(f, state)
    Map(f::F, state::TState, x::T) where {T, TState, F} = new{T,TState,F}(f, state, x)
end
getvalue(x::Map) = x.x
getstate(x::Map) = x.state

# marginals of the generic map
struct Stateless{F<:Function}
    f::F
end
MapStateless{T,TState} = Map{T,TState,<:Stateless}

struct Markov{F<:Function}
    f::F
end
MapMarkov{T,TState} = Map{T,TState,<:Markov}

struct Stateful{F<:Function}
    f::F
end
MapStateful{T,TState} = Map{T,TState,<:Stateful}

struct MarkovStateful{F<:Function}
    f::F
end
MapMarkovStateful{T,TState} = Map{T,TState,<:MarkovStateful}

struct Markov!{F<:Function}
    f::F
end
MapMarkov!{T,TState} = Map{T,TState,<:Markov!}

struct MarkovStateful!{F<:Function}
    f::F
end
MapMarkovStateful!{T,TState} = Map{T,TState,<:MarkovStateful!}

function update!(m::MapMarkovStateful, args...)
    m.x, m.state = m.f.f(m.x, m.state, args...)
end

function update!(m::MapStateless, args...)
    m.x = m.f.f(args...)
end

function update!(m::MapMarkov, args...)
    m.x = m.f.f(m.x, args...)
end

function update!(m::MapStateful, args...)
    m.x, m.state = m.f.f(m.state, args...)
end

update!(m::MapMarkov!, args...) = m.f.f(m.x, args...)
update!(m::MapMarkovStateful!, args...) = m.f.f(m.state, args...)

struct Filter{T} <: Operation{T} end

struct Constant{T} <: Operation{T}
    x::T
end
getvalue(c::Constant) = c.x
