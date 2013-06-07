window.blogRanking = angular.module('blogRanking',[])
window.blogRanking.factory('AuthorData', -> 
  new blogRanking.AuthorCollection())
window.blogRanking.factory('PostData', -> 
  new blogRanking.PostCollection())

#  config(($routeProvider) -> 
#    $routeProvider.
#      when('/', {controller: ListCtrl, templateUrl: 'list.html'}))

AuthorSelectionCtrl = ($scope,$http,AuthorData,PostData) ->
  $scope.authors = AuthorData

  $scope.authorSelectionEnabled = false

  $scope.toggleAuthorSelection = ->
    $scope.authorSelectionEnabled = !$scope.authorSelectionEnabled

  $scope.savePost = (post) ->
    json = {}
    json.author = post.author.name
    json.url    = post.url
    json._rev   = post.rev if post.rev
    json._id    = post.id if post.id

    baseURL = "http://127.0.0.1:5984/posts/"
    url = if post.id then baseURL + post.id else baseURL
    method = if post.id then "PUT" else "POST"

    $http(
      url: url,
      method: method,
      data: json,
      headers: {"Content-Type":"application/json"},
    ).success( 
      (data, status, headers, config) -> 
        post = PostData.findByUrl(post.url)
        post.id  = data.id
        post.rev = data.rev
    ).error( 
      (data, status, headers, config) -> 
        $scope.status = status
    ) 

    $scope.toggleAuthorSelection()


ListCtrl = ($scope, $http, AuthorData, PostData) ->

  $scope.filter = new blogRanking.Filter

  $scope.formatSecondsToMinutes = (value) -> 
    minutes = Math.floor(value / 60)
    seconds = Math.round(value % 60)
    minuteString = minutes.toString()
    secondString = if seconds < 10 then "0" + seconds.toString() else seconds.toString()
    minuteString + ":" + secondString 

  $scope.updatePage = -> 
    fetchPosts()

  fetchPosts = ->
    $http(
      url: "http://127.0.0.1:5984/posts/_all_docs?include_docs=true",
      method: "GET",
    ).success( 
      (data, status, headers, config) -> 
        $scope.posts = PostData.initializePosts(data.rows) 
        applyVisits($scope.posts,$scope.filter)
    ).error( 
      (data, status, headers, config) -> 
        $scope.status = status
    ) 

  applyVisits = (posts,filter) ->
    gapi.client.load 'analytics', 'v3', -> 
      request = prepareRequest(filter,{
        'metrics': 'ga:visits',
        'sort': '-ga:visits',
      })
      request.execute (response) ->
        posts.applyVisits(response.rows)
        applyEngagement(posts,$scope.filter)

  applyEngagement = (posts,filter) ->
    gapi.client.load 'analytics', 'v3', -> 
      request = prepareRequest(filter,{
        'metrics': 'ga:avgTimeOnSite',
        'sort': '-ga:avgTimeOnSite',
      })
      request.execute (response) ->
        posts.applyTimeOnSite(response.rows)
        $scope.authors = AuthorData 
        $scope.authors.assignPosts($scope.posts) 
        $scope.$apply()

  prepareRequest= (filter,params) ->
    standard_params = {
        'ids': 'ga:51266672',
        'dimensions' : 'ga:pagepath',
        'start-date': filter.startDate,
        'end-date': filter.endDate,
        'max-results': '10',
    }
    gapi.client.analytics.data.ga.get(jQuery.extend(standard_params,params))

  $scope.updatePage();

blogRanking.controller 'ListCtrl', ListCtrl
blogRanking.controller 'AuthorSelectionCtrl', AuthorSelectionCtrl

blogRanking.directive 'datepicker', -> 
  (scope, element, attrs) ->
    element.fdatepicker({
      format: 'yyyy-mm-dd'
    }).on 'changeDate', ->
      # e.g. ng-model is "filter.endDate"
      attrPath = $(this).attr('ng-model')
      attrs = attrPath.split(".")
      scope[attrs[0]][attrs[1]] = $(this).val()
