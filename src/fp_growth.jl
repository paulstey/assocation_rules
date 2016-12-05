# translate pyfpgrowth


type FPNode
    value::String
    count::Int
    parent::FPNode
    children::Array{FPNode,1}
    link

    function FPNode(value, count, parent)
        kids = Array{FPNode,1}(0)
        return new(value, count, parent, kids)
    end

    function FPNode()
        # this method is for root node initialization
        x = new("", 100_000_000_000)                # FIXME: don't use arbitrarily large count
        x.children = Array{FPNode,1}(0)
        x.parent = x
        x
    end
end


type FPTree
    frequent
    headers
    root


    function FPTree(transactions, threshold)
        frequent = find_frequent_items(transactions, threshold)
        headers = build_header_table(frequent)

        root = build_fptree(transactions,
                            root_value,
                            root_count,
                            frequent,
                            headers)

        res = new(frequent, headers, root)
        return res
    end

    function FPTree(transactions, threshold, )
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

# NOTE: This function needs re-thinking since
# it can return either a child node or `nothing`
function get_child(pnode::FPNode, value)
    res = nothing
    for child in pnode.children
        if child.value == value
            res = child
        end
    end
    res
end

# This function might render the above get_child!()
# unnecessary since.
function increment_child!(pnode::FPNode, value)
    for child in pnode.children
        if child.value == value
            pnode.count += 1
            break
        end
    end
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


function build_fptree(tree::FPTree, transactions, rootvalue, rootcount, frequent, headers)
    root = FPNode()

    for transaction in transactions
        for x in transaction
            if x ∈ keys(frequent)
                push!(sorted_items, x)
            end
        end
        sort!(sorted_items, by = x -> frequent[x], rev = true)

        if length(sorted_items) > 0
            insert_tree!(tree, sorted_items, root, headers)
        end
    end
    root
end

function insert_tree!(tree::FPTree, items, node, headers)
    # recursively grow FP tree
    first = items[1]

    if has_child(node, first)
        increment_child!(node, first)           # increment existing child counter
    else
        add_child!(node, first)                 # add new child
        child = last(node.children)             # child we just inserted

        # Now we link newly created node to
        # the header structure.
        if !haskey(headers, first)
            headers[first] = child
        else
            current = headers[first]
            while isdefined(current, :link)
                current = current.link
            end
            current.link = child
        end
    end

    # call function recursively
    remaining_items = items[2:end]
    if length(remaining_items) > 0
        insert_tree!(tree, remaining_items, child, headers)
    end
end

# This function returns a boolean indiecating whether or
# not this tree has a single path.
function tree_has_single_path(tree::FPTree, node)
    num_children = length(node.children)
    if num_children > 1
        return false
    elseif num_children == 0
        return true
    else
        return true && tree_has_single_path(tree, node.children[1])
    end
end


# Mine the constructed FP tree for patterns
function mine_patterns(tree, threshold)
    if tree_has_single_path(tree, tree.root)
        return generate_pattern_list(tree)
    else
        return zip_patterns(tree, mine_sub_trees(tree, threshold))
    end
end


# Append suffix to patterns in dictionary if
# we are in a conditional FP tree
function zip_patterns(tree, patterns)
    if isdefined(tree.root, :value)
        new_patterns = Dict{Array{String,1},Int}()

        for k in keys(patterns)
            xpattern = vcat(k, suffix)
            sort!(xpattern)
            new_patterns[xpattern] = patterns[k]
        end
    end
    return patterns
end


# Generate a list of patterns with support counts
function generate_pattern_list(tree)
    patterns = Dict{Array{String,1},Int}()

    items = collect(keys(tree.frequent))

    # If we are in a conditional tree,
    # the suffix is a pattern on its own.
    if !isdefined(tree.root, :value)
        suffix_value = Array{String,1}(0)
    else
        suffix_value = [tree.root.value]
        patterns[suffix_value] = self.root.count
    end

    for i in 1:length(items)
        for subset in collect(combination(items, 1))
            pattern = sort(vcat(subset, suffix_value))
            patterns[pattern] = min([tree.frequent[x] for x in subset])
        end
    end
    return patterns
end


function mine_sub_trees(tree, threshold)
    patterns = Dict{Array{String,1},Int}()
    xkeys = collect(keys(tree.frequent))
    mining_order = sort(xkeys, by = x -> tree.frequent[x])

    # Get items in tree in reverse order of occurrences.
    for item in mining_order
        suffixes = Array{String,1}(0)
        conditional_tree_input = []             # note replace this with type-specific array
        node = tree.headers[item]

        # follow node links to get a list of
        # all occurences of a certain item
        for suffix in suffixes
            frequency = suffix.count
            path = []
            parent = suffix.parent

            while isdefined(parent, :parent)
                push!(path, parent.value)
                parent = parent.parent
            end

            for i = 1:frequency
                push!(conditional_tree_input, path)
            end
        end

        # Now we have the input for a subtree,
        # so construct it and grab the patterns.
        subtree = FPTree(conditional_tree_input, threshold, item, tree.frequent[item])
        subtree_patterns = mine_patterns(subtree, threshold)

        # Insert subtree patterns into main patterns dictionary.
        for pattern in keys(subtree_patterns)
            if pattern ∈ keys(patterns)
                push!(patterns[pattern], subtree_patterns[pattern])     # NOTE: modifying in place
            else
                patterns[pattern] = subtree_patterns[pattern]
            end
        end

    end
    return patterns
end


# Given a set of transactions, find the patterns in it
# over the specified support threshold.
function find_frequent_patterns(transactions, support_threshold)
    tree = FPTree(transactions, support_threshold)
