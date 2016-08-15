using Base.Threads

v = [[1, 2, 3], [1, 2, 3], [1, 2, 3],  [1, 2, 5], [1, 3, 4], [1, 4, 5], [2, 3, 4], [2, 3, 4], [2, 3, 5], [3, 4, 5]]
v = [rand([1, 2, 3, 4, 5], 10) for x = 1:1_000_000];



function combine_dicts!(d, d2)
    all_keys = [collect(keys(d)); collect(keys(d2))]
    uniq_keys = unique(all_keys)

    for k in uniq_keys
        d[k] = get(d, k, 0) + get(d2, k, 0)
    end
end


# Given an integer and a number of chunks, this function
# returns a vector of ranges that partition 1:n into
# nchnks total chunks.
function gen_ranges(n, nchnks)
    step_size = round(Int64, (ceil(n/nchnks)))
    first_idx = 1
    last_idx = 1 + step_size
    range_vec = Array{Range, 1}(nchnks)
    for i = 1:nchnks
        range_vec[i] = range(first_idx, step_size)
        first_idx += step_size
        last_chk = first_idx + step_size
        step_size = last_chk > n ? (n - first_idx + 1) : step_size
    end
    return range_vec
end


# Given a vector of vectors, this function returns a
# Dict with counts representing the frequency of each
# individual value.
function count_values(u)
    out = Dict()
    for i = 1:length(u)
        for v in u[i]
            out[v] = get(out, v, 0) + 1
        end
    end
    out
end


function pcount_values(v)
    nt = nthreads()
    dict_vec = Vector{Dict}(nt)
    range_vec = gen_ranges(length(v), nt)

    @threads for j = 1:nt
        dict_vec[j] = count_values(v[range_vec[j]])
    end
    cnt_dict = Dict()

    for j = 2:nt
        combine_dicts!(dict_vec[1], dict_vec[j])
    end
    return dict_vec[1]
end





@time count_values(v)
@time pcount_values(v)

d1 = count_values(v[1:50_000])
d2 = count_values(v[50_001:100_000])
