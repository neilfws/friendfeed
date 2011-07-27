library(rJava)
library(rjson)

javapath <- paste(Sys.getenv("HOME"), "Dropbox/projects/code/java/mongodb/mongo.jar", sep = "/")
.jinit()
.jaddClassPath(javapath)

# connection
con     <- .jnew("com/mongodb/Mongo", "localhost")
db      <- con$getDB("friendfeed")

# fetch data
getFeed <- function(feed, name) {
  col     <- db$getCollection(feed)
  outfile <- paste("../../data/", name, ".RData", sep = "")
  entries <- col$find()
  # convert to list
  entries <- as.list(entries$toArray())
  entries <- lapply(entries, function(x) x$toString())
  entries <- lapply(entries, function(x) fromJSON(x))
  save(entries, file = outfile)
}

i2008 <- "ismb-2008"
i2009 <- "ismbeccb2009"
i2010 <- "ismb2010"
i2011 <- "ismbeccb2011"

getFeed(i2008, "i2008")
getFeed(i2009, "i2009")
getFeed(i2010, "i2010")
getFeed(i2011, "i2011")
