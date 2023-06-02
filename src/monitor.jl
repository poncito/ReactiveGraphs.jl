abstract type AbstractMonitor end

struct NullMonitor <: AbstractMonitor end

on_update_start!(::AbstractMonitor, inputnames) = nothing
on_update_node!(::AbstractMonitor, name) = nothing
on_update_stop!(::AbstractMonitor) = nothing

