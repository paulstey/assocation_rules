
type Node
    id::Int16
    item_ids::Array{Int16,1}
    transactions::BitArray{1}
    children::Array{Node,1}
    mother::Node

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1})
        nd = new()
        nd.id = id
        nd.item_ids = item_ids
        nd.transactions = transactions
        nd.children = Array{Node,1}(0)
        return nd 
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1}, mother::Node)
        nd = new()
        nd.id = id
        nd.item_ids = item_ids
        nd.transactions = transactions
        nd.children = Array{Node,1}(0)
        nd.mother = mother
        return nd 
    end
end


n1 = Node(Int16(1), Int16[1], trues(3))
n2 = Node(Int16(1), Int16[1, 2], trues(3), n1)
n3 = Node(Int16(1), Int16[1, 3], trues(3), n1)
n4 = Node(Int16(1), Int16[1, 4], trues(3), n1)
n5 = Node(Int16(1), Int16[1, 5], trues(3), n1)
n6 = Node(Int16(1), Int16[1, 6], trues(3), n1)
n7 = Node(Int16(1), Int16[2, 3], trues(3), n1)
n8 = Node(Int16(1), Int16[2, 4], trues(3), n1)
n9 = Node(Int16(1), Int16[2, 5], trues(3), n1)
n10 = Node(Int16(1), Int16[2, 6], trues(3), n1)

push!(n1.children, n2)
push!(n1.children, n3)
push!(n1.children, n4)
push!(n1.children, n5)
push!(n1.children, n6)
push!(n1.children, n7)
push!(n1.children, n8)
push!(n1.children, n9)
push!(n1.children, n10)


function younger_siblings(nd::Node)
    n_sibs = length(nd.mother.children)
    return view(nd.mother.children, (nd.id + 1):n_sibs)
end

younger_siblings(n1.children[1])


function growtree!(nd::Node, minsupp, k, maxdepth)
    sibs = younger_siblings(nd)
    for j = 1:length(sibs)
        transacts = nd.transactions & sibs[j].transactions
        if sum(transacts) ≥ minsupp
            items = zeros(Int16, k)
            items[1:k-1] = deepcopy(nd.item_ids[1:k-1])
            items[end] = sibs[j].item_ids[end]
            
            child = Node(Int16(j), items, transacts, nd)
            push!(nd.children, child)
        end
    end
    # Recurse on newly created children
    maxdepth -= 1
    if maxdepth > 0
        for child in nd.children 
            growtree!(child, minsupp, k+1, maxdepth)
        end
    end
end 

growtree!(n2, 1, 3, 3)


function occurrence(T::Array{Array{String, 1}, 1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    res = BitArray(n, p)

    for j = 1:p 
        for i = 1:n
            res[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    res 
end


function prefix_tree(items, k)
    root = Node(Int16(1), Int16[-1], BitArray(0))
    n_items = length(items)

    for j = 1:n_items
        nd = Node(Int16(j), Int16[j], occ[:, j], root)
        push!(root, nd)
    end
    n_kids = length(root.children)
    for j = 1:n_kids
        growtree!(root.children[j], minsupp, 2, 5)
    end
    root 
end








groceries = ["asparagus", "broccoli", "carrots", "cauliflower", "celery", 
             "corn", "cucumbers", "lettuce", "mushrooms", "onions", 
             "peppers", "potatos", "spinach", "zucchini", "tomatoes",
             "apples", "avocados", "bananas", "berries", "cherries",
             "grapefruit", "grapes", "kiwis", "lemons", "melon",
             "oranges", "peaches", "nectarines", "pears", "plums",
             "butter", "milk", "sour cream", "whipped cream", "yogurt",
             "bacon", "beef", "chicken", "ground beef", "turkey",
             "crab", "lobster", "oysters", "salmon", "shrimp", 
             "tilapia", "tuna", "flour", "sugar", "yeast", 
             "cookies", "crackers", "nuts", "oatmeal", "popcorn",
             "pretzels", "cosmetics", "floss", "mouthwash", "toothpaste"]

transactions = [sample(groceries, 12, replace = false) for x in 1:1_000_000];


function get_unique_items{M}(T::Array{Array{M, 1}, 1})
    dict = Dict{M, Int}()

    for t in T
        for i in t
            dict[i] = 1
        end
    end
    return [x for x in keys(dict)]
end


function occurrence(T::Array{Array{String, 1}, 1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    res = BitArray(n, p)

    for j = 1:p 
        for i = 1:n
            res[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    res 
end


t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]


@code_warntype get_unique_items(t)
@code_warntype occurrence(t)

occ1 = occurrence(t)





function transactions_to_nodes(T::Array{Array{String,1},1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    occur = falses(n, p)

    for j = 1:p 
        @simd for i = 1:n
            @inbounds occur[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    nodes = Array{Node,1}(p)
    for j = 1:p
        @inbounds nodes[j] = Node([Int16(j)], occur[:, j])
    end 
    

    return nodes
end


# Get size of largest transaction 
function max_transaction(T::Array{Array{String,1},1})
    res = 0
    n = length(T)
    for i = 1:n
        len = length(T[i])
        res = (len > res) ? len : res 
    end
    res 
end



function merge_nodes(node1, node2, k)
    ids = Array{Int,1}(k)
    ids[1:k-1] = deepcopy(node1.item_ids[1:(k-1)])
    if k == 2
        ids[k] = node2.item_ids[1]
    elseif k > 2
        ids[k] = node2.item_ids[k-1]
    end
    transacts = node1.transacts & node2.transacts
    nd = Node(ids, transacts)
    return nd 
end


function gen_children(parent::Node, k, minsupp = 1)

    nodes 
end




function frequent(T::Array{Array{String,1},1}, minsupp = 0)
    nodes = transactions_to_nodes(T)
    max_items = max_transaction(T)

    F = Array{Array{Node,1},1}(max_items)
    F[1] = nodes
    k = 2

    while k <= max_items 
        # println(k)
        F[k] = gen_next_layer(F[k-1], minsupp)
        k += 1
    end
    F
end

n = 100_000
t = [sample(groceries, 20, replace = false) for _ in 1:n];

@code_warntype frequent(t, 1)
@time f = frequent(t, round(Int, n*0.2));

