# ═══════════════════════════════════════════════════════════
# POSTGRESQL BAZA ANALİZ DASHBOARD
# Müəllif: ARTI
# Tarix: 2025
# ═══════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)
library(plotly)
library(RPostgreSQL)
library(dplyr)
library(tidyr)
library(jsonlite)
library(htmltools)
library(markdown)

# ═══════════════════════════════════════════════════════════
# BAZA QOŞULMASI
# ═══════════════════════════════════════════════════════════

get_db_connection <- function() {
  tryCatch({
    dbConnect(
      PostgreSQL(),
      dbname = "azerbaijan_language_standards",
      host = "localhost",
      port = 5432,
      user = "royatalibova",
      password = ""
    )
  }, error = function(e) {
    showNotification(paste("Baza qoşulma xətası:", e$message), type = "error")
    NULL
  })
}

# ═══════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════

ui <- dashboardPage(
  skin = "blue",
  
  # ─────────────────────────────────────────────────────────
  # HEADER
  # ─────────────────────────────────────────────────────────
  dashboardHeader(
    title = "📊 PIRLS Baza Analizi",
    titleWidth = 300
  ),
  
  # ─────────────────────────────────────────────────────────
  # SIDEBAR
  # ─────────────────────────────────────────────────────────
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      menuItem("🏠 Ümumi Məlumat", tabName = "overview", icon = icon("home")),
      menuItem("📚 Mətn Siyahısı", tabName = "texts", icon = icon("book")),
      menuItem("❓ Sual Təhlili", tabName = "questions", icon = icon("question-circle")),
      menuItem("📖 Mətn Oxu", tabName = "reader", icon = icon("book-reader")),
      menuItem("📊 Statistika", tabName = "stats", icon = icon("chart-bar")),
      menuItem("🔍 Axtarış", tabName = "search", icon = icon("search")),
      menuItem("⚙️ Baza Strukturu", tabName = "structure", icon = icon("database"))
    )
  ),
  
  # ─────────────────────────────────────────────────────────
  # BODY
  # ─────────────────────────────────────────────────────────
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top: 3px solid #3c8dbc; }
        .small-box { border-radius: 5px; }
        .text-preview { 
          max-height: 400px; 
          overflow-y: auto; 
          padding: 15px;
          background: white;
          border: 1px solid #ddd;
          border-radius: 5px;
          font-family: 'Arial', sans-serif;
          line-height: 1.6;
        }
        .question-box {
          padding: 15px;
          margin: 10px 0;
          border-left: 4px solid #3c8dbc;
          background: #f9f9f9;
        }
        .stat-box {
          text-align: center;
          padding: 20px;
        }
      "))
    ),
    
    tabItems(
      # ══════════════════════════════════════════════════════════
      # TAB 1: ÜMUMİ MƏLUMAT
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "overview",
        h2("📊 Ümumi Baza Məlumatları"),
        
        fluidRow(
          valueBoxOutput("total_texts", width = 3),
          valueBoxOutput("total_questions", width = 3),
          valueBoxOutput("total_words", width = 3),
          valueBoxOutput("avg_questions", width = 3)
        ),
        
        fluidRow(
          box(
            title = "📈 Mətn Növlərinə Görə Bölgü",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("text_type_plot", height = 300)
          ),
          box(
            title = "📊 Sual Tiplərinə Görə Bölgü",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("question_type_plot", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "📚 Son Əlavə Edilən Mətnlər",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("recent_texts")
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 2: MƏTN SİYAHISI
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "texts",
        h2("📚 Bütün Mətnlər"),
        
        fluidRow(
          box(
            title = "Filtrlər",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(4, selectInput("filter_text_type", "Mətn Növü:", choices = NULL)),
              column(4, selectInput("filter_grade", "Sinif:", choices = NULL)),
              column(4, sliderInput("filter_words", "Söz Sayı:", 
                                   min = 0, max = 1000, value = c(0, 1000)))
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Mətn Cədvəli",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("texts_table")
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 3: SUAL TƏHLİLİ
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "questions",
        h2("❓ Sual Təhlili"),
        
        fluidRow(
          box(
            title = "Mətn Seç",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            selectInput("select_text_questions", "Mətn:", choices = NULL, width = "100%")
          )
        ),
        
        fluidRow(
          valueBoxOutput("q_total", width = 3),
          valueBoxOutput("q_mc", width = 3),
          valueBoxOutput("q_open", width = 3),
          valueBoxOutput("q_points", width = 3)
        ),
        
        fluidRow(
          box(
            title = "📊 Sual Bölgüsü",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("question_distribution", height = 300)
          ),
          box(
            title = "🎯 Bal Bölgüsü",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("score_distribution", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "Suallar",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            uiOutput("questions_display")
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 4: MƏTN OXU
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "reader",
        h2("📖 Mətn Oxuyucu"),
        
        fluidRow(
          box(
            title = "Mətn Seç",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            selectInput("select_text_reader", "Mətn:", choices = NULL, width = "100%")
          )
        ),
        
        fluidRow(
          box(
            title = "Mətn Məlumatları",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            htmlOutput("text_metadata")
          )
        ),
        
        fluidRow(
          box(
            title = "Mətn Məzmunu",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            htmlOutput("text_content")
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 5: STATİSTİKA
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "stats",
        h2("📊 Ətraflı Statistika"),
        
        fluidRow(
          box(
            title = "📏 Söz Sayı Statistikası",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("word_count_stats", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "📊 Mətnlərə Görə Sual Sayı",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("questions_per_text", height = 400)
          ),
          box(
            title = "🎯 Mətnlərə Görə Ümumi Bal",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("points_per_text", height = 400)
          )
        ),
        
        fluidRow(
          box(
            title = "📈 Mətn Əlavə Edilmə Tarixi",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("creation_timeline", height = 300)
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 6: AXTARIŞ
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "search",
        h2("🔍 Mətn və Sual Axtarışı"),
        
        fluidRow(
          box(
            title = "Axtarış",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            textInput("search_query", "Açar söz:", placeholder = "Mətn və ya sual içində axtar..."),
            actionButton("search_btn", "Axtar", icon = icon("search"), class = "btn-primary")
          )
        ),
        
        fluidRow(
          box(
            title = "Axtarış Nəticələri",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("search_results")
          )
        )
      ),
      
      # ══════════════════════════════════════════════════════════
      # TAB 7: BAZA STRUKTURU
      # ══════════════════════════════════════════════════════════
      tabItem(
        tabName = "structure",
        h2("⚙️ Baza Strukturu"),
        
        fluidRow(
          box(
            title = "📋 Cədvəllər",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            DTOutput("tables_list")
          ),
          box(
            title = "📊 Cədvəl Ölçüləri",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("table_sizes", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "🔧 text_samples Strukturu",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            DTOutput("text_samples_structure")
          ),
          box(
            title = "🔧 questions Strukturu",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            DTOutput("questions_structure")
          )
        )
      )
    )
  )
)

# ═══════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════

server <- function(input, output, session) {
  
  # ─────────────────────────────────────────────────────────
  # REACTIVE DATA
  # ─────────────────────────────────────────────────────────
  
  texts_data <- reactive({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT 
        ts.sample_id,
        ts.title_az,
        ts.word_count,
        ts.grade_id,
        ts.text_type_id,
        tt.type_name_az as text_type,
        ts.created_at,
        COUNT(q.question_id) as question_count,
        SUM(q.max_score) as total_points
      FROM reading_literacy.text_samples ts
      LEFT JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.type_id
      LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
      WHERE ts.grade_id = 4
      GROUP BY ts.sample_id, ts.title_az, ts.word_count, ts.grade_id, 
               ts.text_type_id, tt.type_name_az, ts.created_at
      ORDER BY ts.sample_id DESC
    "
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    data
  })
  
  questions_data <- reactive({
    req(input$select_text_questions)
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- sprintf("
      SELECT 
        question_id,
        question_number,
        question_text,
        question_type,
        max_score,
        options,
        correct_answer
      FROM assessment.questions
      WHERE text_sample_id = %d
      ORDER BY question_number
    ", as.integer(input$select_text_questions))
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    data
  })
  
  # ─────────────────────────────────────────────────────────
  # UPDATE INPUTS
  # ─────────────────────────────────────────────────────────
  
  observe({
    data <- texts_data()
    if (!is.null(data)) {
      # Update filters
      updateSelectInput(session, "filter_text_type", 
                       choices = c("Hamısı" = "", unique(data$text_type)))
      updateSelectInput(session, "filter_grade",
                       choices = c("Hamısı" = "", unique(data$grade_id)))
      
      # Update text selectors
      choices <- setNames(data$sample_id, paste0(data$sample_id, ": ", data$title_az))
      updateSelectInput(session, "select_text_questions", choices = choices)
      updateSelectInput(session, "select_text_reader", choices = choices)
    }
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 1: ÜMUMİ MƏLUMAT
  # ─────────────────────────────────────────────────────────
  
  output$total_texts <- renderValueBox({
    data <- texts_data()
    valueBox(
      nrow(data),
      "Mətn",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$total_questions <- renderValueBox({
    data <- texts_data()
    valueBox(
      sum(data$question_count, na.rm = TRUE),
      "Sual",
      icon = icon("question-circle"),
      color = "green"
    )
  })
  
  output$total_words <- renderValueBox({
    data <- texts_data()
    valueBox(
      format(sum(data$word_count, na.rm = TRUE), big.mark = ","),
      "Söz",
      icon = icon("font"),
      color = "yellow"
    )
  })
  
  output$avg_questions <- renderValueBox({
    data <- texts_data()
    valueBox(
      round(mean(data$question_count, na.rm = TRUE), 1),
      "Orta Sual/Mətn",
      icon = icon("chart-line"),
      color = "red"
    )
  })
  
  output$text_type_plot <- renderPlotly({
    data <- texts_data()
    type_counts <- data %>%
      group_by(text_type) %>%
      summarise(count = n())
    
    plot_ly(type_counts, labels = ~text_type, values = ~count, type = 'pie',
            textinfo = 'label+percent',
            marker = list(colors = c('#3c8dbc', '#00a65a', '#f39c12'))) %>%
      layout(showlegend = TRUE)
  })
  
  output$question_type_plot <- renderPlotly({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT question_type, COUNT(*) as count
      FROM assessment.questions q
      JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
      WHERE ts.grade_id = 4
      GROUP BY question_type
    "
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    plot_ly(data, x = ~question_type, y = ~count, type = 'bar',
            marker = list(color = c('#3c8dbc', '#00a65a'))) %>%
      layout(xaxis = list(title = "Sual Tipi"),
             yaxis = list(title = "Say"))
  })
  
  output$recent_texts <- renderDT({
    data <- texts_data()
    data %>%
      select(sample_id, title_az, word_count, text_type, question_count, total_points) %>%
      head(10) %>%
      datatable(
        colnames = c("ID", "Başlıq", "Söz", "Növ", "Sual", "Bal"),
        options = list(pageLength = 10, dom = 't')
      )
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 2: MƏTN SİYAHISI
  # ─────────────────────────────────────────────────────────
  
  filtered_texts <- reactive({
    data <- texts_data()
    
    if (input$filter_text_type != "") {
      data <- data %>% filter(text_type == input$filter_text_type)
    }
    if (input$filter_grade != "") {
      data <- data %>% filter(grade_id == as.integer(input$filter_grade))
    }
    data <- data %>% filter(word_count >= input$filter_words[1], 
                           word_count <= input$filter_words[2])
    data
  })
  
  output$texts_table <- renderDT({
    filtered_texts() %>%
      select(sample_id, title_az, word_count, text_type, question_count, total_points) %>%
      datatable(
        colnames = c("ID", "Başlıq", "Söz Sayı", "Növ", "Sual Sayı", "Ümumi Bal"),
        options = list(pageLength = 25),
        filter = 'top'
      )
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 3: SUAL TƏHLİLİ
  # ─────────────────────────────────────────────────────────
  
  output$q_total <- renderValueBox({
    data <- questions_data()
    valueBox(
      nrow(data),
      "Cəmi Sual",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$q_mc <- renderValueBox({
    data <- questions_data()
    mc_count <- sum(data$question_type == "multiple_choice", na.rm = TRUE)
    valueBox(
      mc_count,
      "Qapalı",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$q_open <- renderValueBox({
    data <- questions_data()
    open_count <- sum(data$question_type == "open_response", na.rm = TRUE)
    valueBox(
      open_count,
      "Açıq",
      icon = icon("pen"),
      color = "yellow"
    )
  })
  
  output$q_points <- renderValueBox({
    data <- questions_data()
    valueBox(
      sum(data$max_score, na.rm = TRUE),
      "Ümumi Bal",
      icon = icon("award"),
      color = "red"
    )
  })
  
  output$question_distribution <- renderPlotly({
    data <- questions_data()
    type_counts <- data %>%
      group_by(question_type) %>%
      summarise(count = n())
    
    plot_ly(type_counts, labels = ~question_type, values = ~count, type = 'pie') %>%
      layout(showlegend = TRUE)
  })
  
  output$score_distribution <- renderPlotly({
    data <- questions_data()
    
    plot_ly(data, x = ~question_number, y = ~max_score, type = 'bar',
            color = ~question_type) %>%
      layout(xaxis = list(title = "Sual №"),
             yaxis = list(title = "Bal"))
  })
  
  output$questions_display <- renderUI({
    data <- questions_data()
    
    lapply(1:nrow(data), function(i) {
      q <- data[i, ]
      
      div(class = "question-box",
          h4(paste("Sual", q$question_number, "-", 
                   ifelse(q$question_type == "multiple_choice", "Qapalı", "Açıq"),
                   "(", q$max_score, "bal)")),
          p(strong(q$question_text)),
          if (q$question_type == "multiple_choice" && !is.na(q$options)) {
            tryCatch({
              opts <- fromJSON(q$options)
              div(
                lapply(opts, function(opt) {
                  p(paste(opt$option, "-", opt$text),
                    style = if(opt$option == q$correct_answer) 
                      "color: green; font-weight: bold;" else "")
                })
              )
            }, error = function(e) NULL)
          }
      )
    })
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 4: MƏTN OXU
  # ─────────────────────────────────────────────────────────
  
  text_full_data <- reactive({
    req(input$select_text_reader)
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- sprintf("
      SELECT 
        ts.*,
        tt.type_name_az as text_type_name
      FROM reading_literacy.text_samples ts
      LEFT JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.type_id
      WHERE ts.sample_id = %d
    ", as.integer(input$select_text_reader))
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    data
  })
  
  output$text_metadata <- renderUI({
    data <- text_full_data()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    HTML(sprintf("
      <div style='padding: 15px; background: #f9f9f9; border-radius: 5px;'>
        <h3>%s</h3>
        <p><strong>ID:</strong> %d | <strong>Sinif:</strong> %d | <strong>Növ:</strong> %s | <strong>Söz:</strong> %d</p>
      </div>
    ", data$title_az, data$sample_id, data$grade_id, data$text_type_name, data$word_count))
  })
  
  output$text_content <- renderUI({
    data <- text_full_data()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    # Convert markdown to HTML
    content_html <- markdown::markdownToHTML(text = data$content_az, fragment.only = TRUE)
    
    div(class = "text-preview",
        HTML(content_html)
    )
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 5: STATİSTİKA
  # ─────────────────────────────────────────────────────────
  
  output$word_count_stats <- renderPlotly({
    data <- texts_data()
    
    plot_ly(data, x = ~title_az, y = ~word_count, type = 'bar',
            marker = list(color = ~word_count, colorscale = 'Blues')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Söz Sayı"))
  })
  
  output$questions_per_text <- renderPlotly({
    data <- texts_data()
    
    plot_ly(data, x = ~title_az, y = ~question_count, type = 'bar',
            marker = list(color = '#00a65a')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Sual Sayı"))
  })
  
  output$points_per_text <- renderPlotly({
    data <- texts_data()
    
    plot_ly(data, x = ~title_az, y = ~total_points, type = 'bar',
            marker = list(color = '#f39c12')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Ümumi Bal"))
  })
  
  output$creation_timeline <- renderPlotly({
    data <- texts_data()
    
    plot_ly(data, x = ~created_at, y = ~sample_id, type = 'scatter', mode = 'markers',
            marker = list(size = 10, color = '#3c8dbc')) %>%
      layout(xaxis = list(title = "Tarix"),
             yaxis = list(title = "Mətn ID"))
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 6: AXTARIŞ
  # ─────────────────────────────────────────────────────────
  
  search_results_data <- eventReactive(input$search_btn, {
    req(input$search_query)
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- sprintf("
      SELECT 
        ts.sample_id,
        ts.title_az,
        'Mətn' as type,
        LEFT(ts.content_az, 200) as preview
      FROM reading_literacy.text_samples ts
      WHERE ts.grade_id = 4 
        AND (LOWER(ts.title_az) LIKE LOWER('%%%s%%') 
             OR LOWER(ts.content_az) LIKE LOWER('%%%s%%'))
      
      UNION ALL
      
      SELECT 
        ts.sample_id,
        ts.title_az,
        'Sual' as type,
        q.question_text as preview
      FROM assessment.questions q
      JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
      WHERE ts.grade_id = 4 
        AND LOWER(q.question_text) LIKE LOWER('%%%s%%')
    ", input$search_query, input$search_query, input$search_query)
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    data
  })
  
  output$search_results <- renderDT({
    data <- search_results_data()
    if (is.null(data) || nrow(data) == 0) {
      return(data.frame(Mesaj = "Nəticə tapılmadı"))
    }
    
    datatable(data,
      colnames = c("ID", "Mətn", "Tip", "Önizləmə"),
      options = list(pageLength = 25)
    )
  })
  
  # ─────────────────────────────────────────────────────────
  # TAB 7: BAZA STRUKTURU
  # ─────────────────────────────────────────────────────────
  
  output$tables_list <- renderDT({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT 
        schemaname as schema,
        tablename as table_name,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
      FROM pg_tables
      WHERE schemaname IN ('reading_literacy', 'assessment')
      ORDER BY schemaname, tablename
    "
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    datatable(data,
      colnames = c("Schema", "Cədvəl", "Ölçü"),
      options = list(pageLength = 10, dom = 't')
    )
  })
  
  output$table_sizes <- renderPlotly({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT 
        tablename,
        pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
      FROM pg_tables
      WHERE schemaname IN ('reading_literacy', 'assessment')
      ORDER BY size_bytes DESC
    "
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    plot_ly(data, labels = ~tablename, values = ~size_bytes, type = 'pie') %>%
      layout(showlegend = TRUE)
  })
  
  output$text_samples_structure <- renderDT({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT 
        column_name,
        data_type,
        character_maximum_length as max_length
      FROM information_schema.columns
      WHERE table_schema = 'reading_literacy' 
        AND table_name = 'text_samples'
      ORDER BY ordinal_position
    "
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    datatable(data,
      colnames = c("Sütun", "Tip", "Uzunluq"),
      options = list(pageLength = 20, dom = 't')
    )
  })
  
  output$questions_structure <- renderDT({
    con <- get_db_connection()
    if (is.null(con)) return(NULL)
    
    query <- "
      SELECT 
        column_name,
        data_type,
        character_maximum_length as max_length
      FROM information_schema.columns
      WHERE table_schema = 'assessment' 
        AND table_name = 'questions'
      ORDER BY ordinal_position
    "
    
    data <- dbGetQuery(con, query)
    dbDisconnect(con)
    
    datatable(data,
      colnames = c("Sütun", "Tip", "Uzunluq"),
      options = list(pageLength = 20, dom = 't')
    )
  })
}

# ═══════════════════════════════════════════════════════════
# RUN APP
# ═══════════════════════════════════════════════════════════

shinyApp(ui = ui, server = server)
