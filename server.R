## server.R

# load functions
source('functions/cf_algorithm.R') # collaborative filtering
source('functions/similarity_measures.R') # similarity measures

# define functions
get_user_ratings = function(value_list) {
  dat = data.table(MovieID = sapply(strsplit(names(value_list), "_"), 
                                    function(x) ifelse(length(x) > 1, x[[2]], NA)),
                    Rating = unlist(as.character(value_list)))
  dat = dat[!is.null(Rating) & !is.na(MovieID)]
  dat[Rating == " ", Rating := 0]
  dat[, ':=' (MovieID = as.numeric(MovieID), Rating = as.numeric(Rating))]
  dat = dat[Rating > 0]
}

# read in data
myurl = "https://liangfgithub.github.io/MovieData/"
movies = readLines(paste0(myurl, 'movies.dat?raw=true'))
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 3, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)
colnames(movies) = c('MovieID', 'Title', 'Genres')
movies$MovieID = as.integer(movies$MovieID)
movies$Title = iconv(movies$Title, "latin1", "UTF-8")

small_image_url = "https://liangfgithub.github.io/MovieImages/"
movies$image_url = sapply(movies$MovieID, 
                          function(x) paste0(small_image_url, x, '.jpg?raw=true'))

prep_train_data = function() {
  ratings = read.csv(paste0(myurl, 'ratings.dat?raw=true'), sep=':', colClasses=c('integer','NULL'), header=FALSE)
  colnames(ratings) = c('UserID', 'MovieID', 'Rating', 'Timestamp')
  i = paste0('u', ratings$UserID)
  j = paste0('m', ratings$MovieID)
  x = ratings$Rating
  tmp = data.frame(i, j, x, stringsAsFactors = T)
  Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
  rownames(Rmat) = levels(tmp$i)
  colnames(Rmat) = levels(tmp$j)
  Rmat = new('realRatingMatrix', data = Rmat)
  return(Rmat)
}

shinyServer(function(input, output, session) {
  
  unique_genres = c()
  for (unsplit_genres in movies$Genres) {
    split_genres = strsplit(unsplit_genres[1], "|", fixed = TRUE)
    for (genresArr in split_genres) {
      for (eachGenre in genresArr) {
        if (!(eachGenre %in% unique_genres)) {
          unique_genres = append(unique_genres, eachGenre)
        } 
      }
    }
  }
  
  output$genres_dropdown <- renderUI({
    selectInput("genreDropdown", "Genre:", as.list(unique_genres))
  })
  
  transition_to_loading_state <- function() {
    useShinyjs()
    jsCode <- "document.querySelector('[data-widget=collapse]').click();"
    runjs(jsCode)
  }
  
  df_genre <- eventReactive(input$btnGenre, {
    withBusyIndicatorServer("btnGenre", {
      transition_to_loading_state()
      value_list = reactiveValuesToList(input)
      selected_genre = value_list$genreDropdown
      
      # Compute top movies by genre
      Rmat = prep_train_data()
      recom = Recommender(Rmat, method='POPULAR')
      output_ratings = as(recom@model$ratings, "matrix")
      output_topN = recom@model$topN@items[[1]]
      
      movie_list = c()
      for (i in 1:length(output_topN)) {
        if (grepl(selected_genre, movies[output_topN[i], "Genres"], fixed=TRUE) & length(movie_list) < 10) {
          movie_list = append(movie_list, output_topN[i])
        }
      }
      
      # movie_list = c(1,2,3,4,5,6,7,8,9,10)
      user_results = (1:length(movie_list))/10
      mov <- movie_list
      tit <- movies$Title[movie_list]
      
      recom_genre_results <- data.table(Rank=1:length(movie_list), MovieID=mov, 
                                        Title=tit, Predicted_rating=user_results)
    })
  })
  
  # display the recommendations
  output$results_by_genre <- renderUI({
    num_rows <- 2
    num_movies <- 5
    recom_genre_results <- df_genre()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            
            div(style = "text-align:center", 
                a(img(src = movies$image_url[recom_genre_results$MovieID[(i - 1) * num_movies + j]], height = 150))
            ),
            div(style="text-align:center; font-size: 100%", 
                strong(movies$Title[recom_genre_results$MovieID[(i - 1) * num_movies + j]])
            )
            
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function
  
  # show the movies to be rated
  output$ratings <- renderUI({
    num_rows <- 40
    num_movies <- 6 # movies per row
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        list(box(width = 2,
                 div(style = "text-align:center", img(src = movies$image_url[(i - 1) * num_movies + j], height = 150)),
                 #div(style = "text-align:center; color: #999999; font-size: 80%", books$authors[(i - 1) * num_books + j]),
                 div(style = "text-align:center", strong(movies$Title[(i - 1) * num_movies + j])),
                 div(style = "text-align:center; font-size: 150%; color: #f0ad4e;", ratingInput(paste0("select_", movies$MovieID[(i - 1) * num_movies + j]), label = "", dataStop = 5)))) #00c0ef
      })))
    })
  })
  
  # Calculate recommendations when the sbumbutton is clicked
  df <- eventReactive(input$btnRating, {
    withBusyIndicatorServer("btnRating", { # showing the busy indicator
        # hide the rating container
        useShinyjs()
        jsCode <- "document.querySelector('[data-widget=collapse]').click();"
        runjs(jsCode)
        
        # get the user's rating data
        value_list <- reactiveValuesToList(input)
        user_ratings <- get_user_ratings(value_list)
        
        ## MODEL
        Rmat = prep_train_data()
        recom = NULL
        if (length(unique(user_ratings[,Rating])) == 1) {
          recom = Recommender(Rmat, method='UBCF', parameter=list(normalize='Z-score', method='Cosine', nn=3, weighted=FALSE))
        } else {
          recom = Recommender(Rmat, method='UBCF', parameter=list(normalize='Z-score', method='Cosine', nn=20, weighted=TRUE))
        }
        
        movieIDs = colnames(Rmat)
        n.item = ncol(Rmat)  
        
        new.ratings = rep(NA, n.item)
        
        for (i in 1:dim(user_ratings)[1]) {
          index = as.numeric(user_ratings[i,MovieID])
          rating = as.numeric(user_ratings[i,Rating])
          new.ratings[index] = rating
        }

        new.user = matrix(new.ratings, nrow=1, ncol=n.item, dimnames=list(user=paste('new_user'), item=movieIDs))
        new.Rmat = as(new.user, 'realRatingMatrix')
        recom_pred = predict(recom, new.Rmat, type = 'topN')
        user_predicted_ids = unlist(recom_pred@items)
        user_results = unlist(recom_pred@ratings)
        recom_results <- data.table(Rank=1:10, MovieID=movies$MovieID[user_predicted_ids], 
                                    Title=movies$Title[user_predicted_ids], Predicted_rating=user_results)
        
    }) # still busy
    
  }) # clicked on button
  

  # display the recommendations
  output$results <- renderUI({
    num_rows <- 2
    num_movies <- 5
    recom_result <- df()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            
          div(style = "text-align:center", 
              a(img(src = movies$image_url[recom_result$MovieID[(i - 1) * num_movies + j]], height = 150))
             ),
          div(style="text-align:center; font-size: 100%", 
              strong(movies$Title[recom_result$MovieID[(i - 1) * num_movies + j]])
             )
          
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function
  
}) # server function
