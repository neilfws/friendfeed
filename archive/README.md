## Archive
This directory contains archives of FriendFeed feeds. They were captured by saving JSON from the FriendFeed API to a MongoDB database collection  using [this code](https://github.com/neilfws/friendfeed/blob/master/ismb/code/ruby/ff2mongo.rb).

The JSON files were generated using mongoexport _e.g._

    mongoexport --query '{ $query: {}, $orderby: { date: 1 } }' --db friendfeed --collection the_life_scientists  --out archive/the_life_scientists.json --journal

I cannot guarantee that all of the information in the original feed was captured by this process.

Commit log dates indicate when the files were generated. FriendFeed is shutting down on 2015-04-09 but I cannot promise further archives between now (2015-03-10) and that date.


