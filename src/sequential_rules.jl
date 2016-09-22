
# NOTE: The gen_rules1() function is quite inefficient. In
# particular, it's runtime is O(n*m*2^k) where k is the number
# of elements in the pattern, m is the number of patterns for a
# given pattern length k, and n is the number of different pattern
# lengths. Additionally, though this corresponds to the pseudocode
# Zaki provides in his orginal paper, it is not the implementation
# that appears in the arulesSequence package.

function gen_rules1(F::Array{Array{IDList, 1}, 1}, min_conf)
    supp_count = count_patterns(F)
    rules = String[]

    # Check the confidence for all sub-patterns
    # from all of our frequent patterns
    for k = 1:length(F)
        for i = 1:length(F[k])
            sub_patrns = gen_combin_subpatterns(F[k][i].patrn)
            for s in sub_patrns
                if s ≠ ""
                    cnt = get(supp_count, s, 0)
                    conf = isfinite(cnt) ? F[k][i].supp_cnt/cnt : -Inf

                    if conf ≥ min_conf
                        push!(rules, "$s => $(pattern_string(F[k][i].patrn))")
                    end
                end
            end
        end
    end
    rules
end

rules = gen_rules1(res, 0)



function create_children(patrn::Array{Array{String,1},1}, uniq_items, supp_count, recurse = true)
    seq_extended_children = Array{PrefixNode,1}(0)
    item_extended_children = Array{PrefixNode,1}(0)

    if recurse
        for item in uniq_items
            seq_extd_patrn = sequence_extension(patrn, item)
            seq_extd_supp = get(supp_count, pattern_string(seq_extd_patrn), 0)

            item_extd_patrn = item_extension(patrn, item)
            item_extd_supp = get(supp_count, pattern_string(item_extd_patrn), 0)

            seq_extd_child = PrefixNode(seq_extd_patrn, seq_extd_supp, create_children(seq_extd_patrn, uniq_items, supp_count, false)[1], create_children(seq_extd_patrn, uniq_items, supp_count, false)[2])

            item_extd_child = PrefixNode(item_extd_patrn, item_extd_supp, create_children(item_extd_patrn, uniq_items, supp_count, false)[1], create_children(item_extd_patrn, uniq_items, supp_count, false)[2])

            push!(seq_extension_children, seq_extd_child)
            push!(item_extension_children, item_extd_child)
        end
    end

    return (seq_extended_children, item_extended_children)
end






function gen_rules_from_root!(node::PrefixNode, uniq_items, rules::Array{String,1}, supp_count, min_conf)

    for nseq in node.seq_extension_children)
        child_patterns = seq_and_item_extension(nseq.patrn, unique_items)

        for l in child_patterns


function build_ptree(F::Array{Array{IDList,1},1}, min_conf, num_uniq_sids)
    supp_count = count_patterns(F)
    uniq_items = String[]

    for k = 1:length(F)
        for i = 1:length(F[k])
            if F[k][i] ∉ uniq_items
                push!(uniq_items, F[k][i])
            end
        end
    end
    node = PrefixNode("{}", num_uniq_sids, uniq_items, uniq_items)
    rules = String[]

    gen_rules_from_root!(node, F, rules, supp_count, min_conf)
