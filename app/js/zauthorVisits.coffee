class blogRanking.AuthorCollection

  compileTotalPosts: (posts) ->
    authors = []
    for post in posts
      if author = _.detect(authors,(author) -> post.author == author.name)
        author.totalPosts = parseInt(author.totalPosts) + 1
      else
        authors.push({'name':post.author,'totalPosts':1}) if post.author
    _.sortBy(authors,(author) -> 0 - author.totalPosts)

  compileVisits: (posts) ->
    authors = []
    for post in posts
      if author = _.detect(authors,(author) -> post.author == author.name)
        author.visits = parseInt(author.visits) + parseInt(post.visits)
      else
        authors.push({'name':post.author,'visits':parseInt(post.visits)}) if post.author
    _.sortBy(authors,(author) -> 0 - author.visits)

  compileEngagements: (posts) ->
    authors = []
    for post in posts
      if author = _.detect(authors,(author) -> post.author == author.name)
        author.timeOnSite = parseInt(author.timeOnSite) + parseInt(post.timeOnSite)
      else
        authors.push({'name':post.author,'timeOnSite':parseInt(post.timeOnSite)}) if post.author
    _.sortBy(authors,(author) -> 0 - author.timeOnSite)