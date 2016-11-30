# translate pyfpgrowth


type FPNode
    value
    count::Int
    parent
    children::Array{FPNode,1}

    function FPNode(value, count, parent)
        kids = Array{FPNode,1}(0)
        return new(value, count, parent, kids)
    end
end


type FPTree
    frequent
    headers
    root

    function FPTree
        # tree = new()
    end
end


function has_child(pnode::FPNode, value)
    res = false
    for child in pnode.children
        if child.value == value
            res = true
            break
        end
    end
    res
end


function get_child(pnode::FPNode, value)
    for child in pnode.children
        if child.value == value
            res = child
        end
    end
    res
end


function add_child!(pnode::FPNode, value)
    child = FPNode(value, 1, pnode)
    push!(pnode.children, child)
end

# Create Dict of items with occurrences above threshold.
function find_frequent_items(transactions, threshold)
    items = Dict{String,Int}()

    for transaction in transactions
        for itm in transaction
            items[itm] = get(items, itm, 0) + 1
        end
    end

    for k in keys(items)
        if items[k] < threshold
            delete!(items, k)
        end
    end
    items
end


function build_header_table(frequent)
    headers = Dict()
    for k in keys(frequent)
        headers[k] = nothing
    end
    headers
end


function build_fptree(FPTree, transactions, rootvalue, rootcount, frequent, headers)
