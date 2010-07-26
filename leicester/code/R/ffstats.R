# analyse comments
library(plyr)
library(igraph)

# function to read all CSV files and remove header lines
readCSV <- function(directory) {
  df <- NULL
  files <- list.files(path = paste(getwd(), directory, sep = "/"), full.names = T)
  for(file in files) {
    d  <- read.csv(file, header = T)
    df <- rbind(df, d)
  }
  unique.data.frame(df)
}

# function to write CSV and RData files
writeData <- function(prefix, dataframe) {
  rdatafile <- paste(prefix, "rda", sep = ".")
  rcsvfile  <- paste(prefix, "csv", sep = ".")
  save(dataframe, file = paste(getwd(), "rdata", rdatafile, sep = "/"))
  write.csv(dataframe, file = paste(getwd(), "rdata", rcsvfile, sep = "/"), quote = F, row.names = F)
}

setwd("~/Dropbox/projects/friendfeed/data")
users    <- read.csv("users.anon.csv")
users    <- users[sort.list(users$Account),]

# entries
entries <- readCSV("entries")
ecount   <- as.data.frame(table(entries$user))
colnames(ecount) <- c("user", "entries")
entries.merged <- merge(users, ecount, by.x = "Account", by.y = "user", all.x = T)
writeData("entries", entries.merged)

# comments
comments <- readCSV("comments")
comments.noself <- comments[comments$author != as.character(comments$comment_by),]
# comments *given*
ccount   <- as.data.frame(table(comments$comment_by))
colnames(ccount) <- c("id", "comments")
comments.given <- merge(users, ccount, by.x = "Account", by.y = "id", all.x = T)
writeData("comments_given", comments.given)
# comments *given* excluding own posts
ccount   <- as.data.frame(table(comments.noself$comment_by))
colnames(ccount) <- c("id", "comments")
comments.noself.given <- merge(users, ccount, by.x = "Account", by.y = "id", all.x = T)
writeData("comments_noself_given", comments.noself.given)
# comments *received*
ccount   <- as.data.frame(table(comments$author))
colnames(ccount) <- c("id", "comments")
comments.received <- merge(users, ccount, by.x = "Account", by.y = "id", all.x = T)
writeData("comments_received", comments.received)
# comments *received* excluding own posts
ccount   <- as.data.frame(table(comments.noself$author))
colnames(ccount) <- c("id", "comments")
comments.noself.received <- merge(users, ccount, by.x = "Account", by.y = "id", all.x = T)
writeData("comments_noself_received", comments.noself.received)

# likes
likes <- readCSV("likes")
# likes *given*
lcount   <- as.data.frame(table(likes$liked_by))
colnames(lcount) <- c("id", "likes")
likes.given <- merge(users, lcount, by.x = "Account", by.y = "id", all.x = T)
writeData("likes_given", likes.given)
# likes *received*
lcount   <- as.data.frame(table(likes$author))
colnames(lcount) <- c("id", "likes")
likes.received <- merge(users, lcount, by.x = "Account", by.y = "id", all.x = T)
writeData("likes_received", likes.received)

# subscriptions
subscriptions <- readCSV("subscriptions")
spcount <- as.data.frame(table(subscriptions$user))
colnames(spcount) <- c("id", "subscriptions")
subscriptions.merged <- merge(users, spcount, by.x = "Account", by.y = "id", all.x = T)
writeData("subscriptions", subscriptions.merged)

# subscribers
subscribers <- readCSV("subscribers")
sbcount <- as.data.frame(table(subscribers$user))
colnames(sbcount) <- c("id", "subscribers")
subscribers.merged <- merge(users, sbcount, by.x = "Account", by.y = "id", all.x = T)
writeData("subscribers", subscribers.merged)

# networks
formats <- c("ncol", "lgl", "graphml")
# start with the subscriptions
subscriptions.notype <- subscriptions[,1:2]
# remove subscriptions not in user list
subscriptions.notype <- subscriptions.notype[subscriptions.notype$subscription %in% users$Account,]
gs <- graph.data.frame(subscriptions.notype, directed = T)
m  <- match(V(gs)$name, users$Account)
V(gs)$id     <- as.vector(users[m, "ID"])
V(gs)$gender <- as.vector(users[m, "Gender"])
V(gs)$label  <- as.vector(users[m, "Account"])
V(gs)$degree <- degree(gs)
# spinglass membership
gs.sgc <- spinglass.community(gs)
V(gs)$membership <- gs.sgc$membership
for(i in 1:length(gs.sgc$csize)) {
  V(gs) [ membership == i-1 ]$color <- rainbow(length(gs.sgc$csize))[i]
}
# edge weights (all = 1 in this case)
E(gs)$weight <- count.multiple(gs)
gs <- simplify(gs)
# save files
save(gs, file = paste(getwd(), "rdata", "igraph_subscriptions.rda", sep = "/"))
for(f in formats) {
  filename = paste("igraph_subscriptions", f, sep = ".")
  write.graph(gs, paste(getwd(), "rdata", filename, sep = "/"), format = f)
}
# subscribers should just be the "inverse"

# next, weighted network based on comments
# remove authors not in user list
comments.noself.users <- comments.noself[comments.noself$author %in% users$Account,]
# switch author/commenter columns
gc <- graph.data.frame(comments.noself.users[,2:1], directed = T)
m  <- match(V(gc)$name, users$Account)
V(gc)$id     <- as.vector(users[m, "ID"])
V(gc)$gender <- as.vector(users[m, "Gender"])
V(gc)$label  <- as.vector(users[m, "Account"])
V(gc)$degree <- degree(gc)
# spinglass membership
gc.sgc <- spinglass.community(gc)
V(gc)$membership <- gc.sgc$membership
for(i in 1:length(gc.sgc$csize)) {
  V(gc) [ membership == i-1 ]$color <- rainbow(length(gc.sgc$csize))[i]
}
# edge weights (all = 1 in this case)
E(gc)$weight <- count.multiple(gc)
gc <- simplify(gc)
# save files
save(gc, file = paste(getwd(), "rdata", "igraph_comments.rda", sep = "/"))
for(f in formats) {
  filename = paste("igraph_comments", f, sep = ".")
  write.graph(gc, paste(getwd(), "rdata", filename, sep = "/"), format = f)
}

# finally, weighted network based on likes
# remove authors not in user list
likes.users <- likes[likes$author %in% users$Account,]
# switch author/liker columns
gl <- graph.data.frame(likes.users[,2:1], directed = T)
m  <- match(V(gl)$name, users$Account)
V(gl)$id     <- as.vector(users[m, "ID"])
V(gl)$gender <- as.vector(users[m, "Gender"])
V(gl)$label  <- as.vector(users[m, "Account"])
V(gl)$degree <- degree(gl)
# spinglass membership
gl.sgc <- spinglass.community(gl)
V(gl)$membership <- gl.sgc$membership
for(i in 1:length(gl.sgc$csize)) {
  V(gl) [ membership == i-1 ]$color <- rainbow(length(gl.sgc$csize))[i]
}
# edge weights (all = 1 in this case)
E(gl)$weight <- count.multiple(gl)
gl <- simplify(gl)
# save files
save(gl, file = paste(getwd(), "rdata", "igraph_likes.rda", sep = "/"))
for(f in formats) {
  filename = paste("igraph_likes", f, sep = ".")
  write.graph(gl, paste(getwd(), "rdata", filename, sep = "/"), format = f)
}

# temporal analysis
# entries by date
dates <- as.data.frame(table(entries$date))
#dates <- dates[-grep("date", dates[,1]),]
colnames(dates) <- c("date", "entries")
dates$date <- as.Date(dates$date)
dates <- dates[sort.list(dates$date),]
writeData("entries_by_date", dates)

# entries by day of week
entries$day <- weekdays(strptime(entries$date, "%Y-%m-%d"))
days <- as.data.frame(table(entries$day))
colnames(days) <- c("day", "entries")
days$weekday <- c(6,2,7,1,5,3,4)
days <- days[sort.list(days$weekday),]
writeData("entries_by_dow", days)

# entries by time of day
entries$hour <- substring(entries$time, 0, 2)
timeday <- as.data.frame(table(entries$day, entries$hour))
colnames(timeday) <- c("day", "hour", "entries")
series <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
series <- factor(series, levels = series)
levels(timeday$day) <- series
writeData("entries_by_timeday", timeday)

# comments by date
dates <- as.data.frame(table(comments$date))
#dates <- dates[-grep("date", dates[,1]),]
colnames(dates) <- c("date", "comments")
dates$date <- as.Date(dates$date)
dates <- dates[sort.list(dates$date),]
writeData("comments_by_date", dates)

# comments by day of week
comments$day <- weekdays(strptime(comments$date, "%Y-%m-%d"))
days <- as.data.frame(table(comments$day))
colnames(days) <- c("day", "comments")
days$weekday <- c(6,2,7,1,5,3,4)
days <- days[sort.list(days$weekday),]
writeData("comments_by_dow", days)

# comments by time of day
comments$hour <- substring(comments$time, 0, 2)
timeday <- as.data.frame(table(comments$day, comments$hour))
colnames(timeday) <- c("day", "hour", "comments")
levels(timeday$day) <- series
writeData("comments_by_timeday", timeday)

# likes by date
dates <- as.data.frame(table(likes$date))
#dates <- dates[-grep("date", dates[,1]),]
colnames(dates) <- c("date", "likes")
dates$date <- as.Date(dates$date)
dates <- dates[sort.list(dates$date),]
writeData("likes_by_date", dates)

# likes by day of week
likes$day <- weekdays(strptime(likes$date, "%Y-%m-%d"))
days <- as.data.frame(table(likes$day))
colnames(days) <- c("day", "likes")
days$weekday <- c(6,2,7,1,5,3,4)
days <- days[sort.list(days$weekday),]
writeData("likes_by_dow", days)

# likes by time of day
likes$hour <- substring(likes$time, 0, 2)
timeday <- as.data.frame(table(likes$day, likes$hour))
colnames(timeday) <- c("day", "hour", "likes")
levels(timeday$day) <- series
writeData("likes_by_timeday", timeday)
