
# testing a-priori algorithm
l = [sample([1, 2, 3, 4, 5], 5, replace = false) for x in 1:100_000]
fk = freq_itemsets(l, 0.1)
rules = apriori(l, 0.1, 0.8, false);


# testing SPADE algorithm
d = readcsv("./data/zaki_data.csv", skipstart = 1)
seqs = make_sequences(d, 2, 3, 1)
res = spade(seqs, 0.2, 5)
