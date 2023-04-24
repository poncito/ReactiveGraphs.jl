"""
    quiet(node::Node; name)

Creates a node that contains the same value as `node`,
but does not trigger its children.

If `name` is provided, it will be appended to the
generated symbol that identifies the node.
"""
function quiet(node::Node; name = nothing)
    filter(node, constant(false; name); name)
end
