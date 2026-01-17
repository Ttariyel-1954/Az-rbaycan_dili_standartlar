# 📊 ARTI Oxu Savadlılığı - Ana Dashboard
# Bütün siniflər, mətnlər, suallar, statistika
# Author: Talıbov Tariyel İsmayıl oğlu

library(shiny)
library(shinydashboard)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(DT)
library(ggplot2)
library(scales)

# Database bağlantısı
get_db_connection <- function() {
  dbConnect(PostgreSQL(), 
            dbname = "azerbaijan_language_standards",
            host = "localhost", 
            port = 5432, 
            user = "royatalibova")
}

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "ARTI - Oxu Savadlılığı Sistemi", titleWidth = 400),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      menuItem("🏠 Ümumi Məlumat", tabName = "overview", icon = icon("home")),
      menuItem("📚 Mətnlər", tabName = "texts", icon = icon("book")),
      menuItem("❓ Suallar", tabName = "questions", icon = icon("question-circle")),
      menuItem("📊 Statistika", tabName = "stats", icon = icon("chart-bar")),
      menuItem("🎯 Test Nəticələri", tabName = "results", icon = icon("trophy"))
    ),
    
    hr(),
    
    selectInput("filter_grade", "Sinif seç:",
                choices = c("Hamısı" = "all"),
                selected = "all"),
    
    uiOutput("filter_text_ui"),
    
    hr(),
    
    div(style = "padding: 15px; font-size: 14px;",
        icon("info-circle"), 
        " ARTI - Azerbaijan Republic Education Institute",
        br(),
        "Tariyel Talıbov - 2025"
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper { background: #ecf0f5; }
      .box { border-top: 3px solid #3c8dbc; }
      .small-box h3 { font-size: 38px; font-weight: bold; }
      .small-box p { font-size: 16px; }
      .dataTables_wrapper { font-size: 16px; }
      .info-box { min-height: 100px; }
      .info-box-text { font-size: 18px; }
      .info-box-number { font-size: 30px; font-weight: bold; }
    "))),
    
    tabItems(
      # ÜMUMI MƏLUMAT
      tabItem(tabName = "overview",
              h2("📋 Sistem Ümumi Görünüşü"),
              
              fluidRow(
                valueBoxOutput("total_grades", width = 3),
                valueBoxOutput("total_texts", width = 3),
                valueBoxOutput("total_questions", width = 3),
                valueBoxOutput("total_students", width = 3)
              ),
              
              fluidRow(
                box(width = 6, title = "Sinif üzrə Mətn Paylanması", 
                    status = "primary", solidHeader = TRUE,
                    plotOutput("chart_texts_by_grade", height = "300px")
                ),
                
                box(width = 6, title = "Sinif üzrə Sual Paylanması", 
                    status = "success", solidHeader = TRUE,
                    plotOutput("chart_questions_by_grade", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Sinif üzrə Ətraflı Statistika",
                    status = "info", solidHeader = TRUE,
                    DTOutput("table_grade_stats")
                )
              )
      ),
      
      # MƏTNLƏR
      tabItem(tabName = "texts",
              h2("📚 Mətnlər Bazası"),
              
              fluidRow(
                infoBoxOutput("selected_text_count", width = 4),
                infoBoxOutput("selected_text_words", width = 4),
                infoBoxOutput("selected_text_questions", width = 4)
              ),
              
              fluidRow(
                box(width = 12, title = "Mətnlər Cədvəli",
                    status = "primary", solidHeader = TRUE,
                    DTOutput("table_texts")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Seçilmiş Mətn",
                    status = "info", solidHeader = TRUE,
                    uiOutput("text_detail")
                )
              )
      ),
      
      # SUALLAR
      tabItem(tabName = "questions",
              h2("❓ Suallar Bazası"),
              
              fluidRow(
                box(width = 3,
                    selectInput("filter_question_type", "Sual Tipi:",
                                choices = c("Hamısı" = "all"),
                                selected = "all")
                ),
                
                box(width = 3,
                    selectInput("filter_cognitive", "Cognitive Level:",
                                choices = c("Hamısı" = "all"),
                                selected = "all")
                ),
                
                box(width = 3,
                    numericInput("filter_max_score", "Min Bal:",
                                 value = 0, min = 0, max = 3)
                ),
                
                box(width = 3,
                    actionButton("apply_filters", "Filtr Tətbiq Et",
                                 class = "btn-primary btn-block",
                                 style = "margin-top: 25px;")
                )
              ),
              
              fluidRow(
                valueBoxOutput("filtered_question_count", width = 4),
                valueBoxOutput("filtered_total_score", width = 4),
                valueBoxOutput("filtered_avg_score", width = 4)
              ),
              
              fluidRow(
                box(width = 12, title = "Suallar Cədvəli",
                    status = "warning", solidHeader = TRUE,
                    DTOutput("table_questions")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Seçilmiş Sual Detayları",
                    status = "info", solidHeader = TRUE,
                    uiOutput("question_detail")
                )
              )
      ),
      
      # STATİSTİKA
      tabItem(tabName = "stats",
              h2("📊 Ətraflı Statistika və Təhlil"),
              
              fluidRow(
                box(width = 6, title = "Sual Tipləri Paylanması",
                    status = "primary", solidHeader = TRUE,
                    plotOutput("chart_question_types", height = "350px")
                ),
                
                box(width = 6, title = "Cognitive Level Paylanması",
                    status = "success", solidHeader = TRUE,
                    plotOutput("chart_cognitive_levels", height = "350px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bal Paylanması (Histogram)",
                    status = "info", solidHeader = TRUE,
                    plotOutput("chart_score_distribution", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Orta Söz Sayı (Mətnlər)",
                    status = "warning", solidHeader = TRUE,
                    plotOutput("chart_word_count", height = "300px")
                ),
                
                box(width = 6, title = "Mətn Növləri",
                    status = "danger", solidHeader = TRUE,
                    plotOutput("chart_text_types", height = "300px")
                )
              )
      ),
      
      # TEST NƏTİCƏLƏRİ
      tabItem(tabName = "results",
              h2("🎯 Test Nəticələri (RSQLite)"),
              
              fluidRow(
                valueBoxOutput("total_test_students", width = 4),
                valueBoxOutput("total_test_sessions", width = 4),
                valueBoxOutput("avg_test_score", width = 4)
              ),
              
              fluidRow(
                box(width = 12, title = "Test Nəticələri Cədvəli",
                    status = "success", solidHeader = TRUE,
                    DTOutput("table_test_results")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Performans Paylanması",
                    status = "primary", solidHeader = TRUE,
                    plotOutput("chart_performance", height = "300px")
                ),
                
                box(width = 6, title = "Sinif üzrə Orta Bal",
                    status = "info", solidHeader = TRUE,
                    plotOutput("chart_grade_performance", height = "300px")
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive values
  rv <- reactiveValues(
    grades_data = NULL,
    texts_data = NULL,
    questions_data = NULL,
    selected_text = NULL,
    selected_question = NULL
  )
  
  # Load initial data
  observe({
    con <- get_db_connection()
    
    rv$grades_data <- dbGetQuery(con, "
      SELECT * FROM reading_literacy.grades ORDER BY grade_level
    ")
    
    dbDisconnect(con)
    
    # Update grade choices
    updateSelectInput(session, "filter_grade",
                      choices = c("Hamısı" = "all",
                                  setNames(rv$grades_data$grade_level,
                                           rv$grades_data$grade_name_az)))
  })
  
  # Texts data (reactive)
  texts_data <- reactive({
    con <- get_db_connection()
    
    query <- "
      SELECT 
        ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
        g.grade_level, g.grade_name_az,
        tt.type_name_az,
        COUNT(q.question_id) as question_count
      FROM reading_literacy.text_samples ts
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      LEFT JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
      LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
    "
    
    if (input$filter_grade != "all") {
      query <- paste0(query, sprintf(" WHERE g.grade_level = %s", input$filter_grade))
    }
    
    query <- paste0(query, "
      GROUP BY ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
               g.grade_level, g.grade_name_az, tt.type_name_az
      ORDER BY g.grade_level, ts.sample_id
    ")
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    data
  })
  
  # Questions data (reactive)
  questions_data <- reactive({
    input$apply_filters  # Trigger on button click
    
    con <- get_db_connection()
    
    query <- "
      SELECT 
        q.question_id, q.text_sample_id, q.question_number, 
        q.question_text, q.question_type, q.cognitive_level,
        q.max_score, q.options, q.correct_answer, q.sample_answer,
        ts.title_az, g.grade_name_az
      FROM assessment.questions q
      JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      WHERE 1=1
    "
    
    if (input$filter_grade != "all") {
      query <- paste0(query, sprintf(" AND g.grade_level = %s", input$filter_grade))
    }
    
    if (!is.null(input$filter_text) && input$filter_text != "all") {
      query <- paste0(query, sprintf(" AND ts.sample_id = %s", input$filter_text))
    }
    
    if (input$filter_question_type != "all") {
      query <- paste0(query, sprintf(" AND q.question_type = '%s'", input$filter_question_type))
    }
    
    if (input$filter_cognitive != "all") {
      query <- paste0(query, sprintf(" AND q.cognitive_level = '%s'", input$filter_cognitive))
    }
    
    if (input$filter_max_score > 0) {
      query <- paste0(query, sprintf(" AND q.max_score >= %d", input$filter_max_score))
    }
    
    query <- paste0(query, " ORDER BY q.text_sample_id, q.question_number")
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    data
  })
  
  # Dynamic text filter
  output$filter_text_ui <- renderUI({
    req(texts_data())
    
    choices <- c("Hamısı" = "all",
                 setNames(texts_data()$sample_id, 
                          paste0(texts_data()$title_az, " (", texts_data()$grade_name_az, ")")))
    
    selectInput("filter_text", "Mətn seç:",
                choices = choices,
                selected = "all")
  })
  
  # Update question type choices
  observe({
    con <- get_db_connection()
    
    types <- dbGetQuery(con, "
      SELECT DISTINCT question_type FROM assessment.questions ORDER BY question_type
    ")
    
    dbDisconnect(con)
    
    updateSelectInput(session, "filter_question_type",
                      choices = c("Hamısı" = "all", types$question_type))
  })
  
  # Update cognitive level choices
  observe({
    con <- get_db_connection()
    
    levels <- dbGetQuery(con, "
      SELECT DISTINCT cognitive_level FROM assessment.questions ORDER BY cognitive_level
    ")
    
    dbDisconnect(con)
    
    updateSelectInput(session, "filter_cognitive",
                      choices = c("Hamısı" = "all", levels$cognitive_level))
  })
  
  # VALUE BOXES - Overview
  output$total_grades <- renderValueBox({
    valueBox(
      value = 4,
      subtitle = "Sinif Sayı",
      icon = icon("graduation-cap"),
      color = "blue"
    )
  })
  
  output$total_texts <- renderValueBox({
    con <- get_db_connection()
    count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM reading_literacy.text_samples")$n
    dbDisconnect(con)
    
    valueBox(
      value = count,
      subtitle = "Mətn Sayı",
      icon = icon("book"),
      color = "green"
    )
  })
  
  output$total_questions <- renderValueBox({
    con <- get_db_connection()
    count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM assessment.questions")$n
    dbDisconnect(con)
    
    valueBox(
      value = count,
      subtitle = "Sual Sayı",
      icon = icon("question-circle"),
      color = "yellow"
    )
  })
  
  output$total_students <- renderValueBox({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      count <- dbGetQuery(local_con, "SELECT COUNT(*) as n FROM students")$n
      dbDisconnect(local_con)
      
      valueBox(
        value = count,
        subtitle = "Test Edilmiş Şagird",
        icon = icon("users"),
        color = "red"
      )
    }, error = function(e) {
      valueBox(value = 0, subtitle = "Test Edilmiş Şagird", 
               icon = icon("users"), color = "red")
    })
  })
  
  # CHARTS - Overview
  output$chart_texts_by_grade <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT g.grade_name_az, COUNT(*) as count
      FROM reading_literacy.text_samples ts
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      GROUP BY g.grade_level, g.grade_name_az
      ORDER BY g.grade_level
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = grade_name_az, y = count, fill = grade_name_az)) +
      geom_col() +
      geom_text(aes(label = count), vjust = -0.5, size = 6, fontface = "bold") +
      scale_fill_brewer(palette = "Set2") +
      labs(x = "", y = "Mətn Sayı") +
      theme_minimal(base_size = 16) +
      theme(legend.position = "none",
            axis.text = element_text(size = 14))
  })
  
  output$chart_questions_by_grade <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT g.grade_name_az, COUNT(*) as count
      FROM assessment.questions q
      JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      GROUP BY g.grade_level, g.grade_name_az
      ORDER BY g.grade_level
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = grade_name_az, y = count, fill = grade_name_az)) +
      geom_col() +
      geom_text(aes(label = count), vjust = -0.5, size = 6, fontface = "bold") +
      scale_fill_brewer(palette = "Set1") +
      labs(x = "", y = "Sual Sayı") +
      theme_minimal(base_size = 16) +
      theme(legend.position = "none",
            axis.text = element_text(size = 14))
  })
  
  # TABLE - Grade stats
  output$table_grade_stats <- renderDT({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT 
        g.grade_name_az as \"Sinif\",
        COUNT(DISTINCT ts.sample_id) as \"Mətn Sayı\",
        COUNT(q.question_id) as \"Sual Sayı\",
        SUM(q.max_score) as \"Maksimum Bal\"
      FROM reading_literacy.grades g
      LEFT JOIN reading_literacy.text_samples ts ON g.grade_id = ts.grade_id
      LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
      GROUP BY g.grade_level, g.grade_name_az
      ORDER BY g.grade_level
    ")
    
    dbDisconnect(con)
    
    datatable(data, options = list(pageLength = 10, dom = 't'),
              rownames = FALSE)
  })
  
  # TEXTS TAB
  output$selected_text_count <- renderInfoBox({
    infoBox(
      "Mətn Sayı",
      nrow(texts_data()),
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$selected_text_words <- renderInfoBox({
    avg_words <- round(mean(texts_data()$word_count, na.rm = TRUE), 0)
    
    infoBox(
      "Orta Söz Sayı",
      avg_words,
      icon = icon("font"),
      color = "green"
    )
  })
  
  output$selected_text_questions <- renderInfoBox({
    total_q <- sum(texts_data()$question_count, na.rm = TRUE)
    
    infoBox(
      "Toplam Sual",
      total_q,
      icon = icon("question-circle"),
      color = "yellow"
    )
  })
  
  output$table_texts <- renderDT({
    data <- texts_data() %>%
      select(`ID` = sample_id,
             `Sinif` = grade_name_az,
             `Başlıq` = title_az,
             `Söz Sayı` = word_count,
             `Növ` = type_name_az,
             `Sual Sayı` = question_count)
    
    datatable(data, 
              selection = 'single',
              options = list(pageLength = 15, scrollX = TRUE),
              rownames = FALSE)
  })
  
  output$text_detail <- renderUI({
    req(input$table_texts_rows_selected)
    
    selected_row <- texts_data()[input$table_texts_rows_selected, ]
    
    tagList(
      h3(selected_row$title_az, style = "color: #3c8dbc;"),
      p(strong("Sinif: "), selected_row$grade_name_az),
      p(strong("Söz Sayı: "), selected_row$word_count),
      p(strong("Növ: "), selected_row$type_name_az),
      p(strong("Sual Sayı: "), selected_row$question_count),
      hr(),
      h4("Mətn:"),
      div(style = "background: #f4f4f4; padding: 20px; border-left: 4px solid #3c8dbc; 
                   line-height: 1.8; font-size: 16px;",
          selected_row$content_az)
    )
  })
  
  # QUESTIONS TAB
  output$filtered_question_count <- renderValueBox({
    valueBox(
      value = nrow(questions_data()),
      subtitle = "Sual Sayı",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$filtered_total_score <- renderValueBox({
    total <- sum(questions_data()$max_score, na.rm = TRUE)
    
    valueBox(
      value = total,
      subtitle = "Toplam Bal",
      icon = icon("star"),
      color = "yellow"
    )
  })
  
  output$filtered_avg_score <- renderValueBox({
    avg <- round(mean(questions_data()$max_score, na.rm = TRUE), 1)
    
    valueBox(
      value = avg,
      subtitle = "Orta Bal",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$table_questions <- renderDT({
    data <- questions_data() %>%
      select(`ID` = question_id,
             `Mətn` = title_az,
             `Sinif` = grade_name_az,
             `№` = question_number,
             `Sual` = question_text,
             `Tip` = question_type,
             `Level` = cognitive_level,
             `Bal` = max_score)
    
    datatable(data,
              selection = 'single',
              options = list(pageLength = 15, scrollX = TRUE),
              rownames = FALSE)
  })
  
  output$question_detail <- renderUI({
    req(input$table_questions_rows_selected)
    
    q <- questions_data()[input$table_questions_rows_selected, ]
    
    tagList(
      h3(sprintf("Sual %d - %s", q$question_number, q$title_az), 
         style = "color: #3c8dbc;"),
      p(strong("Tip: "), q$question_type),
      p(strong("Cognitive Level: "), q$cognitive_level),
      p(strong("Maksimum Bal: "), q$max_score),
      hr(),
      h4("Sual:"),
      div(style = "background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; 
                   font-size: 18px; line-height: 1.6;",
          q$question_text),
      
      if (q$question_type == "multiple_choice" && !is.na(q$options)) {
        tagList(
          h4("Variantlar:", style = "margin-top: 20px;"),
          renderPrint({
            opts <- fromJSON(q$options)
            for (i in 1:nrow(opts)) {
              cat(sprintf("%s. %s\n", opts$option[i], opts$text[i]))
            }
            cat(sprintf("\n✓ Düzgün cavab: %s\n", q$correct_answer))
          })
        )
      },
      
      if (!is.na(q$sample_answer) && q$sample_answer != "") {
        tagList(
          h4("Nümunə Cavab:", style = "margin-top: 20px;"),
          div(style = "background: #d4edda; padding: 15px; border-left: 4px solid #28a745;
                       font-size: 16px; line-height: 1.6;",
              q$sample_answer)
        )
      }
    )
  })
  
  # STATISTICS TAB
  output$chart_question_types <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT question_type, COUNT(*) as count
      FROM assessment.questions
      GROUP BY question_type
      ORDER BY count DESC
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = reorder(question_type, -count), y = count, fill = question_type)) +
      geom_col() +
      geom_text(aes(label = count), vjust = -0.5, size = 6, fontface = "bold") +
      scale_fill_brewer(palette = "Set3") +
      labs(x = "", y = "Say", title = "") +
      theme_minimal(base_size = 16) +
      theme(legend.position = "none",
            axis.text.x = element_text(angle = 20, hjust = 1))
  })
  
  output$chart_cognitive_levels <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT cognitive_level, COUNT(*) as count
      FROM assessment.questions
      GROUP BY cognitive_level
      ORDER BY count DESC
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = reorder(cognitive_level, -count), y = count, fill = cognitive_level)) +
      geom_col() +
      geom_text(aes(label = count), vjust = -0.5, size = 6, fontface = "bold") +
      scale_fill_brewer(palette = "Pastel1") +
      labs(x = "", y = "Say", title = "") +
      theme_minimal(base_size = 16) +
      theme(legend.position = "none")
  })
  
  output$chart_score_distribution <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "SELECT max_score FROM assessment.questions")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = max_score)) +
      geom_histogram(binwidth = 1, fill = "#3c8dbc", color = "white") +
      scale_x_continuous(breaks = 0:3) +
      labs(x = "Maksimum Bal", y = "Sual Sayı", title = "") +
      theme_minimal(base_size = 16)
  })
  
  output$chart_word_count <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT g.grade_name_az, AVG(ts.word_count) as avg_words
      FROM reading_literacy.text_samples ts
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      GROUP BY g.grade_level, g.grade_name_az
      ORDER BY g.grade_level
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = grade_name_az, y = avg_words, fill = grade_name_az)) +
      geom_col() +
      geom_text(aes(label = round(avg_words, 0)), vjust = -0.5, size = 6, fontface = "bold") +
      scale_fill_brewer(palette = "Blues") +
      labs(x = "", y = "Orta Söz Sayı", title = "") +
      theme_minimal(base_size = 16) +
      theme(legend.position = "none")
  })
  
  output$chart_text_types <- renderPlot({
    con <- get_db_connection()
    
    data <- dbGetQuery(con, "
      SELECT tt.type_name_az, COUNT(*) as count
      FROM reading_literacy.text_samples ts
      LEFT JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
      GROUP BY tt.type_name_az
      ORDER BY count DESC
    ")
    
    dbDisconnect(con)
    
    ggplot(data, aes(x = "", y = count, fill = type_name_az)) +
      geom_col(width = 1) +
      coord_polar("y") +
      scale_fill_brewer(palette = "Set2") +
      labs(fill = "Növ", title = "") +
      theme_void(base_size = 14) +
      theme(legend.position = "right")
  })
  
  # TEST RESULTS TAB
  output$total_test_students <- renderValueBox({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      count <- dbGetQuery(local_con, "SELECT COUNT(DISTINCT student_id) as n FROM students")$n
      dbDisconnect(local_con)
      
      valueBox(value = count, subtitle = "Şagird", 
               icon = icon("user"), color = "blue")
    }, error = function(e) {
      valueBox(value = 0, subtitle = "Şagird", 
               icon = icon("user"), color = "blue")
    })
  })
  
  output$total_test_sessions <- renderValueBox({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      count <- dbGetQuery(local_con, "SELECT COUNT(*) as n FROM answers")$n
      dbDisconnect(local_con)
      
      valueBox(value = count, subtitle = "Cavablandırılmış Sual", 
               icon = icon("check"), color = "green")
    }, error = function(e) {
      valueBox(value = 0, subtitle = "Cavablandırılmış Sual", 
               icon = icon("check"), color = "green")
    })
  })
  
  output$avg_test_score <- renderValueBox({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      avg <- dbGetQuery(local_con, "
        SELECT ROUND(AVG(is_correct) * 100, 1) as avg 
        FROM answers
      ")$avg
      dbDisconnect(local_con)
      
      valueBox(value = sprintf("%.1f%%", avg), subtitle = "Orta Uğur", 
               icon = icon("star"), color = "yellow")
    }, error = function(e) {
      valueBox(value = "N/A", subtitle = "Orta Uğur", 
               icon = icon("star"), color = "yellow")
    })
  })
  
  output$table_test_results <- renderDT({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      
      data <- dbGetQuery(local_con, "
        SELECT 
          s.first_name || ' ' || s.last_name as \"Şagird\",
          s.grade as \"Sinif\",
          s.test_date as \"Tarix\",
          COUNT(a.answer_id) as \"Cavablar\",
          SUM(a.is_correct) as \"Düzgün\",
          ROUND(AVG(a.is_correct) * 100, 1) as \"Faiz\"
        FROM students s
        LEFT JOIN answers a ON s.student_id = a.student_id
        GROUP BY s.student_id
        ORDER BY s.test_date DESC
      ")
      
      dbDisconnect(local_con)
      
      datatable(data, options = list(pageLength = 15), rownames = FALSE)
    }, error = function(e) {
      data.frame(Mesaj = "Test nəticələri yoxdur")
    })
  })
  
  output$chart_performance <- renderPlot({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      
      data <- dbGetQuery(local_con, "
        SELECT 
          CASE 
            WHEN AVG(is_correct) >= 0.9 THEN '90-100%'
            WHEN AVG(is_correct) >= 0.75 THEN '75-89%'
            WHEN AVG(is_correct) >= 0.60 THEN '60-74%'
            ELSE '<60%'
          END as range,
          COUNT(*) as count
        FROM (
          SELECT student_id, AVG(is_correct) as avg
          FROM answers
          GROUP BY student_id
        )
        GROUP BY range
      ")
      
      dbDisconnect(local_con)
      
      ggplot(data, aes(x = range, y = count, fill = range)) +
        geom_col() +
        geom_text(aes(label = count), vjust = -0.5, size = 6) +
        scale_fill_brewer(palette = "RdYlGn") +
        labs(x = "Uğur Aralığı", y = "Şagird Sayı") +
        theme_minimal(base_size = 16) +
        theme(legend.position = "none")
    }, error = function(e) {
      ggplot() + theme_void() + 
        geom_text(aes(x = 0, y = 0, label = "Məlumat yoxdur"), size = 8)
    })
  })
  
  output$chart_grade_performance <- renderPlot({
    tryCatch({
      local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
      
      data <- dbGetQuery(local_con, "
        SELECT 
          s.grade,
          ROUND(AVG(a.is_correct) * 100, 1) as avg_score
        FROM students s
        LEFT JOIN answers a ON s.student_id = a.student_id
        GROUP BY s.grade
        ORDER BY s.grade
      ")
      
      dbDisconnect(local_con)
      
      data$grade_name <- paste0(c("I", "II", "III", "IV")[data$grade], " sinif")
      
      ggplot(data, aes(x = grade_name, y = avg_score, fill = grade_name)) +
        geom_col() +
        geom_text(aes(label = sprintf("%.1f%%", avg_score)), vjust = -0.5, size = 6) +
        scale_fill_brewer(palette = "Set3") +
        labs(x = "", y = "Orta Uğur (%)") +
        theme_minimal(base_size = 16) +
        theme(legend.position = "none") +
        ylim(0, 110)
    }, error = function(e) {
      ggplot() + theme_void() + 
        geom_text(aes(x = 0, y = 0, label = "Məlumat yoxdur"), size = 8)
    })
  })
}

shinyApp(ui, server)
