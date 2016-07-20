# Find k-freq-itemset in given transactions of items queried together
using StatsBase


# Given a vector of transactions (each is a vector), this
# function returns a single array with all the unique items.

function get_unique_items(T::Array{Array{Int, 1}, 1})
    I = Array{Int, 1}(0)
    dict = Dict{Int, Int}()

    # loop over transactions, store each item in I
    for t in T
        for i in t
            dict[i] = 1
        end
    end
    return keys(dict)
end

# v = [[1, 2, 3], [1, 2, 4], [1, 3, 5], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
v = [rand([1, 2, 3, 4, 5], 10) for x = 1:10_000];

@time get_unique_items(v)






# Given C_{k-1}, which is a vector of transactions (and each
# transaction is a vector), this function returns the candidate
# frequent item sets C_k
function apriori_gen{M}(x::Array{Array{M, 1}, 1})
    n = length(x)
    m = length(x[1]) - 1
    C = Array{Array{M, 1}, 1}(0)

    for i = 1:n
        for j = (i+1):n
            sort!(x[i])
            sort!(x[j])
            keep_candidate = true

            # length k candidate itemsets are created by merging pairs of
            # length k - 1 itemsets if their first k - 2 elements identical
            for l in 1:m

                # confirm all k - 1 elements are identical
                if x[i][l] != x[j][l]
                    keep_candidate = false
                    break
                end
            end
            if keep_candidate
                c = [x[i]; x[j][end]]
                push!(C, sort!(c))
            end
        end
    end
    return C              # vector of candidate itemsets: C_{k}
end














# Find frequent itemsets from transactions
# @T: array of transactions (each is a set)
# @minsup: minimum support
function freq_itemset_gen{M}(T::Array{Array{M, 1}, 1}, minsup::Float64)

    I = get_unique_items(T)

    # Find freq-itemset when k = 1: F_k = {i : i ∈ I ∧ σ({i}) ≥ N × minsup}
    F = Array{Array{Array{M, 1}, 1}, 1}(0)
    N = length(T)
    min_n = N * minsup

    push!(F, map(x -> [x], filter(i -> σ(i, T) ≥ min_n, I)))

    persist = true
    while persist
        C_k = apriori_gen(F[end]) # Generate candidate set C_k from F_{k-1}
        F_k = filter(c -> σ(c, T) ≥ min_n, C_k)
        if !isempty(F_k)
            push!(F, F_k) # Eliminate infrequent candidates, then set to F_k
        else
            persist = false
        end
    end
    return F
end

v = [[1, 2, 3], [1, 2, 4], [1, 3, 5], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
@time freq_itemset_gen(v, 0.5)



v = [[1, 2, 3], [1, 2, 4], [1, 3, 5], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
@time apriori_gen(v)













# Generate rules from frequent itemsets
# @x: list of frequent itemsets
# @T: Transaction list
function gen_rules(x, T)
    if length(x) <= 1;
        return [] # F contains 1-itemsets only, hence no rules generated.
    end
    x = reduce(append!, x[2:end])
    R = Array(Rule, 0)
    for f in x # f as each freq-f-itemset fₖ
        ap_genrules!(R,f,map(i->Array([i]),f),T) # H₁ itemset is same as f
    end
    R
end


function ap_genrules!(R, f, H, T)
    k, m = length(f), length(H[1])
    if k > m + 1
        H = apriori_gen(H)
        H_plus_1 = []
        for h in H
            p = setdiff(f,h)
            if conf(p, h, T) >= minconf
                push!(R, Rule(p,h))
                push!(H_plus_1, h)
            end
        end
        ap_genrules(R, f, H_plus_1, T)
    end
end

# TODO: Closed Frequent Itemset
