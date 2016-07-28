# Find k-freq-itemset in given transactions of items queried together
# using StatsBase

include("./src/common.jl")
include("./src/display_utils.jl")
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

@time get_unique_items(v);
@time unique(reduce(append!, v));



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

                # see if all k - 1 elements are identical
                if x[i][l] != x[j][l]
                    keep_candidate = false
                    break
                end
            end
            if keep_candidate
                # Julia isn't inferring the type of c below, but
                # telling the compiler doesn't improve speed
                c = [x[i]; x[j][end]]
                push!(C, sort!(c))
            end
        end
    end
    return C              # vector of candidate itemsets: C_{k}
end

v = [rand([1, 2, 3, 4, 5], 10) for x = 1:1000];
# @code_warntype apriori_gen(v)
@time apriori_gen(v)


# Find frequent itemsets from transactions
# @T: array of transactions (each is a set)
# @minsup: minimum support
# NOTE: This function agrees with R
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

v = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
v = [[1, 2], [1, 3], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5]]
# v = [rand([1, 2, 3, 4, 5], 10) for x = 1:1000];
# @code_warntype freq_itemset_gen(v, 0.5)
freq_itemset_gen(v, 0.2)



v = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
@time apriori_gen(v)







# R: Array of rules
# f: frequent itemset
# H: Array of rule consequents (also arrays)
# T: Array of transactions

function ap_genrules!{M}(fk::Vector{M}, Hm::Vector{Vector{M}}, T::Vector{Vector{M}}, minconf, R)
    k = length(fk)
    m = length(Hm[1])            # NOTE: will need to confirm length(Hm) ≥ 1

    if k > m+1
        H_mplus1 = apriori_gen(Hm)
        indcs_to_drop = Array{Int}(0)

        for (idx, h_mp1) in enumerate(H_mplus1)
            p = setdiff(fk, h_mp1)

            if conf(p, h_mp1, T) ≥ minconf
                push!(R, Rule(p, h_mp1))
            else
                push!(indcs_to_drop, idx)
            end
        end

        # remove the indices of consequents with low confidence
        reverse!(indcs_to_drop)
        for indx in indcs_to_drop
            deleteat!(H_mplus1, indx)
        end
        ap_genrules!(fk, H_mplus1, T, minconf, R)
    end
end

rules = Vector{Rule}(0)
freq = [1, 2]
consq = [Int[], [1], [2], [3], [4], [5]]
trans = [[1, 2], [1, 3], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5]]
ap_genrules!(freq, consq, trans, 0.01, rules)
rules



# Generate rules from frequent itemsets
# @x: list of frequent itemsets
# @T: Transaction list
function generate_rules{M}(freq::Vector{Vector{Vector{M}}}, T, minconf)
    k_max = length(freq)
    # if k_max ≤ 1;
    #     return Array{M}(0)          # F contains 1-itemsets only; no rules generated.
    # end
    R = Array{Rule}(0)
    F = Array{Array, 1}(0)
    for i = 1:k_max
        map(x -> push!(F, x), freq)
    end

    for k = 1:k_max
        H1 = map(x -> [x], get_unique_items(F[k]))
        reverse!(push!(H1, Array{M}(0)))
        display(H1)
        for f in F[k]
            println("f: ", f)
            ap_genrules!(f, H1, T, minconf, R)
        end
    end
    return R
end

v = [[1, 2], [1, 3], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5]]
freq_itemsets = freq_itemset_gen(v, 0.2)

rules = generate_rules(freq_itemsets, v, 0.01)





















































#
