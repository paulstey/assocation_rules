import Base.sort
import Base.isless



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



groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:100_000]

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
occ2 = occurrence(transactions)


function is_frequent(indcs::Array{Int,1}, idx::Int, occ::BitArray{2}, minsupp::Int)
    n = size(occ, 1)
    bit_col = trues(n)
    for j in indcs
        bit_col &= view(occ, :, j)
    end
    cnt = sum(bit_col & view(occ, :, idx))
    println(cnt)
    res = cnt ≥ minsupp
    res 
end

@code_warntype is_frequent([1], 2, occ1, 2)
@time is_frequent([1], 2, occ2, 2)






@code_warntype sortperm([[3, 13, 21], [3, 12, 14]])
