using StatsBase
using Base.Threads


import Base.sort
import Base.isless
import Base.==

type Node
    item_ids::Array{Int,1} 
    transacts::BitArray 
end

function ==(a::Node, b::Node)
    res = a.item_ids == b.item_ids && a.transacts == b.transacts 
    res 
end 

function ==(x::Array{Node,1}, y::Array{Node,1})
    n = length(x)
    res = length(y) == n
    i = 1
    while res && i < n
        println(i)
        res = x[i] == y[i]
        i += 1
    end
    res 
end




"""
    isless(x::Array{Int,1}, y::Array{Int,1})
This `isless()` method is defined to handle two Array{Int,1} so that we can 
use `sortperm()` function on arrays of arrays.
"""
function isless(x::Array{Int,1}, y::Array{Int,1})
    res = true 
    if length(x) ≠ length(y)
        error("isless() cannot be used to compare vectors of differing lengths")
    else 
        for i = 1:length(x)
            if x[i] > y[i]
                res = false 
                break
            end
        end
    end
    res 
end

function sort(x::Array{Array{Int,1},1})
    perm = sortperm(x)
    x[perm]
end


@code_warntype sortperm([[3, 13, 21], [3, 12, 14]])




groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer", "steak", "chicken"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1_000_000]

function get_unique_items{M}(T::Array{Array{M, 1}, 1})
    dict = Dict{M, Int}()

    # loop over transactions, store each item in I
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


function is_frequent(indcs::Array{Int,1}, idx::Int, occ::BitArray{2}, minsupp::Int)
    # NOTE: This function's number of allocations is constant with 
    # respect to the size of its input vectors (this is good!).
    n = size(occ, 1)
    bit_col = trues(n)
    for j in indcs
        bit_col &= view(occ, :, j)
    end
    cnt = sum(bit_col & view(occ, :, idx))
    
    res = cnt ≥ minsupp
    res 
end

transactions = [sample(groceries, 4, replace = false) for x in 1:100_000];
occ2 = occurrence(transactions);
@code_warntype is_frequent([1], 2, occ1, 2)
@time is_frequent([1], 2, occ2, 2)




function bitwise_and!(x::BitArray, y::BitArray)
    # NOTE: This function's number of allocations is constant with respect to the size 
    # of inputs. But it's slower than `x & y`, which doesn't modify in place and uses more mem.
    @threads for i = 1:length(x)
        @inbounds x[i] &= y[i]
    end
end

n = 100_000_000
@code_warntype bitwise_and!(bitrand(n), bitrand(n))
@time bitwise_and!(bitrand(n), bitrand(n))


function inplace_bitwise_and!(res::BitArray, x::BitArray, y::BitArray)
    @threads for i = 1:length(res)
        res[i] = x[i] & y[i]
    end
end

@code_warntype inplace_bitwise_and!(falses(n), bitrand(n), bitrand(n))
@time inplace_bitwise_and!(falses(n), bitrand(n), bitrand(n))



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
        @inbounds nodes[j] = Node([j], occur[:, j])
    end 
    
    # Get size of largest transaction 
    row_cnts = zeros(Int, n) 
    @simd for i = 1:n 
        @inbounds row_cnts[i] = sum(occur[i, :])
    end
    max_items = maximum(row_cnts)
    return (nodes, max_items) 
end


t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]

@code_warntype transactions_to_nodes(t)

@time transactions_to_nodes(t)

n = 1_000_000
transactions = [sample(groceries, 6, replace = false) for x in 1:n]
@time w1 = transactions_to_nodes(transactions);


function merge_nodes(node1, node2, k, n_obs)
    ids = Array{Int,1}(k)
    ids[1:k-1] = deepcopy(node1.item_ids[1:(k-1)])
    if k == 2
        ids[k] = node2.item_ids[1]
    elseif k > 2
        ids[k] = node2.item_ids[k-1]
    end
    transacts = falses(n_obs) 
    inplace_bitwise_and!(transacts, node1.transacts, node2.transacts)
    nd = Node(ids, transacts)
    return nd 
end


function gen_next_layer(prev::Array{Node,1}, minsupp = 0)
    k = length(prev[1].item_ids) + 1
    n = length(prev)
    nodes = Array{Node,1}(0)             # next layer of nodes
    n_obs = length(prev[1].transacts)

    for i = 1:(n-1)
        for j = (i+1):n 
            nd = merge_nodes(prev[i], prev[j], k, n_obs)
            if sum(nd.transacts) ≥ minsupp
                push!(nodes, nd)
            end 
        end 
    end
    nodes 
end

a1 = transactions_to_nodes(t)
@code_warntype gen_next_layer(a1)
@time gen_next_layer(w1);
a2 = gen_next_layer(a1)
a3 = gen_next_layer(a2)
a4 = gen_next_layer(a3)


function frequent(T::Array{Array{String,1},1}, minsupp = 0)
    nodes, max_items = transactions_to_nodes(T)
    F = Array{Array{Node,1},1}(max_items)
    F[1] = deepcopy(nodes)
    for k = 2:max_items
        # println(k)
        F[k] = gen_next_layer(F[k-1], minsupp)
    end
    F
end

n = 10
t1 = [sample(groceries, 6, replace = false) for x in 1:n]

@code_warntype frequent(t, 1)
@time f = frequent(t, 1);








