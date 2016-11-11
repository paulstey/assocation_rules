# AssociationRules
[![Build Status](https://travis-ci.org/bcbi/AssociationRules.jl.svg?branch=master)](https://travis-ci.org/bcbi/AssociationRules.jl)
[![codecov](https://codecov.io/gh/bcbi/AssociationRules.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/AssociationRules.jl)



## Description
This package implements algorithms for association rule mining and sequential pattern mining. In particular, we have currently implemented the _Apriori_ algorithm (Agrawal & Srikant, 1994) and the SPADE algorithm (Zaki, 2001). The former is used for association rule mining (e.g., "market basket" analysis), and the latter is used for identifying sequential patterns when the data possess a temporal ordering. The algorithms are written in pure Julia.


Note that a portion of our implementation of the _Apriori_ algorithm was adapted from the earlier work of [toddleo](https://github.com/toddleo/ARules.jl).


## Initial Setup
```{Julia}
Pkg.clone("https://github.com/bcbi/AssociationRules.jl.git")
```

## Examples
Several examples below illustrate the use and features of the `apiori()` function and the `spade()` function.

### Ex. 1 _Apriori_ Algorithm:
Here we are generating association rules using the `apriori()` function.
```{Julia}
using AssociationRules
using StatsBase                        # for sample() function

# simulate transactions
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# minimum support of 0.1, minimum confidence of 0.4
rules = apriori(transactions, 0.1, 0.4)
```


Note that by default our `apriori()` function generates multi-item consequents. However, it can be made to mimic the `apriori()` function in R's _arules_ package and generate only single-item consequents.
```{Julia}
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# fourth argument prevents multi-item consequents
rules = apriori(transactions, 0.1, 0.4, false)
```


We can also use the `frequent()` function to generate the frequent item sets based on some minimum support threshold. Note that this function is called internally by the `apriori()` function when generating association rules.
```{Julia}
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# item sets with minimum support of 0.1
fk = frequent(transactions, 0.1)
```



### Ex. 2 _Apriori_ Algorithm (with tabular data)
The more common scenario will be the one in which we start with tabular data from a two-dimensional `Array` or a `DataFrame` object.
```{Julia}
adult = dataset("adult")

# convert tabular data
transactions = make_transactions(adult[1:1000, :])       # use only first 1000 rows

rules = apriori(transactions, 0.1, 0.4)
```



### Ex. 3 SPADE Algorithm
The SPADE algorithm takes sequential transaction or event data and generates frequent sequential patterns. Once again, the standard scenario is the one in which we start with tabular data from a two-dimensional `Array` or a `DataFrame` object. This is then converted to and array of `Sequence` objects, which is the input type that our `spade()` function requires.
```{Julia}
zaki_data = dataset("zaki_data")

# Convert tabular data to sequences. Item is in
# column 1, sequence ID is column 2, and event ID is column 3.
seqs = make_sequences(zaki_data, item_col = 1, sid_col = 2, eid_col = 3)                   

# generate frequent sequential patterns with minimum
# support of 0.1 and maximum of 6 elements
fseq = spade(seqs, 0.1, 6)
```


### Ex. 4 Sequential Rules
The SPADE algorithm is used to generate frequent sequential patterns. Using these patterns we can derive sequential rules of the type _{X} => {Y}_, where _{X}_ and _{Y}_ are sequential patterns and _{X}_ preceded _{Y}_.
```{Julia}
zaki_data = dataset("zaki_data")

seqs = make_sequences(zaki_data, item_col = 1, sid_col = 2, eid_col = 3)                   
fseq = spade(seqs, 0.1, 6)

# generate sequential rules with minimum
# confidence of 0.1, and a maximum of 6 elements
rules = sequential_rules(fseq, 0.1, 6)
```   
## Current Algorithms
- _Apriori_ Algorithm (Agrawal & Srikant, 1994)
- SPADE Algorithm (Zaki, 2001)


## In progress
- Update _Apriori_ to take advantage of multi-threaded parallelism


## To do
- Add measures of interestingness for rules generated by the _Apriori_ algorithm

## _Caveats_
- The implementations of the SPADE algorithm and the rule-induction algorithm for sequential patterns have exponential run time, and thus, are quite slow and memory inefficient for even moderately sized problems.
- This package is under active development. Please notify us of bugs or proposed improvements by submitting an issue or pull request.
