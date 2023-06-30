abstract type AbstractGraphTracker end

using Base: nothing_sentinel
struct NullGraphTracker <: AbstractGraphTracker end

on_update_start!(::AbstractGraphTracker, inputnames) = nothing
on_update_node!(::AbstractGraphTracker, name) = nothing
on_update_stop!(::AbstractGraphTracker) = nothing

struct TrackingNode
    name::Symbol
    id::Int64
    elapsed_time::Int64
    bytes_allocated::Int
end

struct TrackingTriggers
    name::Symbol
    id::Int64
end

mutable struct PerformanceGraphTracker <: AbstractGraphTracker
    @tryconst trackingnodes::Vector{TrackingNode}
    @tryconst trackingtriggers::Vector{TrackingTriggers}
    currentid::Int64
    lasttime::UInt64
    @tryconst total_bytes_allocated::Base.RefValue{Int64}
end

PerformanceGraphTracker() = PerformanceGraphTracker(
    TrackingNode[],
    TrackingTriggers[],
    zero(Int64),
    zero(UInt64),
    Ref(zero(Int64)),
)

gettrackingnodes(pm::PerformanceGraphTracker) = pm.trackingnodes
gettrackingtriggers(pm::PerformanceGraphTracker) = pm.trackingtriggers

gettime(::PerformanceGraphTracker) = time_ns()
getelapsedtime(pm::PerformanceGraphTracker) = reinterpret(Int64, gettime(pm) - pm.lasttime)
settime!(pm::PerformanceGraphTracker) = pm.lasttime = gettime(pm)

setallocatedbytes!(pm::PerformanceGraphTracker) = Base.gc_bytes(pm.total_bytes_allocated)
function getallocatedbytes!(pm::PerformanceGraphTracker)
    old_total_bytes_allocated = pm.total_bytes_allocated[]
    Base.gc_bytes(pm.total_bytes_allocated)
    pm.total_bytes_allocated[] - old_total_bytes_allocated
end

function on_update_start!(pm::PerformanceGraphTracker, names)
    id = pm.currentid += 1
    for name in names
        rs = TrackingTriggers(name, id)
        push!(pm.trackingtriggers, rs)
    end

    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end

function on_update_node!(pm::PerformanceGraphTracker, name)
    elapsed_time = getelapsedtime(pm)
    bytes_allocated = getallocatedbytes!(pm)

    rs = TrackingNode(
        name,
        pm.currentid,
        elapsed_time,
        bytes_allocated,
    )
    push!(pm.trackingnodes, rs)

    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end

