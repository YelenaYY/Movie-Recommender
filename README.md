
# A movie recommender based on collaborative filtering.


Link to R|Shiny App for a movie recommendation website: 
[Shiny Page](https://yelenayu.shinyapps.io/movie_recommender/)

## Description

A movie recommender application was built using R|Shiny.
Shiny is a framework used for building web applications UI under R.


The algorithm provides two method of recommending:
1. Recommendation system based on genres:
	It recommends top-10 movies based on the user selected genre.
2. Recommendation system based on rating:
	An user-based collaborative filtering recommendation system. It recommends top-10 movies based on user's ratings on other movies. 
	(The more movies rated, the more accurate result will be presented)

Both user-based and item-based collaborative filtering are supported. 
User-based collaborative filtering was selected for the implementation because the expectation is user pattern is consistent and predictable.
	(In case alg_method=="ubcf" it should be IU matrix (items are rows, users are columns). 
	 In case In case alg_method=="ibcf" it should be UI matrix.)


### About Collaborative filtering:

Collaborative filtering is the predictive process behind [Recommendation Engines](https://www.techtarget.com/whatis/definition/recommendation-engine). 

Recommendation engines analyze information about users with similar tastes to assess the probability that a target individual will enjoy something, such as a video, a book or a product. Collaborative filtering is also known as social filtering, which uses *similarities between users and items simultaneously* to provide recommendations.

It uses algorithms to filter and analyze data from user reviews/ratings to make personalized recommendations for users with similar preferences. Collaborative filtering is also used to select content and advertising for individuals on social media.

Two Barriers of CF:
1. Sparsity:
	If most users don't rate, which is actually the case in real practice, there will be a lot of empty cells. However, collaborative filter depends on matrix that not being too sparse.
    
2. Grey & Black Sheep problem:
	Black sheep is the problem when we have a group of users that are not close to any cluster at all. Then the model not sure how to recommend related content to them.


### Data Resource:

[Movie Lense](https://grouplens.org/datasets/movielens/)
The project uses MovieLens MovieLens 1M Dataset, contain 1,000,209 anonymous ratings of approximately 3,900 movies 
made by 6,040 MovieLens users who joined MovieLens in 2000.

