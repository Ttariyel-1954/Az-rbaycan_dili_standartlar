# Azərbaycan Dili Standartları - PISA/PIRLS Dashboard
library(shiny)
library(shinydashboard)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(DT)
library(plotly)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Azərbaycan Dili - PISA/PIRLS"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Əsas Məlumat", tabName = "overview", icon = icon("dashboard")),
      menuItem("Standartlar", tabName = "standards", icon = icon("book")),
      menuItem("Framework Mapping", tabName = "mapping", icon = icon("project-diagram")),
      menuItem("Statistika", tabName = "statistics", icon = icon("chart-bar")),
      menuItem("Mətn Nümunələri", tabName = "texts", icon = icon("file-alt"))
    )
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview",
        h2("Layihə haqqında"),
        fluidRow(
          valueBoxOutput("total_standards"),
          valueBoxOutput("total_mappings"),
          valueBoxOutput("total_frameworks")
        ),
        fluidRow(
          box(width = 12,
            title = "Layihənin məqsədi",
            solidHeader = TRUE,
            status = "primary",
            p("Bu sistem Azərbaycan dili milli kurikulumunu PISA və PIRLS beynəlxalq 
              qiymətləndirmə çərçivələrinə uyğunlaşdırır."),
            tags$ul(
              tags$li("PISA - əsas strateji hədəf"),
              tags$li("PIRLS - fundamentin ölçülməsi"),
              tags$li("CEFR və EGRA - tamamlayıcı alətlər")
            ),
            hr(),
            h4("Mövcud Məlumatlar:"),
            verbatimTextOutput("summary_stats")
          )
        )
      ),
      
      tabItem(tabName = "standards",
        h2("Kurrikulum Standartları"),
        fluidRow(
          box(width = 12,
            selectInput("content_area", "Məzmun Sahəsi:",
                       choices = c("Yüklənir..." = "")),
            DTOutput("standards_table")
          )
        )
      ),
      
      tabItem(tabName = "mapping",
        h2("PISA/PIRLS Uyğunlaşdırma"),
        fluidRow(
          box(width = 12, DTOutput("mapping_table"))
        ),
        fluidRow(
          box(width = 6, title = "Aspektlərə görə bölgü",
            plotlyOutput("aspect_distribution")),
          box(width = 6, title = "Alignment Strength",
            plotlyOutput("strength_plot"))
        )
      ),
      
      tabItem(tabName = "statistics",
        h2("Statistik Analiz"),
        fluidRow(
          box(width = 6, title = "Məzmun sahələrinə görə",
            plotlyOutput("content_area_chart")),
          box(width = 6, title = "Framework tiplərinə görə",
            plotlyOutput("framework_chart"))
        )
      ),
      
      tabItem(tabName = "texts",
        h2("Mətn Nümunələri və Tapşırıqlar"),
        fluidRow(
          box(width = 12, DTOutput("texts_table"))
        ),
        fluidRow(
          box(width = 12, title = "Generasiya olunmuş tapşırıqlar",
            DTOutput("tasks_table"))
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Məzmun sahələrini yükləyirik (bir dəfə)
  observeEvent(TRUE, {
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    areas <- dbGetQuery(con, 
      "SELECT DISTINCT content_area FROM reading_literacy.curriculum_standards 
       ORDER BY content_area")
    dbDisconnect(con)
    
    updateSelectInput(session, "content_area", 
                     choices = c("Hamısı" = "all", setNames(areas$content_area, areas$content_area)))
  }, once = TRUE)
  
  # Summary stats
  output$summary_stats <- renderText({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    
    stats <- paste0(
      "Standartlar: ", dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.curriculum_standards")[[1]], "\n",
      "Mappings: ", dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.standard_framework_mapping")[[1]], "\n",
      "Mətn nümunələri: ", dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.text_samples")[[1]], "\n",
      "Tapşırıqlar: ", dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.assessment_tasks")[[1]]
    )
    
    dbDisconnect(con)
    stats
  })
  
  # Value boxes
  output$total_standards <- renderValueBox({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    count <- dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.curriculum_standards")[[1]]
    dbDisconnect(con)
    valueBox(count, "Standart", icon = icon("book"), color = "blue")
  })
  
  output$total_mappings <- renderValueBox({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    count <- dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.standard_framework_mapping")[[1]]
    dbDisconnect(con)
    valueBox(count, "Mapping", icon = icon("link"), color = "green")
  })
  
  output$total_frameworks <- renderValueBox({
    valueBox(4, "Framework", icon = icon("globe"), color = "yellow")
  })
  
  # Standartlar cədvəli
  output$standards_table <- renderDT({
    req(input$content_area)
    
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    
    if(input$content_area == "all") {
      query <- "SELECT standard_code, content_area, standard_text_az 
                FROM reading_literacy.curriculum_standards ORDER BY standard_code"
    } else {
      query <- sprintf("SELECT standard_code, content_area, standard_text_az 
                        FROM reading_literacy.curriculum_standards 
                        WHERE content_area = '%s' ORDER BY standard_code", input$content_area)
    }
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    datatable(data, options = list(pageLength = 15),
              colnames = c("Kod", "Məzmun Sahəsi", "Standart"))
  })
  
  # Mapping cədvəli
  output$mapping_table <- renderDT({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT cs.standard_code, cs.standard_text_az, ra.aspect_code, 
              ra.aspect_name_az, sfm.alignment_strength
       FROM reading_literacy.standard_framework_mapping sfm
       JOIN reading_literacy.curriculum_standards cs ON sfm.standard_id = cs.standard_id
       JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id
       ORDER BY cs.standard_code")
    dbDisconnect(con)
    
    datatable(data, options = list(pageLength = 15),
              colnames = c("Standart", "Mətn", "Aspekt", "Aspekt adı", "Güc"))
  })
  
  # Charts
  output$aspect_distribution <- renderPlotly({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT ra.aspect_name_az, COUNT(*) as count
       FROM reading_literacy.standard_framework_mapping sfm
       JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id
       GROUP BY ra.aspect_name_az ORDER BY count DESC")
    dbDisconnect(con)
    
    plot_ly(data, x = ~aspect_name_az, y = ~count, type = 'bar',
            marker = list(color = 'rgb(26, 118, 255)')) %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Say"))
  })
  
  output$strength_plot <- renderPlotly({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT alignment_strength, COUNT(*) as count
       FROM reading_literacy.standard_framework_mapping
       GROUP BY alignment_strength")
    dbDisconnect(con)
    
    plot_ly(data, labels = ~alignment_strength, values = ~count, type = 'pie')
  })
  
  output$content_area_chart <- renderPlotly({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT content_area, COUNT(*) as count
       FROM reading_literacy.curriculum_standards
       GROUP BY content_area ORDER BY count DESC")
    dbDisconnect(con)
    
    plot_ly(data, x = ~content_area, y = ~count, type = 'bar',
            marker = list(color = 'rgb(55, 128, 191)')) %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Standart sayı"))
  })
  
  output$framework_chart <- renderPlotly({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT f.framework_name, COUNT(*) as count
       FROM reading_literacy.standard_framework_mapping sfm
       JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id
       JOIN reading_literacy.frameworks f ON ra.framework_id = f.framework_id
       GROUP BY f.framework_name")
    dbDisconnect(con)
    
    plot_ly(data, labels = ~framework_name, values = ~count, type = 'pie')
  })
  
  output$texts_table <- renderDT({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT title_az, word_count, themes FROM reading_literacy.text_samples
       WHERE source = 'Claude API - Generated'")
    dbDisconnect(con)
    
    datatable(data, options = list(pageLength = 10),
              colnames = c("Başlıq", "Söz sayı", "Temalar"))
  })
  
  output$tasks_table <- renderDT({
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    data <- dbGetQuery(con,
      "SELECT ts.title_az, ra.aspect_code, at.task_text_az, 
              at.task_type, at.difficulty_level
       FROM reading_literacy.assessment_tasks at
       JOIN reading_literacy.text_samples ts ON at.sample_id = ts.sample_id
       JOIN reading_literacy.reading_aspects ra ON at.aspect_id = ra.aspect_id")
    dbDisconnect(con)
    
    datatable(data, options = list(pageLength = 10),
              colnames = c("Mətn", "Aspekt", "Tapşırıq", "Növ", "Səviyyə"))
  })
}

shinyApp(ui, server)
