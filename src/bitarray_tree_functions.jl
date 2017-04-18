using StatsBase


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

# @code_warntype Node(Int16(1), Int16[1], trues(3))

n1 = Node(Int16(1), Int16[1], trues(3))

# @code_warntype Node(Int16(1), Int16[1, 2], trues(3), n1)
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

# @code_warntype growtree!(n2, 1, 3, 3)
growtree!(n2, 1, 3, 3)



function get_unique_items{M}(T::Array{Array{M, 1}, 1})
    dict = Dict{M, Bool}()

    for t in T
        for i in t
            dict[i] = true
        end
    end
    return collect(keys(dict))
end

@time get_unique_items(t);


function occurrence(T::Array{Array{String, 1}, 1}, uniq_items::Array{String,1})
    n = length(T)
    p = length(uniq_items)
    res = BitArray(n, p)
    for j = 1:p 
        for i = 1:n
            res[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    res 
end

unq = get_unique_items(t)
@code_warntype occurrence(t, unq)


function buildtree(T::Array{Array{String,1},1}, minsupp, maxdepth)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)

    occ = occurrence(T, uniq_items)
    root = Node(Int16(1), Int16[-1], BitArray(0))
    n_items = length(uniq_items)

    # Creat 1-item nodes (i.e., first children)
    for j = 1:n_items
        nd = Node(Int16(j), Int16[j], occ[:, j], root)
        push!(root.children, nd)
    end
    n_kids = length(root.children)

    # Grow nodes in breadth-first manner
    for j = 1:n_kids
        growtree!(root.children[j], minsupp, 2, maxdepth)
    end
    root 
end


t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]

@code_warntype buildtree(t, 1, 3)
xtree1 = buildtree(t, 1, 3)





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
             "pretzels", "cosmetics", "floss", "mouthwash", "toothpaste",
             "lime", "almonds", "cashews", "ketchup", "mustard",
             "barley, quinoa", "couscous", "rice cakes", "pita bread",
             "agave", "soy milk", "almond milk", "apple butter", "maple syrup",
             "coffee filters", "granola", "bleach", "toaster pasteries", "glass cleaner",
             "paper towels", "paper plates", "napkins", "sour cream", "pepperonis",
             "buns", "rolls", "half and half", "steak sauce", "relish", 
             "gravy", "lip balm", "goat cheese", "sunblock", "hand soap",
             "muffins", "floss", "spaghetti", "bbq sauce", "vinegar"]

# transactions = [sample(groceries, 12, replace = false) for x in 1:10];


n = 100_000
m = 10              # number of items in transactions
t = [sample(groceries, m, replace = false) for _ in 1:n];

# @code_warntype buildtree(t, 1)
@time f = buildtree(t, round(Int, n*0.1), m);


"""
    randstring(n, len)

This function generates `n` random strings of length `len`. The strings will 
be concatenated characters uniformally drawn from all alphabetic characters 
(uppers and lowercase), as well as the numbers 0 to 9.
"""
function randstring(n::Int, len::Int = 16)
    vals = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
               "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    upper = map(uppercase, vals)
    append!(vals, upper)
    append!(vals, map(string, 0:9))
    res = Array{String,1}(n)
    for i = 1:n
        res[i] = join(rand(vals, len))
    end
    res
end



itemlist = randstring(500);


n = 1_000_000
m = 10              # number of items in transactions
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype buildtree(t, 1)
@time f = buildtree(t, round(Int, n*0.1), m);













@code_warntype get_unique_items(t)

occ1 = occurrence(t)





