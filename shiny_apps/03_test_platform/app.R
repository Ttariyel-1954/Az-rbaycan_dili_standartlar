# Test Platforması - LOKAL BAZA + QRAFIKLƏR
# RSQLite ilə offline işləyir
# 3 mətn, vizualizasiya

library(shiny)
library(shinydashboard)
library(tidyverse)
library(RPostgreSQL)
library(RSQLite)
library(DBI)
library(shinyjs)
library(jsonlite)
library(ggplot2)

# Lokal baza yarat
create_local_db <- function() {
  local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
  
  dbExecute(local_con, "
    CREATE TABLE IF NOT EXISTS students (
      student_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT,
      last_name TEXT,
      grade INTEGER,
      school_name TEXT,
      test_date TEXT
    )
  ")
  
  dbExecute(local_con, "
    CREATE TABLE IF NOT EXISTS answers (
      answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER,
      text_id INTEGER,
      text_title TEXT,
      question_number INTEGER,
      question_text TEXT,
      student_answer TEXT,
      correct_answer TEXT,
      is_correct INTEGER,
      cognitive_level TEXT
    )
  ")
  
  dbDisconnect(local_con)
}

# App başlayanda lokal baza yarat
create_local_db()

ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title = "Oxu Testi (1-4 Sinif)"),
  
  dashboardSidebar(
    useShinyjs(),
    sidebarMenu(
      id = "tabs",
      menuItem("Giriş", tabName = "start", icon = icon("user")),
      menuItem("Test", tabName = "test", icon = icon("book")),
      menuItem("Nəticələr", tabName = "result", icon = icon("chart-bar"))
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      body { font-size: 20px; }
      .login-box { 
        background: white; 
        padding: 50px; 
        border-radius: 12px; 
        margin: 30px auto; 
        max-width: 700px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.12);
      }
      .login-box input, .login-box select { 
        font-size: 22px; 
        padding: 15px; 
      }
      .login-box label { 
        font-size: 24px; 
        font-weight: 600; 
        color: #2c3e50; 
        margin-bottom: 10px;
      }
      .text-box {
        background: #fff;
        padding: 35px;
        border-radius: 12px;
        border-left: 6px solid #007bff;
        margin: 25px 0;
        box-shadow: 0 3px 10px rgba(0,0,0,0.1);
      }
      .text-box h2 { 
        color: #007bff; 
        font-size: 34px; 
        font-weight: bold; 
        margin-bottom: 25px;
      }
      .text-box p { 
        font-size: 24px; 
        line-height: 2.3; 
        color: #2c3e50;
      }
      .question-box {
        background: #f8f9fa;
        padding: 35px;
        border-radius: 12px;
        margin: 25px 0;
        border: 3px solid #dee2e6;
      }
      .question-box h3 {
        color: #28a745;
        font-size: 30px;
        font-weight: bold;
        margin-bottom: 20px;
      }
      .question-box .qtext {
        font-size: 24px;
        color: #2c3e50;
        margin: 20px 0;
        font-weight: 500;
        line-height: 1.9;
      }
      .radio label {
        font-size: 22px !important;
        padding: 14px !important;
        line-height: 1.9 !important;
      }
      .btn-big {
        font-size: 26px;
        padding: 20px 50px;
        font-weight: bold;
        border-radius: 10px;
        width: 100%;
        margin-top: 30px;
      }
      .result-card {
        background: white;
        padding: 40px;
        border-radius: 12px;
        margin: 20px 0;
        box-shadow: 0 3px 10px rgba(0,0,0,0.1);
      }
      .score-huge {
        font-size: 90px;
        font-weight: bold;
        margin: 40px 0;
      }
      .chart-box {
        background: white;
        padding: 30px;
        border-radius: 12px;
        margin: 20px 0;
      }
    "))),
    
    tabItems(
      # GİRİŞ
      tabItem(tabName = "start",
              fluidRow(
                column(12,
                       div(class = "login-box",
                           h1("Oxu Savadlılığı Testi", 
                              style="text-align:center; color:#007bff; margin-bottom:30px;"),
                           p("1-4 sinif şagirdləri üçün", 
                             style="text-align:center; color:#666; font-size:20px;"),
                           hr(),
                           textInput("name", "Adınız:", placeholder = "Adınızı yazın"),
                           textInput("surname", "Soyadınız:", placeholder = "Soyadınızı yazın"),
                           selectInput("grade", "Sinif:", 
                                       choices = c("I sinif" = "1", "II sinif" = "2", 
                                                   "III sinif" = "3", "IV sinif" = "4")),
                           textInput("school", "Məktəb:", placeholder = "Məktəbin adı"),
                           actionButton("btn_start", "Testə Başla", 
                                        class = "btn btn-primary btn-big")
                       )
                )
              )
      ),
      
      # TEST
      tabItem(tabName = "test",
              div(style="max-width:1200px; margin:0 auto;",
                  uiOutput("test_content"),
                  actionButton("btn_submit", "Testləri Bitir", 
                               class = "btn btn-success btn-big")
              )
      ),
      
      # NƏTİCƏ
      tabItem(tabName = "result",
              fluidRow(
                column(6,
                       div(class = "result-card",
                           h2("Ümumi Nəticə", style="text-align:center; color:#28a745;"),
                           uiOutput("score_display")
                       )
                ),
                column(6,
                       div(class = "result-card",
                           h2("Statistika", style="text-align:center; color:#007bff;"),
                           uiOutput("stats_display")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(class = "chart-box",
                           h2("Qrafik Təhlil", style="color:#28a745; margin-bottom:30px;"),
                           plotOutput("chart_cognitive", height = "350px"),
                           hr(),
                           plotOutput("chart_by_text", height = "350px")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(class = "result-card",
                           h2("Ətraflı Cavablar", style="color:#666;"),
                           uiOutput("detailed_feedback")
                       )
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  rv <- reactiveValues(
    student_id = NULL,
    test_data = NULL
  )
  
  # TEST BAŞLAT - 3 MƏTN SEÇ
  observeEvent(input$btn_start, {
    req(input$name, input$surname, input$grade)
    
    # PostgreSQL-dən mətnləri al
    pg_con <- dbConnect(PostgreSQL(), 
                        dbname = "azerbaijan_language_standards",
                        host = "localhost", port = 5432, 
                        user = "royatalibova")
    
    # 3 mətn seç
    rv$test_data <- dbGetQuery(pg_con, sprintf("
      WITH selected_texts AS (
        SELECT ts.sample_id, ts.title_az, ts.content_az
        FROM reading_literacy.text_samples ts
        JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
        WHERE g.grade_level = %d AND ts.sample_id IN (5,6,8,9,10,11)
        ORDER BY RANDOM()
        LIMIT 3
      )
      SELECT 
        st.sample_id, st.title_az, st.content_az,
        q.question_id, q.question_number, q.question_text,
        q.correct_answer, q.cognitive_level,
        q.options::text as options_text
      FROM selected_texts st
      JOIN assessment.questions q ON st.sample_id = q.text_sample_id
      WHERE q.question_type = 'multiple_choice'
      ORDER BY st.sample_id, q.question_number
    ", as.integer(input$grade)))
    
    dbDisconnect(pg_con)
    
    # Lokal bazada şagird yarat
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    dbExecute(local_con, sprintf("
      INSERT INTO students (first_name, last_name, grade, school_name, test_date)
      VALUES ('%s', '%s', %d, '%s', '%s')
    ", input$name, input$surname, as.integer(input$grade), 
                                 input$school, Sys.Date()))
    
    rv$student_id <- dbGetQuery(local_con, 
                                "SELECT last_insert_rowid() as id")$id
    
    dbDisconnect(local_con)
    
    updateTabItems(session, "tabs", "test")
  })
  
  # TEST MƏZMUNU - 3 MƏTN
  output$test_content <- renderUI({
    req(rv$test_data)
    
    # Mətnləri qrupla
    texts <- rv$test_data %>% 
      select(sample_id, title_az, content_az) %>% 
      distinct()
    
    test_ui <- list()
    
    for (i in 1:nrow(texts)) {
      text <- texts[i,]
      questions <- rv$test_data %>% filter(sample_id == text$sample_id)
      
      test_ui[[i]] <- tagList(
        h1(sprintf("Mətn %d / 3", i), 
           style="color:#007bff; margin:40px 0 30px 0; font-size:36px;"),
        
        # Mətn
        div(class = "text-box",
            h2(text$title_az),
            p(text$content_az)
        ),
        
        # Suallar
        lapply(1:nrow(questions), function(j) {
          q <- questions[j,]
          opts <- tryCatch({
            if (!is.na(q$options_text) && q$options_text != "") {
              fromJSON(q$options_text)
            } else {
              data.frame(option = c("A","B","C","D"), 
                         text = c("Variant A","B","C","D"))
            }
          }, error = function(e) {
            data.frame(option = c("A","B","C","D"), 
                       text = c("Variant A","B","C","D"))
          })
          
          div(class = "question-box",
              h3(sprintf("Sual %d", q$question_number)),
              div(class = "qtext", q$question_text),
              radioButtons(
                inputId = paste0("q_", q$question_id),
                label = NULL,
                choices = setNames(opts$option, 
                                   paste0(opts$option, ". ", opts$text))
              )
          )
        })
      )
    }
    
    do.call(tagList, test_ui)
  })
  
  # CAVABLARI QİYMƏTLƏNDİR
  observeEvent(input$btn_submit, {
    req(rv$test_data, rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    # Hər cavabı yoxla və yaz
    for (i in 1:nrow(rv$test_data)) {
      q <- rv$test_data[i,]
      ans <- input[[paste0("q_", q$question_id)]]
      
      if (!is.null(ans)) {
        is_correct <- (ans == q$correct_answer)
        
        dbExecute(local_con, sprintf("
          INSERT INTO answers 
          (student_id, text_id, text_title, question_number, 
           question_text, student_answer, correct_answer, 
           is_correct, cognitive_level)
          VALUES (%d, %d, '%s', %d, '%s', '%s', '%s', %d, '%s')
        ", rv$student_id, q$sample_id, 
                                     gsub("'", "''", q$title_az), q$question_number,
                                     gsub("'", "''", q$question_text), ans, q$correct_answer,
                                     as.integer(is_correct), q$cognitive_level))
      }
    }
    
    dbDisconnect(local_con)
    
    updateTabItems(session, "tabs", "result")
  })
  
  # NƏTİCƏ GÖSTƏR
  output$score_display <- renderUI({
    req(rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    total <- dbGetQuery(local_con, sprintf("
      SELECT 
        COUNT(*) as total,
        SUM(is_correct) as correct
      FROM answers WHERE student_id = %d
    ", rv$student_id))
    
    dbDisconnect(local_con)
    
    percentage <- round((total$correct / total$total) * 100, 0)
    
    color <- ifelse(percentage >= 75, "#28a745",
                    ifelse(percentage >= 60, "#ffc107", "#dc3545"))
    
    tagList(
      div(class = "score-huge", 
          style = sprintf("color:%s; text-align:center;", color),
          sprintf("%d%%", percentage)),
      h3(sprintf("%d / %d düzgün cavab", total$correct, total$total),
         style="text-align:center; color:#666; font-size:26px;")
    )
  })
  
  # STATİSTİKA
  output$stats_display <- renderUI({
    req(rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    stats <- dbGetQuery(local_con, sprintf("
      SELECT 
        cognitive_level,
        COUNT(*) as total,
        SUM(is_correct) as correct
      FROM answers 
      WHERE student_id = %d
      GROUP BY cognitive_level
    ", rv$student_id))
    
    dbDisconnect(local_con)
    
    items <- lapply(1:nrow(stats), function(i) {
      s <- stats[i,]
      pct <- round((s$correct / s$total) * 100, 0)
      
      level_az <- case_when(
        s$cognitive_level == "literal" ~ "Məlumat tapmaq",
        s$cognitive_level == "inferential" ~ "Nəticə çıxarmaq",
        s$cognitive_level == "evaluative" ~ "Qiymətləndirmək",
        TRUE ~ s$cognitive_level
      )
      
      div(style="margin:20px 0; padding:15px; background:#f8f9fa; border-radius:8px;",
          h4(level_az, style="color:#007bff; font-size:22px;"),
          p(sprintf("%d / %d (%d%%)", s$correct, s$total, pct),
            style="font-size:20px; margin:5px 0;")
      )
    })
    
    do.call(tagList, items)
  })
  
  # QRAFİK 1: Cognitive Level
  output$chart_cognitive <- renderPlot({
    req(rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    data <- dbGetQuery(local_con, sprintf("
      SELECT 
        cognitive_level,
        COUNT(*) as total,
        SUM(is_correct) as correct
      FROM answers 
      WHERE student_id = %d
      GROUP BY cognitive_level
    ", rv$student_id))
    
    dbDisconnect(local_con)
    
    data <- data %>%
      mutate(
        percentage = round((correct / total) * 100, 1),
        level_az = case_when(
          cognitive_level == "literal" ~ "Məlumat Tapmaq",
          cognitive_level == "inferential" ~ "Nəticə Çıxarmaq",
          cognitive_level == "evaluative" ~ "Qiymətləndirmək",
          TRUE ~ cognitive_level
        )
      )
    
    ggplot(data, aes(x = reorder(level_az, -percentage), y = percentage, fill = level_az)) +
      geom_col(width = 0.7) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)), 
                vjust = -0.5, size = 8, fontface = "bold") +
      scale_fill_manual(values = c("#28a745", "#007bff", "#ffc107")) +
      labs(title = "Bacarıq Səviyyələrinə görə Uğur",
           x = "", y = "Düzgün cavab (%)") +
      theme_minimal(base_size = 18) +
      theme(
        legend.position = "none",
        plot.title = element_text(size = 24, face = "bold", hjust = 0.5),
        axis.text = element_text(size = 18),
        axis.title = element_text(size = 20)
      ) +
      ylim(0, 105)
  })
  
  # QRAFİK 2: Mətnlərə görə
  output$chart_by_text <- renderPlot({
    req(rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    data <- dbGetQuery(local_con, sprintf("
      SELECT 
        text_title,
        COUNT(*) as total,
        SUM(is_correct) as correct
      FROM answers 
      WHERE student_id = %d
      GROUP BY text_title
    ", rv$student_id))
    
    dbDisconnect(local_con)
    
    data <- data %>%
      mutate(percentage = round((correct / total) * 100, 1))
    
    ggplot(data, aes(x = reorder(text_title, -percentage), y = percentage)) +
      geom_col(fill = "#007bff", width = 0.6) +
      geom_text(aes(label = sprintf("%.0f%%", percentage)), 
                vjust = -0.5, size = 8, fontface = "bold") +
      labs(title = "Mətnlərə görə Performans",
           x = "Mətn", y = "Düzgün cavab (%)") +
      theme_minimal(base_size = 18) +
      theme(
        plot.title = element_text(size = 24, face = "bold", hjust = 0.5),
        axis.text.x = element_text(angle = 15, hjust = 1, size = 16),
        axis.text.y = element_text(size = 18),
        axis.title = element_text(size = 20)
      ) +
      ylim(0, 105)
  })
  
  # ƏTRAFLIMFEEDBACK
  output$detailed_feedback <- renderUI({
    req(rv$student_id)
    
    local_con <- dbConnect(RSQLite::SQLite(), "test_results.db")
    
    answers <- dbGetQuery(local_con, sprintf("
      SELECT * FROM answers WHERE student_id = %d
      ORDER BY text_id, question_number
    ", rv$student_id))
    
    dbDisconnect(local_con)
    
    items <- lapply(1:nrow(answers), function(i) {
      a <- answers[i,]
      
      bg_color <- ifelse(a$is_correct == 1, "#d4edda", "#f8d7da")
      border_color <- ifelse(a$is_correct == 1, "#28a745", "#dc3545")
      icon_html <- ifelse(a$is_correct == 1, "✓", "✗")
      
      div(style=sprintf("background:%s; border-left:5px solid %s; 
                         padding:25px; margin:15px 0; border-radius:8px;",
                        bg_color, border_color),
          h4(sprintf("%s Sual %d - %s", icon_html, a$question_number, a$text_title),
             style="font-size:24px; margin-bottom:15px;"),
          p(strong("Sual: "), a$question_text, style="font-size:20px;"),
          p(strong("Sizin cavabınız: "), a$student_answer, style="font-size:20px;"),
          if (a$is_correct == 0) {
            p(strong("Düzgün cavab: "), a$correct_answer, 
              style="font-size:20px; color:#dc3545;")
          }
      )
    })
    
    do.call(tagList, items)
  })
}

shinyApp(ui, server)