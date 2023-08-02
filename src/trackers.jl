abstract type AbstractGraphTracker end

struct NullGraphTracker <: AbstractGraphTracker end

on_update_start!(::AbstractGraphTracker) = nothing
on_update_node!(::AbstractGraphTracker, name, isinput) = nothing
on_update_stop!(::AbstractGraphTracker) = nothing

struct TrackingNode
    name::Symbol
    id::Int64
    elapsed_time::Int64
    bytes_allocated::Int
    isinput::Bool
end

mutable struct PerformanceGraphTracker <: AbstractGraphTracker
    @tryconst trackingnodes::Vector{TrackingNode}
    currentid::Int64
    lasttime::UInt64
    @tryconst total_bytes_allocated::Base.RefValue{Int64}
end

PerformanceGraphTracker() = PerformanceGraphTracker(
    TrackingNode[],
    zero(Int64),
    zero(UInt64),
    Ref(zero(Int64)),
)

gettrackingnodes(pm::PerformanceGraphTracker) = pm.trackingnodes

gettime(::PerformanceGraphTracker) = time_ns()
getelapsedtime(pm::PerformanceGraphTracker) = reinterpret(Int64, gettime(pm) - pm.lasttime)
settime!(pm::PerformanceGraphTracker) = pm.lasttime = gettime(pm)

setallocatedbytes!(pm::PerformanceGraphTracker) = Base.gc_bytes(pm.total_bytes_allocated)
function getallocatedbytes!(pm::PerformanceGraphTracker)
    old_total_bytes_allocated = pm.total_bytes_allocated[]
    Base.gc_bytes(pm.total_bytes_allocated)
    pm.total_bytes_allocated[] - old_total_bytes_allocated
end

function on_update_start!(pm::PerformanceGraphTracker)
    pm.currentid += 1
    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end

function on_update_node!(pm::PerformanceGraphTracker, name, isinput::Bool)
    elapsed_time = getelapsedtime(pm)
    bytes_allocated = getallocatedbytes!(pm)

    rs = TrackingNode(name, pm.currentid, elapsed_time, bytes_allocated, isinput)
    push!(pm.trackingnodes, rs)

    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end
