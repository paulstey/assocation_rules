library(arulesSequences)
example("cspade")

data("zaki")
t <- zaki
transactionInfo(t)$classID <- as.integer(transactionInfo(t)$sequenceID) %% 2 + 1L

fm1 <- cspade(zaki, parameter = list(support = 0.25, maxlen = 2))
summary(fm1)

head(as(fm1, "data.frame"), 40)




x <- read_baskets(con = system.file("misc", "zaki.txt", package = "arulesSequences"), info = c("sequenceID","eventID","SIZE"))
as(x, "data.frame")

s1 <- cspade(x, parameter = list(support = 0.2, maxlen = 20), control = list(verbose =TRUE))

as(s1, "data.frame")
summary(s1)

r1 <- ruleInduction(s1, confidence = 0.01)
res <- as(r1, "data.frame")

print_results <- function(dat) {
    n <- nrow(dat)
    for (i in 1:n) {
        print(as.character(dat[i, 1]))
    }
}

print_results(res)






# subset of Zaki data
dset <- read_baskets("./projects_code/association_rules/data/zaki_subset_data_forR.txt", sep = "[ \t]+",info =  c("sequenceID","eventID", "SIZE"))
summary(dset)
as(dset, "data.frame")

s2 <- cspade(dset, parameter = list(support = 0.2, maxlen = 20), control = list(verbose =TRUE))

as(s2, "data.frame")
summary(s2)

r2 <- ruleInduction(s2, confidence = 0.01)
res2 <- as(r2, "data.frame")

print_results <- function(dat) {
    n <- nrow(dat)
    for (i in 1:n) {
        print(as.character(dat[i, 1]))
    }
}

print_results(res2)
nrow(res2)





# subset of Zaki data
dset <- read_baskets("./projects_code/association_rules/data/zaki_data_extra_forR.txt", sep = "[ \t]+",info =  c("sequenceID","eventID", "SIZE"))
summary(dset)
as(dset, "data.frame")

s3 <- cspade(dset, parameter = list(support = 0.2, maxlen = 20), control = list(verbose =TRUE))

as(s3, "data.frame")
summary(s3)

r3 <- ruleInduction(s3, confidence = 0.01)
res3 <- as(r3, "data.frame")

print_results(res3)
nrow(res3)






x <- list("01" = list(c("A","B", "C"), "D"),
          "02" = list("C"),
          "03" = list("B", "B"),
          "04" = list("A", "C", "D"))


x <- list("01" = list(c("A","B"), "C"),
          "02" = list("A", "B"),
          "03" = list(c("D")))
## uses paste
s <- as(x, "sequences")
s

getSlots("sequences")
s@elements
s@sequenceInfo
s@data@p
s@data@i

getSlots("itemsets")
s@elements@items

getSlots("itemMatrix")
s@elements@items@data
