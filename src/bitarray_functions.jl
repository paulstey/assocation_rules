using StatsBase

import Base.sort
import Base.isless
import Base.Threads                 # used only for bitwise_and!() function 
import Base.==

type Node
    item_id::Array{Int,1} 
    transacts::BitArray 
end

function ==(a::Node, b::Node)
    res = a.item_id == b.item_id && a.transacts == b.transacts 
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
    if !res 
        println("$(x[i-1]) is not equal to $(y[i-1])")
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


@code_warntype sortperm([[3, 13, 21], [3, 12, 14]])



function transactions_to_nodes(T::Array{Array{String,1},1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    occur = BitArray(n, p)

    for j = 1:p 
        for i = 1:n
            @inbounds occur[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    nodes = Array{Node,1}(p)
    for j = 1:p
        @inbounds nodes[j] = Node([j], occur[:, j])
    end 
    nodes 
end


function transactions_to_nodes(T::Array{Array{String,1},1}; parallel::Bool = true)
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    occur = BitArray(n, p)

    for j = 1:p 
        @threads for i = 1:n
            @inbounds occur[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    nodes = Array{Node,1}(p)
    for j = 1:p
        @inbounds nodes[j] = Node([j], occur[:, j])
    end 
    nodes 
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
@code_warntype transactions_to_nodes(t, parallel = true)

@time transactions_to_nodes(t)

n = 1_000_000
transactions = [sample(groceries[1:6], 4, replace = false) for x in 1:n]
@time w1 = transactions_to_nodes(transactions);
@time w2 = transactions_to_nodes(transactions, parallel = true);
@assert w1 == w2



