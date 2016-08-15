addprocs(4)



v = [[1, 2, 3], [1, 2, 3], [1, 2, 3],  [1, 2, 5], [1, 3, 4], [1, 4, 5], [2, 3, 4], [2, 3, 4], [2, 3, 5], [3, 4, 5]]
v = [rand([1, 2, 3, 4, 5], 10) for x = 1:100_000];

dv = distribute(v)


function combine_dicts(d1, d2)
    all_keys = [collect(keys(d1)); collect(keys(d2))]
    uniq_keys = unique(all_keys)
    out = Dict()

    for k in uniq_keys
        out[k] = get(d1, k, 0) + get(d2, k, 0)
    end
    out
end


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



function count_values(u)
    out = Dict()
    for i = 1:length(u)
        for v in u[i]
            out[v] = get(out, v, 0) + 1
        end
    end
    out
end

function pcount_values(da)
    np = length(procs(da))
    dict_vec = Vector{Dict}(np)
    @async for j = procs(da)
        dict_vec[j-1] = remotecall_fetch(count_values, j, da)
    end
    dict_vec
end





@time count_values(dv)
d1 = count_values(v[1:50_000])
d2 = count_values(v[50_001:100_000])



darray_closeall()
