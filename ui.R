## ui.R
library(shiny)
library(shinydashboard)
library(recommenderlab)
library(data.table)
library(ShinyRatingInput)
library(shinyjs)

source('functions/helpers.R')

shinyUI(
  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "Movie Recommender"),
    dashboardSidebar(
      sidebarMenu(
        id = "tabs",
        menuItem("By Genre", icon = icon("th"), tabName = "genre"),
        menuItem("By Rating", icon = icon("star"), tabName = "rating")
      )
    ),
    dashboardBody(includeCSS("css/movies.css"),
                  tabItems(
                    tabItem(
                      tabName = "genre",
                      fluidRow(
                        box(width = 12, title = "Step 1: Select your favorite genre", status = "info", solidHeader = TRUE, collapsible = TRUE,
                            div(class = "genreitems",
                                uiOutput('genres_dropdown')
                            )
                        )
                      ),
                      fluidRow(
                        useShinyjs(),
                        box(
                          width = 12, status = "info", solidHeader = TRUE,
                          title = "Step 2: Discover movies you might like",
                          br(),
                          withBusyIndicatorUI(
                            actionButton("btnGenre", "Click here to get your recommendations", class = "btn-warning")
                          ),
                          br(),
                          tableOutput("results_by_genre")
                        )
                      )
                    ),
                    tabItem(
                      tabName = "rating",
                      fluidRow(
                        box(width = 12, title = "Step 1: Rate as many movies as possible", status = "info", solidHeader = TRUE, collapsible = TRUE,
                            div(class = "rateitems",
                                uiOutput('ratings')
                            )
                        )
                      ),
                      fluidRow(
                        useShinyjs(),
                        box(
                          width = 12, status = "info", solidHeader = TRUE,
                          title = "Step 2: Discover movies you might like",
                          br(),
                          withBusyIndicatorUI(
                            actionButton("btnRating", "Click here to get your recommendations", class = "btn-warning")
                          ),
                          br(),
                          tableOutput("results")
                        )
                      )
                    )
                  )
    )
  )
) 