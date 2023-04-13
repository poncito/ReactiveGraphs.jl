function quiet(node::Node; name::Union{Nothing,Symbol}=nothing)
    filter(node, constant(false); name)
end

