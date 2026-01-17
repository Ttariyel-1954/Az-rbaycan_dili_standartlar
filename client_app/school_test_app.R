# MƏKTƏB TEST PLATFORMASI
# Offline işləyir, lokal SQLite bazası
# test_package.db faylını oxuyur

library(shiny)
library(shinydashboard)
library(RSQLite)
library(DBI)
library(tidyverse)
library(jsonlite)

# KONFIQURASIYA - paket faylı eyni qovluqda olmalıdır
TEST_PACKAGE_FILE <- "test_package.db"

ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title = "ARTI - Oxu Testi"),
  
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Başla", tabName = "start", icon = icon("play")),
      menuItem("Test", tabName = "test", icon = icon("book")),
      menuItem("Nəticə", tabName = "result", icon = icon("star"))
    ),
    
    hr(),
    
    div(style = "padding: 15px; font-size: 14px; color: #ddd;",
        icon("info-circle"), " Offline Test Sistemi",
        br(), br(),
        uiOutput("package_info")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      body { font-size: 20px; }
      .login-box { 
        background: white; padding: 50px; border-radius: 12px; 
        margin: 30px auto; max-width: 700px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.12);
      }
      .login-box input { font-size: 22px; padding: 15px; }
      .login-box label { 
        font-size: 24px; font-weight: 600; 
        color: #2c3e50; margin-bottom: 10px;
      }
      .text-box {
        background: #fff; padding: 35px; border-radius: 12px;
        border-left: 6px solid #007bff; margin: 25px 0;
        box-shadow: 0 3px 10px rgba(0,0,0,0.1);
      }
      .text-box h2 { 
        color: #007bff; font-size: 34px; 
        font-weight: bold; margin-bottom: 25px;
      }
      .text-box p { 
        font-size: 24px; line-height: 2.3; color: #2c3e50;
      }
      .question-box {
        background: #f8f9fa; padding: 35px; border-radius: 12px;
        margin: 25px 0; border: 3px solid #dee2e6;
      }
      .question-box h3 {
        color: #28a745; font-size: 30px;
        font-weight: bold; margin-bottom: 20px;
      }
      .question-box .qtext {
        font-size: 24px; color: #2c3e50;
        margin: 20px 0; font-weight: 500; line-height: 1.9;
      }
      .radio label {
        font-size: 22px !important; padding: 14px !important;
        line-height: 1.9 !important;
      }
      textarea {
        font-size: 20px !important; line-height: 1.8 !important;
      }
      .btn-big {
        font-size: 26px; padding: 20px 50px;
        font-weight: bold; border-radius: 10px;
        width: 100%; margin-top: 30px;
      }
      .result-card {
        background: white; padding: 40px; border-radius: 12px;
        margin: 20px 0; box-shadow: 0 3px 10px rgba(0,0,0,0.1);
      }
      .score-huge {
        font-size: 90px; font-weight: bold; margin: 40px 0;
      }
    "))),
    
    tabItems(
      # BAŞLA
      tabItem(tabName = "start",
              fluidRow(
                column(12,
                       div(class = "login-box",
                           h1("Oxu Savadlılığı Testi", 
                              style="text-align:center; color:#007bff; margin-bottom:30px;"),
                           uiOutput("grade_display"),
                           hr(),
                           textInput("name", "Adınız:", placeholder = "Adınızı yazın"),
                           textInput("surname", "Soyadınız:", placeholder = "Soyadınızı yazın"),
                           textInput("school", "Məktəb:", placeholder = "Məktəbin adı"),
                           textInput("class_name", "Sinif (məs: 2-A):", placeholder = "2-A"),
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
    test_data = NULL,
    package_meta = NULL
  )
  
  # Paketi yüklə
  observe({
    if (!file.exists(TEST_PACKAGE_FILE)) {
      showModal(modalDialog(
        title = "XƏTA",
        "test_package.db faylı tapılmadı! Müəllimdən paket faylını istəyin.",
        footer = NULL,
        easyClose = FALSE
      ))
      return()
    }
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    rv$package_meta <- dbGetQuery(con, "SELECT * FROM package_metadata")
    
    dbDisconnect(con)
  })
  
  # Paket info
  output$package_info <- renderUI({
    req(rv$package_meta)
    
    tagList(
      p(strong("Paket: "), rv$package_meta$package_name),
      p(strong("Mətnlər: "), rv$package_meta$num_texts),
      p(strong("Suallar: "), rv$package_meta$num_questions)
    )
  })
  
  output$grade_display <- renderUI({
    req(rv$package_meta)
    
    grade_names <- c("I sinif", "II sinif", "III sinif", "IV sinif")
    grade_name <- grade_names[rv$package_meta$grade_level]
    
    p(strong("Sinif: "), grade_name, 
      style="text-align:center; font-size:20px; color:#666;")
  })
  
  # TEST BAŞLAT
  observeEvent(input$btn_start, {
    req(input$name, input$surname)
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    # Şagird yarat
    dbExecute(con, sprintf("
      INSERT INTO students (first_name, last_name, school_name, class_name, test_date)
      VALUES ('%s', '%s', '%s', '%s', '%s')
    ", input$name, input$surname, input$school, input$class_name, Sys.Date()))
    
    rv$student_id <- dbGetQuery(con, "SELECT last_insert_rowid() as id")$id
    
    # Test data yüklə
    rv$test_data <- dbGetQuery(con, "
      SELECT 
        t.sample_id, t.title_az, t.content_az,
        q.question_id, q.question_number, q.question_text,
        q.question_type, q.cognitive_level, q.max_score,
        q.options_json, q.correct_answer, q.sample_answer
      FROM texts t
      JOIN questions q ON t.sample_id = q.text_sample_id
      ORDER BY t.sample_id, q.question_number
    ")
    
    dbDisconnect(con)
    
    updateTabItems(session, "tabs", "test")
  })
  
  # TEST MƏZMUNU
  output$test_content <- renderUI({
    req(rv$test_data)
    
    texts <- rv$test_data %>% 
      select(sample_id, title_az, content_az) %>% 
      distinct()
    
    test_ui <- list()
    
    for (i in 1:nrow(texts)) {
      text <- texts[i,]
      questions <- rv$test_data %>% filter(sample_id == text$sample_id)
      
      test_ui[[i]] <- tagList(
        h1(sprintf("Mətn %d / %d", i, nrow(texts)), 
           style="color:#007bff; margin:40px 0 30px 0; font-size:36px;"),
        
        div(class = "text-box",
            h2(text$title_az),
            p(text$content_az)
        ),
        
        lapply(1:nrow(questions), function(j) {
          q <- questions[j,]
          
          div(class = "question-box",
              h3(sprintf("Sual %d", q$question_number)),
              div(class = "qtext", q$question_text),
              
              if (q$question_type == "multiple_choice") {
                opts <- fromJSON(q$options_json)
                radioButtons(
                  inputId = paste0("q_", q$question_id),
                  label = NULL,
                  choices = setNames(opts$option, 
                                     paste0(opts$option, ". ", opts$text))
                )
              } else if (q$question_type == "short_response") {
                textAreaInput(
                  inputId = paste0("q_", q$question_id),
                  label = "Cavabınızı yazın (1-2 cümlə):",
                  rows = 3,
                  placeholder = "Buraya yazın..."
                )
              } else {
                textAreaInput(
                  inputId = paste0("q_", q$question_id),
                  label = "Cavabınızı ətraflı yazın (3-5 cümlə):",
                  rows = 6,
                  placeholder = "Buraya yazın..."
                )
              }
          )
        })
      )
    }
    
    do.call(tagList, test_ui)
  })
  
  # CAVABLARI GÖNDƏR
  observeEvent(input$btn_submit, {
    req(rv$test_data, rv$student_id)
    
    showModal(modalDialog(
      title = "Qiymətləndirilir...",
      "Cavablarınız yoxlanılır...",
      footer = NULL,
      easyClose = FALSE
    ))
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    for (i in 1:nrow(rv$test_data)) {
      q <- rv$test_data[i,]
      ans <- input[[paste0("q_", q$question_id)]]
      
      if (!is.null(ans) && ans != "") {
        
        # Qiymətləndirmə
        if (q$question_type == "multiple_choice") {
          score <- ifelse(ans == q$correct_answer, q$max_score, 0)
          feedback <- ifelse(score > 0, 
                             "✓ Düzgün!",
                             sprintf("✗ Düzgün cavab: %s", q$correct_answer))
        } else {
          # Short/Extended - müvəqqəti sadə qiymət
          score <- q$max_score * 0.7
          feedback <- "Cavabınız qəbul edildi. Müəllim yoxlayacaq."
        }
        
        dbExecute(con, sprintf("
          INSERT INTO student_answers 
          (student_id, question_id, student_answer, score, feedback, answered_at)
          VALUES (%d, %d, '%s', %.2f, '%s', '%s')
        ", rv$student_id, q$question_id, 
                               gsub("'", "''", ans), score, 
                               gsub("'", "''", feedback), Sys.time()))
      }
    }
    
    dbDisconnect(con)
    
    removeModal()
    
    updateTabItems(session, "tabs", "result")
  })
  
  # NƏTİCƏ
  output$score_display <- renderUI({
    req(rv$student_id)
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    stats <- dbGetQuery(con, sprintf("
      SELECT 
        COUNT(*) as total,
        SUM(score) as earned,
        (SELECT SUM(max_score) FROM questions) as max_score
      FROM student_answers WHERE student_id = %d
    ", rv$student_id))
    
    dbDisconnect(con)
    
    percentage <- round((stats$earned / stats$max_score) * 100, 0)
    
    color <- ifelse(percentage >= 75, "#28a745",
                    ifelse(percentage >= 60, "#ffc107", "#dc3545"))
    
    tagList(
      div(class = "score-huge", 
          style = sprintf("color:%s; text-align:center;", color),
          sprintf("%d%%", percentage)),
      h3(sprintf("%.1f / %.0f bal", stats$earned, stats$max_score),
         style="text-align:center; color:#666; font-size:26px;")
    )
  })
  
  output$stats_display <- renderUI({
    req(rv$student_id)
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    stats <- dbGetQuery(con, sprintf("
      SELECT 
        q.cognitive_level,
        COUNT(*) as total,
        SUM(sa.score) as earned,
        SUM(q.max_score) as max_score
      FROM student_answers sa
      JOIN questions q ON sa.question_id = q.question_id
      WHERE sa.student_id = %d
      GROUP BY q.cognitive_level
    ", rv$student_id))
    
    dbDisconnect(con)
    
    items <- lapply(1:nrow(stats), function(i) {
      s <- stats[i,]
      pct <- round((s$earned / s$max_score) * 100, 0)
      
      level_az <- case_when(
        s$cognitive_level == "retrieve" ~ "Məlumat tapmaq",
        s$cognitive_level == "infer" ~ "Nəticə çıxarmaq",
        s$cognitive_level == "interpret" ~ "Şərh etmək",
        s$cognitive_level == "evaluate" ~ "Qiymətləndirmək",
        TRUE ~ s$cognitive_level
      )
      
      div(style="margin:20px 0; padding:15px; background:#f8f9fa; border-radius:8px;",
          h4(level_az, style="color:#007bff; font-size:22px;"),
          p(sprintf("%.1f / %.0f (%d%%)", s$earned, s$max_score, pct),
            style="font-size:20px; margin:5px 0;")
      )
    })
    
    do.call(tagList, items)
  })
  
  output$detailed_feedback <- renderUI({
    req(rv$student_id)
    
    con <- dbConnect(RSQLite::SQLite(), TEST_PACKAGE_FILE)
    
    answers <- dbGetQuery(con, sprintf("
      SELECT 
        q.question_number, q.question_text, q.question_type,
        sa.student_answer, sa.score, q.max_score, sa.feedback
      FROM student_answers sa
      JOIN questions q ON sa.question_id = q.question_id
      WHERE sa.student_id = %d
      ORDER BY q.question_number
    ", rv$student_id))
    
    dbDisconnect(con)
    
    items <- lapply(1:nrow(answers), function(i) {
      a <- answers[i,]
      
      bg_color <- ifelse(a$score == a$max_score, "#d4edda", 
                         ifelse(a$score == 0, "#f8d7da", "#fff3cd"))
      border_color <- ifelse(a$score == a$max_score, "#28a745",
                             ifelse(a$score == 0, "#dc3545", "#ffc107"))
      
      div(style=sprintf("background:%s; border-left:5px solid %s; 
                         padding:25px; margin:15px 0; border-radius:8px;",
                        bg_color, border_color),
          h4(sprintf("Sual %d (%s)", a$question_number, a$question_type),
             style="font-size:24px; margin-bottom:15px;"),
          p(strong("Sual: "), a$question_text, style="font-size:20px;"),
          p(strong("Sizin cavabınız: "), a$student_answer, style="font-size:20px;"),
          p(strong("Bal: "), sprintf("%.1f / %.0f", a$score, a$max_score), 
            style="font-size:20px;"),
          p(strong("Feedback: "), a$feedback, style="font-size:20px; color:#666;")
      )
    })
    
    do.call(tagList, items)
  })
}

shinyApp(ui, server)