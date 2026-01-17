# TEST TƏRTİB ETMƏ DASHBOARDU v2
# Köhnə interface + interaktiv mətn seçimi
# .rmd nömrələnmiş qeyd

library(shiny)
library(shinydashboard)
library(DBI)
library(RPostgreSQL)
library(tidyverse)
library(DT)
library(jsonlite)

get_db <- function() {
  dbConnect(PostgreSQL(), 
            dbname = "azerbaijan_language_standards",
            host = "localhost", port = 5432, 
            user = "royatalibova")
}

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "PIRLS Test Builder", titleWidth = 300),
  
  dashboardSidebar(
    width = 300,
    
    selectInput("grade", "Sinif seç:", 
                choices = c("I sinif" = 1, "II sinif" = 2, 
                            "III sinif" = 3, "IV sinif" = 4)),
    
    numericInput("num_texts", "Mətn sayı (PIRLS: 4-5):", 
                 value = 3, min = 1, max = 5),
    
    hr(),
    
    uiOutput("text_checkbox_ui"),
    
    actionButton("select_random", "🎲 Təsadüfi Seç",
                 class = "btn-warning btn-block"),
    
    hr(),
    
    actionButton("generate_preview", "👁 Preview", 
                 class = "btn-primary btn-block"),
    
    downloadButton("download_rmd", "💾 RMD Yüklə",
                   class = "btn-success btn-block"),
    
    downloadButton("download_word", "📝 Word Yüklə",
                   class = "btn-info btn-block")
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper { background: #ecf0f5; }
      .selected-text-card {
        background: white;
        padding: 25px;
        margin: 15px 0;
        border-left: 5px solid #00a65a;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        border-radius: 5px;
      }
      .text-content {
        background: #f9f9f9;
        padding: 20px;
        margin: 15px 0;
        border-left: 4px solid #3c8dbc;
        font-size: 16px;
        line-height: 1.8;
      }
      .question-item {
        background: #fff;
        padding: 15px;
        margin: 10px 0;
        border-left: 3px solid #f39c12;
        border-radius: 3px;
      }
      .question-header {
        font-weight: bold;
        color: #f39c12;
        margin-bottom: 8px;
      }
    "))),
    
    fluidRow(
      valueBoxOutput("stat_selected", width = 4),
      valueBoxOutput("stat_questions", width = 4),
      valueBoxOutput("stat_score", width = 4)
    ),
    
    fluidRow(
      box(width = 12, title = "Test Məlumatları",
          status = "info", solidHeader = TRUE, collapsible = TRUE,
          textInput("test_title", "Test başlığı:", 
                    value = "Azərbaycan dili - Oxu Savadlılığı Testi"),
          textInput("test_date", "Tarix:", 
                    value = format(Sys.Date(), "%d.%m.%Y")),
          textInput("test_institution", "Təşkilat:", 
                    value = "ARTI"),
          numericInput("test_duration", "Müddət (dəqiqə):", 
                       value = 40, min = 20, max = 90)
      )
    ),
    
    fluidRow(
      box(width = 12, title = "Seçilmiş Mətnlər və Suallar",
          status = "success", solidHeader = TRUE,
          uiOutput("selected_texts_display"))
    )
  )
)

server <- function(input, output, session) {
  
  rv <- reactiveValues(
    available_texts = NULL,
    selected_data = NULL
  )
  
  # Mətnləri yüklə
  observe({
    req(input$grade)
    
    con <- get_db()
    
    rv$available_texts <- dbGetQuery(con, sprintf("
      SELECT 
        ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
        tt.type_name_az,
        COUNT(q.question_id) as question_count
      FROM reading_literacy.text_samples ts
      JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
      LEFT JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
      LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
      WHERE g.grade_level = %d
      GROUP BY ts.sample_id, ts.title_az, ts.content_az, 
               ts.word_count, tt.type_name_az
      HAVING COUNT(q.question_id) > 0
      ORDER BY ts.sample_id
    ", as.integer(input$grade)))
    
    dbDisconnect(con)
  })
  
  # Checkbox UI
  output$text_checkbox_ui <- renderUI({
    req(rv$available_texts)
    
    choices <- setNames(
      rv$available_texts$sample_id,
      paste0(rv$available_texts$title_az, " (", 
             rv$available_texts$question_count, " sual)")
    )
    
    checkboxGroupInput("selected_text_ids", 
                       "Mətnlər seç:",
                       choices = choices)
  })
  
  # Təsadüfi seçim
  observeEvent(input$select_random, {
    req(rv$available_texts)
    
    n <- min(input$num_texts, nrow(rv$available_texts))
    random_ids <- sample(rv$available_texts$sample_id, n)
    
    updateCheckboxGroupInput(session, "selected_text_ids", 
                             selected = random_ids)
  })
  
  # Seçilmiş mətnlərin datasını yüklə
  observe({
    req(input$selected_text_ids)
    
    if (length(input$selected_text_ids) == 0) {
      rv$selected_data <- NULL
      return()
    }
    
    con <- get_db()
    
    text_ids <- paste(input$selected_text_ids, collapse = ",")
    
    rv$selected_data <- dbGetQuery(con, sprintf("
      SELECT 
        ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
        q.question_id, q.question_number, q.question_text,
        q.question_type, q.cognitive_level, q.max_score,
        q.options::text as options_json, q.correct_answer
      FROM reading_literacy.text_samples ts
      JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
      WHERE ts.sample_id IN (%s)
      ORDER BY ts.sample_id, q.question_number
    ", text_ids))
    
    dbDisconnect(con)
  })
  
  # Value boxes
  output$stat_selected <- renderValueBox({
    n <- length(input$selected_text_ids)
    
    valueBox(
      value = n,
      subtitle = "Seçilmiş Mətn",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$stat_questions <- renderValueBox({
    q <- if (is.null(rv$selected_data)) 0 else nrow(rv$selected_data)
    
    valueBox(
      value = q,
      subtitle = "Toplam Sual",
      icon = icon("question-circle"),
      color = "green"
    )
  })
  
  output$stat_score <- renderValueBox({
    score <- if (is.null(rv$selected_data)) 0 else sum(rv$selected_data$max_score)
    
    valueBox(
      value = score,
      subtitle = "Maksimum Bal",
      icon = icon("star"),
      color = "yellow"
    )
  })
  
  # Seçilmiş mətnləri göstər
  output$selected_texts_display <- renderUI({
    req(rv$selected_data)
    
    texts <- rv$selected_data %>%
      select(sample_id, title_az, content_az, word_count) %>%
      distinct()
    
    text_cards <- lapply(1:nrow(texts), function(i) {
      text <- texts[i,]
      questions <- rv$selected_data %>% filter(sample_id == text$sample_id)
      
      div(class = "selected-text-card",
          h3(sprintf("%d. %s", i, text$title_az), 
             style = "color: #00a65a; margin-bottom: 15px;"),
          
          p(strong("Söz sayı: "), text$word_count, " | ",
            strong("Sual sayı: "), nrow(questions)),
          
          div(class = "text-content",
              p(text$content_az)
          ),
          
          h4("Suallar:", style = "color: #3c8dbc; margin-top: 20px;"),
          
          lapply(1:nrow(questions), function(j) {
            q <- questions[j,]
            
            div(class = "question-item",
                div(class = "question-header",
                    sprintf("Sual %d: %s (%d bal)", 
                            q$question_number, q$question_type, q$max_score)),
                
                p(q$question_text),
                
                if (q$question_type == "multiple_choice" && !is.na(q$options_json)) {
                  opts <- fromJSON(q$options_json)
                  tagList(
                    tags$ul(
                      lapply(1:nrow(opts), function(k) {
                        tags$li(sprintf("%s. %s", opts$option[k], opts$text[k]))
                      })
                    ),
                    p(strong("Düzgün: "), q$correct_answer, style = "color: #00a65a;")
                  )
                }
            )
          })
      )
    })
    
    do.call(tagList, text_cards)
  })
  
  # RMD məzmunu
  generate_rmd <- reactive({
    req(rv$selected_data)
    
    texts <- rv$selected_data %>%
      select(sample_id, title_az, content_az) %>%
      distinct()
    
    rmd <- c(
      "---",
      sprintf("title: \"%s\"", input$test_title),
      sprintf("date: \"%s\"", input$test_date),
      "output: word_document",
      "---",
      "",
      sprintf("**Sinif:** %s | **Müddət:** %d dəqiqə", 
              c("I", "II", "III", "IV")[as.integer(input$grade)],
              input$test_duration),
      "",
      sprintf("**Təşkilat:** %s", input$test_institution),
      "",
      "---",
      "",
      "**Şagirdin adı, soyadı:** _______________________________________",
      "",
      "**Sinif:** ______  **Məktəb:** ___________________________________",
      "",
      "---",
      ""
    )
    
    for (i in 1:nrow(texts)) {
      text <- texts[i,]
      questions <- rv$selected_data %>% filter(sample_id == text$sample_id)
      
      rmd <- c(rmd,
               sprintf("\n\\newpage\n\n# Mətn %d\n", i),
               sprintf("## %s\n", text$title_az),
               sprintf("%s\n", text$content_az),
               "\n## Suallar:\n"
      )
      
      for (j in 1:nrow(questions)) {
        q <- questions[j,]
        
        rmd <- c(rmd,
                 sprintf("\n**Sual %d** (%s - %d bal)\n", 
                         q$question_number, q$question_type, q$max_score),
                 sprintf("%s\n", q$question_text)
        )
        
        if (q$question_type == "multiple_choice" && !is.na(q$options_json)) {
          opts <- fromJSON(q$options_json)
          for (k in 1:nrow(opts)) {
            rmd <- c(rmd, sprintf("- [ ] %s. %s", opts$option[k], opts$text[k]))
          }
        } else {
          rmd <- c(rmd, "\n_Cavab:_\n\n\n\n")
        }
        
        rmd <- c(rmd, "")
      }
    }
    
    paste(rmd, collapse = "\n")
  })
  
  # RMD download
  output$download_rmd <- downloadHandler(
    filename = function() {
      sprintf("test_%s_%s_%s.Rmd", 
              c("I", "II", "III", "IV")[as.integer(input$grade)],
              format(Sys.Date(), "%Y%m%d"),
              format(Sys.time(), "%H%M"))
    },
    content = function(file) {
      writeLines(generate_rmd(), file)
    }
  )
  
  # Word download
  output$download_word <- downloadHandler(
    filename = function() {
      sprintf("test_%s_%s_%s.docx", 
              c("I", "II", "III", "IV")[as.integer(input$grade)],
              format(Sys.Date(), "%Y%m%d"),
              format(Sys.time(), "%H%M"))
    },
    content = function(file) {
      rmd_file <- tempfile(fileext = ".Rmd")
      writeLines(generate_rmd(), rmd_file)
      
      rmarkdown::render(rmd_file, 
                        output_format = "word_document",
                        output_file = file,
                        quiet = TRUE)
    }
  )
  
  # Preview modal
  observeEvent(input$generate_preview, {
    req(rv$selected_data)
    
    showModal(modalDialog(
      title = "Test Preview",
      size = "l",
      easyClose = TRUE,
      
      renderUI({
        texts <- rv$selected_data %>%
          select(sample_id, title_az, content_az) %>%
          distinct()
        
        preview_html <- lapply(1:nrow(texts), function(i) {
          text <- texts[i,]
          questions <- rv$selected_data %>% filter(sample_id == text$sample_id)
          
          tagList(
            hr(),
            h3(sprintf("Mətn %d: %s", i, text$title_az)),
            p(text$content_az, style = "background: #f9f9f9; padding: 20px; line-height: 1.8;"),
            h4("Suallar:"),
            lapply(1:nrow(questions), function(j) {
              q <- questions[j,]
              p(sprintf("%d. %s (%d bal)", j, q$question_text, q$max_score))
            })
          )
        })
        
        do.call(tagList, preview_html)
      })
    ))
  })
}

shinyApp(ui, server)
