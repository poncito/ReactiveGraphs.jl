abstract type AbstractMonitor end

using Base: nothing_sentinel
struct NullMonitor <: AbstractMonitor end

on_update_start!(::AbstractMonitor, inputnames) = nothing
on_update_node!(::AbstractMonitor, name) = nothing
on_update_stop!(::AbstractMonitor) = nothing

struct NodeStatistic
    name::Symbol
    id::Int64
    elapsed_time::Int64
    bytes_allocated::Int
end

struct RootStatistic
    name::Symbol
    id::Int64
end

mutable struct PerformanceMonitor <: AbstractMonitor
    @tryconst nodestatistics::Vector{NodeStatistic}
    @tryconst rootstatistics::Vector{RootStatistic}
    currentid::Int64
    lasttime::Int64
    @tryconst total_bytes_allocated::Base.RefValue{Int64}
end

PerformanceMonitor() = PerformanceMonitor(
    NodeStatistic[],
    RootStatistic[],
    zero(Int64),
    zero(Int64),
    Ref(zero(Int64)),
)

gettime(::PerformanceMonitor) = Dates.value(unix_now())
getelapsedtime(pm::PerformanceMonitor) = gettime(pm) - pm.lasttime
settime!(pm::PerformanceMonitor) = pm.lasttime = gettime(pm)

setallocatedbytes!(pm::PerformanceMonitor) = Base.gc_bytes(pm.total_bytes_allocated)
function getallocatedbytes!(pm::PerformanceMonitor)
    old_total_bytes_allocated = pm.total_bytes_allocated[]
    Base.gc_bytes(pm.total_bytes_allocated)
    pm.total_bytes_allocated[] - old_total_bytes_allocated
    0
end

function on_update_start!(pm::PerformanceMonitor, names)
    id = pm.currentid += 1
    for name in names
        rs = RootStatistic(name, id)
        push!(pm.rootstatistics, rs)
    end

    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end

function on_update_node!(pm::PerformanceMonitor, name)
    elapsed_time = getelapsedtime(pm)
    bytes_allocated = getallocatedbytes!(pm)

    rs = NodeStatistic(
        name,
        pm.currentid,
        elapsed_time,
        bytes_allocated,
    )
    push!(pm.nodestatistics, rs)

    setallocatedbytes!(pm)
    settime!(pm)
    nothing
end

