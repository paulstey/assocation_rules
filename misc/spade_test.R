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

s1 <- cspade(x, parameter = list(support = 0.2, maxlen = 10), control = list(verbose =TRUE))

as(s1, "data.frame")
summary(s1)

r1 <- ruleInduction(s1, confidence = 0.01)
as(r1, "data.frame")
