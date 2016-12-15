#fp_growth_performance.jl

include("fp_growth.jl")

#Testing and benchmarking
adult = readtable("/Users/pstey/projects_code/association_rules_jl/data/adult.csv")
T = make_transactions(adult)

find_frequent_patterns(T[1:2], 1)

Profile.clear_malloc_data()

@time find_frequent_patterns(T[1:500], 50);
