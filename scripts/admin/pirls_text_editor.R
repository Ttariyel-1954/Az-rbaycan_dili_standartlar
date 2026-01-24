# ═══════════════════════════════════════════════════════════
# PIRLS 2026 MƏTN VƏ SUAL REDAKTƏ SİSTEMİ
# Professional Content Editor for Language Specialists
# TAM VERSİYA - Heç bir funksionallıq itməyib!
# ═══════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DBI)
library(RPostgreSQL)
library(dplyr)
library(DT)
library(jsonlite)

# ═══════════════════════════════════════════════════════════
# DATABASE CONNECTION
# ═══════════════════════════════════════════════════════════

get_db_connection <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

# ═══════════════════════════════════════════════════════════
# DATA LOADING FUNCTIONS
# ═══════════════════════════════════════════════════════════

load_texts <- function() {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  dbGetQuery(con, "
    SELECT 
      sample_id,
      title_az,
      text_type_id,
      CASE 
        WHEN text_type_id = 2 THEN 'Ədəbi'
        WHEN text_type_id = 5 THEN 'İnformasiya'
        ELSE 'Digər'
      END as text_type,
      word_count,
      grade_id,
      pirls_2026_compliant,
      created_at
    FROM reading_literacy.text_samples
    WHERE grade_id = 4 AND pirls_2026_compliant = TRUE
    ORDER BY created_at DESC
  ")
}

load_text_detail <- function(sample_id) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  dbGetQuery(con, sprintf("
    SELECT 
      sample_id,
      title_az,
      content_az,
      text_type_id,
      word_count,
      pirls_2026_compliant,
      created_at
    FROM reading_literacy.text_samples
    WHERE sample_id = %d
  ", sample_id))
}

load_questions <- function(sample_id) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  # Database-də olan sütunlar
  dbGetQuery(con, sprintf("
    SELECT 
      question_id,
      question_number,
      question_text,
      question_type,
      cognitive_level,
      max_score,
      options::text as options_json,
      correct_answer
    FROM assessment.questions
    WHERE text_sample_id = %d
    ORDER BY question_number
  ", sample_id))
}

# ═══════════════════════════════════════════════════════════
# DATA UPDATE FUNCTIONS
# ═══════════════════════════════════════════════════════════

update_text <- function(sample_id, title, content) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  # Word count
  word_count <- length(strsplit(content, "\\s+")[[1]])
  
  dbExecute(con, sprintf("
    UPDATE reading_literacy.text_samples
    SET 
      title_az = '%s',
      content_az = '%s',
      word_count = %d,
      updated_at = CURRENT_TIMESTAMP
    WHERE sample_id = %d
  ",
                         gsub("'", "''", title),
                         gsub("'", "''", content),
                         word_count,
                         sample_id
  ))
}

update_question <- function(question_id, question_text, options_json, correct_answer) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  dbExecute(con, sprintf("
    UPDATE assessment.questions
    SET 
      question_text = '%s',
      options = '%s'::jsonb,
      correct_answer = %s,
      updated_at = CURRENT_TIMESTAMP
    WHERE question_id = %d
  ",
                         gsub("'", "''", question_text),
                         gsub("'", "''", options_json),
                         ifelse(is.null(correct_answer) || correct_answer == "", "NULL", 
                                sprintf("'%s'", gsub("'", "''", correct_answer))),
                         question_id
  ))
}

# ═══════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "📝 PIRLS 2026 Mətn və Sual Redaktoru",
    titleWidth = 400
  ),
  
  dashboardSidebar(
    width = 350,
    
    sidebarMenu(
      id = "sidebar",
      menuItem("📚 Mətn Seçimi", tabName = "texts", icon = icon("book")),
      menuItem("✏️ Mətn Redaktəsi", tabName = "text_edit", icon = icon("file-alt")),
      menuItem("❓ Sual Redaktəsi", tabName = "question_edit", icon = icon("question-circle")),
      menuItem("📊 Statistika", tabName = "stats", icon = icon("chart-bar"))
    ),
    
    hr(),
    
    div(
      style = "padding: 15px; background: #2c3e50; color: white; border-radius: 5px; margin: 10px;",
      h4("ℹ️ Məlumat", style = "margin-top: 0;"),
      p("PIRLS 2026 standartlarına uyğun mətn və sual redaktəsi", 
        style = "font-size: 12px;"),
      p("Dəyişikliklər dərhal PostgreSQL-ə yazılır", 
        style = "font-size: 11px; color: #bdc3c7;")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { 
          background: #ecf0f1;
        }
        
        .box {
          border-radius: 5px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .editor-box {
          background: white;
          padding: 25px;
          border-radius: 8px;
          margin-bottom: 20px;
          box-shadow: 0 2px 15px rgba(0,0,0,0.1);
        }
        
        .question-card {
          background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
          padding: 25px;
          border-radius: 10px;
          margin-bottom: 20px;
          border-left: 5px solid #3498db;
          box-shadow: 0 3px 15px rgba(0,0,0,0.1);
        }
        
        .option-input {
          background: white;
          padding: 15px;
          border-radius: 8px;
          margin-bottom: 10px;
          border: 2px solid #e0e0e0;
          transition: all 0.3s;
        }
        
        .option-input:hover {
          border-color: #3498db;
        }
        
        .save-button {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          padding: 12px 30px;
          border-radius: 5px;
          font-size: 16px;
          font-weight: bold;
          cursor: pointer;
          transition: all 0.3s;
        }
        
        .save-button:hover {
          transform: translateY(-2px);
          box-shadow: 0 5px 20px rgba(0,0,0,0.3);
        }
        
        .word-count {
          background: #3498db;
          color: white;
          padding: 8px 20px;
          border-radius: 25px;
          font-size: 14px;
          font-weight: bold;
          box-shadow: 0 2px 10px rgba(52,152,219,0.3);
        }
        
        .status-badge {
          padding: 6px 15px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 600;
          display: inline-block;
          margin: 5px;
        }
        
        .badge-mc { background: #3498db; color: white; }
        .badge-open { background: #9b59b6; color: white; }
        .badge-cognitive { background: #e67e22; color: white; }
        .badge-score { background: #e74c3c; color: white; }
        
        .correct-indicator {
          background: #27ae60;
          color: white;
          padding: 3px 10px;
          border-radius: 15px;
          font-size: 11px;
          font-weight: bold;
          margin-left: 10px;
        }
        
        textarea.form-control {
          font-size: 15px;
          line-height: 1.6;
          border: 2px solid #e0e0e0;
          border-radius: 8px;
          transition: all 0.3s;
        }
        
        textarea.form-control:focus {
          border-color: #3498db;
          box-shadow: 0 0 10px rgba(52,152,219,0.2);
        }
      "))
    ),
    
    tabItems(
      # ═══════════════════════════════════════════════════════
      # TAB 1: MƏTN SEÇİMİ
      # ═══════════════════════════════════════════════════════
      tabItem(
        tabName = "texts",
        
        fluidRow(
          box(
            width = 12,
            title = "📚 PIRLS 2026 Mətnləri",
            status = "primary",
            solidHeader = TRUE,
            
            p("Redaktə etmək üçün mətn seçin. Seçdiyiniz mətn avtomatik yüklənəcək.",
              style = "color: #7f8c8d; margin-bottom: 15px;"),
            
            DTOutput("texts_table")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "ℹ️ Seçilmiş Mətn Haqqında",
            status = "info",
            solidHeader = TRUE,
            collapsible = TRUE,
            
            uiOutput("text_info")
          )
        )
      ),
      
      # ═══════════════════════════════════════════════════════
      # TAB 2: MƏTN REDAKTƏSI
      # ═══════════════════════════════════════════════════════
      tabItem(
        tabName = "text_edit",
        
        fluidRow(
          box(
            width = 12,
            title = uiOutput("text_edit_title_display"),
            status = "primary",
            solidHeader = TRUE,
            
            div(class = "editor-box",
                
                fluidRow(
                  column(
                    width = 9,
                    textInput("edit_title", 
                              tags$b("📌 Mətn Başlığı:"), 
                              width = "100%",
                              placeholder = "Mətn başlığını daxil edin...")
                  ),
                  column(
                    width = 3,
                    uiOutput("word_count_display")
                  )
                ),
                
                br(),
                
                tags$label(tags$b("📄 Mətn Məzmunu:"), 
                           style = "font-size: 16px; color: #2c3e50;"),
                
                tags$p(
                  style = "color: #95a5a6; font-size: 13px; margin-top: 5px;",
                  "💡 Markdown formatı: # Başlıq 1, ## Başlıq 2, ### Başlıq 3"
                ),
                
                textAreaInput(
                  "edit_content",
                  NULL,
                  height = "450px",
                  width = "100%",
                  placeholder = "Mətn məzmununu daxil edin...\n\n# Başlıq\n\nParaqraf məzmunu..."
                ),
                
                br(),
                
                fluidRow(
                  column(
                    width = 6,
                    div(
                      style = "background: #e8f5e9; padding: 20px; border-radius: 8px; border-left: 4px solid #27ae60;",
                      tags$h5("✓ Formatlaşdırma Qaydaları:", style = "color: #27ae60; margin-top: 0;"),
                      tags$ul(
                        style = "margin-bottom: 0;",
                        tags$li("# Başlıq 1, ## Başlıq 2, ### Başlıq 3"),
                        tags$li("Boş sətir paraqrafları ayırır"),
                        tags$li("| Cədvəl | Format | Dəstəklənir |")
                      )
                    )
                  ),
                  column(
                    width = 6,
                    div(
                      style = "background: #fff3e0; padding: 20px; border-radius: 8px; border-left: 4px solid #f39c12;",
                      tags$h5("⚠️ PIRLS Tələbləri:", style = "color: #f39c12; margin-top: 0;"),
                      tags$ul(
                        style = "margin-bottom: 0;",
                        tags$li("Söz sayı: 400-600 arası"),
                        tags$li("4-cü sinif səviyyəsi"),
                        tags$li("Aydın və anlaşılan dil")
                      )
                    )
                  )
                ),
                
                br(),
                br(),
                
                div(
                  style = "text-align: center;",
                  actionButton("save_text", 
                               "💾 Mətni Saxla", 
                               class = "save-button",
                               style = "min-width: 250px; font-size: 18px;")
                )
            )
          )
        )
      ),
      
      # ═══════════════════════════════════════════════════════
      # TAB 3: SUAL REDAKTƏSI
      # ═══════════════════════════════════════════════════════
      tabItem(
        tabName = "question_edit",
        
        fluidRow(
          box(
            width = 12,
            title = "❓ Suallar və Cavablar Redaktəsi",
            status = "warning",
            solidHeader = TRUE,
            
            p("Hər sual üçün mətn, variantlar və doğru cavabı redaktə edə bilərsiniz.",
              style = "color: #7f8c8d; margin-bottom: 20px;"),
            
            uiOutput("questions_editor")
          )
        )
      ),
      
      # ═══════════════════════════════════════════════════════
      # TAB 4: STATİSTİKA
      # ═══════════════════════════════════════════════════════
      tabItem(
        tabName = "stats",
        
        fluidRow(
          valueBoxOutput("total_texts", width = 3),
          valueBoxOutput("total_questions", width = 3),
          valueBoxOutput("avg_word_count", width = 3),
          valueBoxOutput("compliant_rate", width = 3)
        ),
        
        fluidRow(
          box(
            width = 6,
            title = "📊 Mətn Növləri",
            status = "info",
            solidHeader = TRUE,
            plotOutput("text_types_chart", height = "300px")
          ),
          box(
            width = 6,
            title = "🧠 Cognitive Levels",
            status = "success",
            solidHeader = TRUE,
            plotOutput("cognitive_chart", height = "300px")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            title = "📈 Mətn Siyahısı",
            status = "primary",
            solidHeader = TRUE,
            DTOutput("all_texts_table")
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
  
  # ═══════════════════════════════════════════════════════
  # Reactive Values
  # ═══════════════════════════════════════════════════════
  
  rv <- reactiveValues(
    texts = NULL,
    selected_text = NULL,
    questions = NULL,
    refresh_counter = 0
  )
  
  # ═══════════════════════════════════════════════════════
  # Load Data on Start
  # ═══════════════════════════════════════════════════════
  
  observe({
    rv$refresh_counter  # Reactive dependency
    rv$texts <- load_texts()
  })
  
  # ═══════════════════════════════════════════════════════
  # TAB 1: Mətn Seçimi
  # ═══════════════════════════════════════════════════════
  
  output$texts_table <- renderDT({
    req(rv$texts)
    
    datatable(
      rv$texts %>%
        select(
          ID = sample_id,
          Başlıq = title_az,
          Növ = text_type,
          `Söz sayı` = word_count,
          `PIRLS 2026` = pirls_2026_compliant
        ),
      selection = "single",
      options = list(
        pageLength = 15,
        language = list(
          search = "Axtar:",
          lengthMenu = "Göstər _MENU_ mətn",
          info = "_TOTAL_ mətn arasında _START_-dən _END_-ə qədər",
          paginate = list(previous = "Əvvəl", `next` = "Sonra")
        )
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        'PIRLS 2026',
        backgroundColor = styleEqual(c(TRUE, FALSE), c('#27ae60', '#e74c3c')),
        color = 'white',
        fontWeight = 'bold'
      )
  })
  
  # Mətn seçimi
  observeEvent(input$texts_table_rows_selected, {
    req(input$texts_table_rows_selected)
    
    selected_row <- rv$texts[input$texts_table_rows_selected, ]
    sample_id <- selected_row$sample_id
    
    # Load mətn
    rv$selected_text <- load_text_detail(sample_id)
    
    # Load suallar
    rv$questions <- load_questions(sample_id)
    
    # Update editors
    updateTextInput(session, "edit_title", value = rv$selected_text$title_az)
    updateTextAreaInput(session, "edit_content", value = rv$selected_text$content_az)
    
    # Switch to edit tab
    updateTabItems(session, "sidebar", "text_edit")
    
    showNotification(
      sprintf("✅ Mətn yükləndi: %s (%d sual)",  selected_row$title_az, nrow(rv$questions)),
      type = "message",
      duration = 3,
      id = "text_loaded_notif"
    )
  })
  
  # Mətn info
  output$text_info <- renderUI({
    req(input$texts_table_rows_selected)
    selected <- rv$texts[input$texts_table_rows_selected, ]
    
    div(
      style = "padding: 20px;",
      fluidRow(
        column(
          width = 8,
          tags$h3(selected$title_az, style = "color: #2c3e50; margin-top: 0;"),
          tags$p(
            span(class = "status-badge", 
                 style = "background: #3498db; color: white;",
                 sprintf("📝 %s", selected$text_type)),
            span(class = "status-badge", 
                 style = "background: #9b59b6; color: white;",
                 sprintf("📏 %d söz", selected$word_count)),
            span(class = "status-badge", 
                 style = "background: #e67e22; color: white;",
                 sprintf("🎯 ID: %d", selected$sample_id))
          )
        ),
        column(
          width = 4,
          div(
            style = "text-align: right;",
            if (selected$pirls_2026_compliant) {
              div(
                style = "background: #27ae60; color: white; padding: 10px 20px; border-radius: 8px; display: inline-block;",
                tags$h4("✓ PIRLS 2026 Uyğun", style = "margin: 0;")
              )
            } else {
              div(
                style = "background: #e74c3c; color: white; padding: 10px 20px; border-radius: 8px; display: inline-block;",
                tags$h4("✗ Standarta uyğun deyil", style = "margin: 0;")
              )
            },
            br(), br(),
            actionButton("btn_edit_text", 
                         "✏️ Mətni Redaktə Et", 
                         class = "btn-primary btn-lg",
                         style = "min-width: 200px;")
          )
        )
      )
    )
  })
  
  observeEvent(input$btn_edit_text, {
    updateTabItems(session, "sidebar", "text_edit")
  })
  
  # ═══════════════════════════════════════════════════════
  # TAB 2: Mətn Redaktəsi
  # ═══════════════════════════════════════════════════════
  
  output$text_edit_title_display <- renderUI({
    if (is.null(rv$selected_text)) {
      return(tags$span("📝 Mətn Redaktəsi"))
    }
    tags$span(
      icon("edit"),
      sprintf(" Redaktə: %s (ID: %d)", 
              rv$selected_text$title_az, 
              rv$selected_text$sample_id)
    )
  })
  
  # Word count
  output$word_count_display <- renderUI({
    content <- input$edit_content
    if (is.null(content) || nchar(content) == 0) {
      word_count <- 0
    } else {
      word_count <- length(strsplit(content, "\\s+")[[1]])
    }
    
    color <- if (word_count >= 400 && word_count <= 600) {
      "#27ae60"  # Green
    } else if (word_count >= 300 && word_count < 800) {
      "#f39c12"  # Orange
    } else {
      "#e74c3c"  # Red
    }
    
    div(
      style = sprintf("text-align: center; padding: 15px; margin-top: 25px;"),
      span(
        sprintf("📊 %d söz", word_count),
        class = "word-count",
        style = sprintf("background: %s; font-size: 16px;", color)
      )
    )
  })
  
  # Save mətn
  observeEvent(input$save_text, {
    req(rv$selected_text, input$edit_title, input$edit_content)
    
    tryCatch({
      update_text(
        rv$selected_text$sample_id,
        input$edit_title,
        input$edit_content
      )
      
      # Refresh
      rv$refresh_counter <- rv$refresh_counter + 1
      
      showNotification(
        "✅ Mətn uğurla PostgreSQL-ə saxlanıldı!",
        type = "message",
        duration = 3,
        id = "text_saved_notif"
      )
    }, error = function(e) {
      showNotification(
        sprintf("❌ Xəta: %s", e$message),
        type = "error",
        duration = 5
      )
    })
  })
  
  # ═══════════════════════════════════════════════════════
  # TAB 3: Sual Redaktəsi
  # ═══════════════════════════════════════════════════════
  
  output$questions_editor <- renderUI({
    req(rv$questions)
    
    if (nrow(rv$questions) == 0) {
      return(div(
        style = "text-align: center; padding: 60px; background: #f8f9fa; border-radius: 10px;",
        icon("inbox", style = "font-size: 64px; color: #bdc3c7;"),
        tags$h3("Bu mətn üçün sual yoxdur", style = "color: #7f8c8d; margin-top: 20px;")
      ))
    }
    
    question_cards <- lapply(1:nrow(rv$questions), function(i) {
      q <- rv$questions[i, ]
      
      # Parse options
      options_list <- tryCatch({
        fromJSON(q$options_json)
      }, error = function(e) {
        data.frame(option = character(), text = character())
      })
      
      div(
        class = "question-card",
        
        # Sual başlığı
        tags$h3(
          sprintf("Sual %d", q$question_number),
          style = "color: #2c3e50; margin-top: 0;"
        ),
        
        # Badges
        div(
          style = "margin-bottom: 20px;",
          span(
            sprintf("📝 %s", ifelse(q$question_type == "multiple_choice", "Multiple Choice", "Open Response")),
            class = "status-badge badge-mc"
          ),
          span(
            sprintf("🧠 %s", q$cognitive_level),
            class = "status-badge badge-cognitive"
          ),
          span(
            sprintf("🎯 %d bal", q$max_score),
            class = "status-badge badge-score"
          )
        ),
        
        hr(style = "border-color: #bdc3c7;"),
        
        # Sual mətni
        textAreaInput(
          sprintf("question_text_%d", q$question_id),
          tags$b("📋 Sual Mətni:"),
          value = q$question_text,
          rows = 4,
          width = "100%",
          placeholder = "Sual mətnini daxil edin..."
        ),
        
        # Variantlar (MC üçün)
        if (q$question_type == "multiple_choice" && is.data.frame(options_list) && nrow(options_list) > 0) {
          tagList(
            br(),
            tags$h4("📝 Variantlar:", style = "color: #34495e;"),
            
            lapply(1:nrow(options_list), function(j) {
              opt <- options_list[j, ]
              is_correct <- (!is.na(q$correct_answer) && opt$option == q$correct_answer)
              
              div(
                class = "option-input",
                fluidRow(
                  column(
                    width = 11,
                    textInput(
                      sprintf("option_%d_%s", q$question_id, opt$option),
                      tags$b(sprintf("Variant %s:", opt$option)),
                      value = opt$text,
                      width = "100%",
                      placeholder = sprintf("Variant %s məzmunu...", opt$option)
                    )
                  ),
                  column(
                    width = 1,
                    if (is_correct) {
                      div(
                        style = "text-align: center; padding-top: 30px;",
                        span("✓", class = "correct-indicator")
                      )
                    }
                  )
                )
              )
            }),
            
            br(),
            
            selectInput(
              sprintf("correct_answer_%d", q$question_id),
              tags$b("✅ Doğru Cavab:"),
              choices = c("Seçin..." = "", options_list$option),
              selected = q$correct_answer,
              width = "200px"
            )
          )
        } else if (q$question_type == "open_response") {
          div(
            style = "background: #e8f5e9; padding: 15px; border-radius: 8px; margin-top: 15px;",
            icon("info-circle"),
            tags$b(" Bu açıq cavab sualıdır."),
            tags$p("Şagirdlər öz cavablarını yazacaq.", style = "margin: 5px 0 0 0; color: #7f8c8d;")
          )
        },
        
        br(),
        
        # Save button
        div(
          style = "text-align: center; margin-top: 20px;",
          actionButton(
            sprintf("save_question_%d", q$question_id),
            "💾 Sualı Saxla",
            class = "btn-success btn-lg",
            style = "min-width: 200px; font-size: 16px;",
            onclick = sprintf("Shiny.setInputValue('save_question_clicked', %d, {priority: 'event'})", q$question_id)
          )
        )
      )
    })
    
    do.call(tagList, question_cards)
  })
  
  # Save Question Handler
  observeEvent(input$save_question_clicked, {
    question_id <- input$save_question_clicked
    
    # Find question
    q <- rv$questions[rv$questions$question_id == question_id, ]
    req(nrow(q) > 0)
    q <- q[1, ]
    
    # Get inputs
    question_text <- input[[sprintf("question_text_%d", question_id)]]
    
    if (q$question_type == "multiple_choice") {
      # Parse current options
      options_list <- tryCatch({
        fromJSON(q$options_json)
      }, error = function(e) {
        data.frame(option = c("A", "B", "C", "D"), text = rep("", 4))
      })
      
      # Update options with new values
      updated_options <- lapply(1:nrow(options_list), function(j) {
        opt_letter <- options_list$option[j]
        opt_text <- input[[sprintf("option_%d_%s", question_id, opt_letter)]]
        list(option = opt_letter, text = opt_text)
      })
      
      options_json <- toJSON(updated_options, auto_unbox = TRUE)
      correct_answer <- input[[sprintf("correct_answer_%d", question_id)]]
    } else {
      options_json <- "[]"
      correct_answer <- NULL
    }
    
    # Save
    tryCatch({
      update_question(question_id, question_text, options_json, correct_answer)
      
      # Refresh questions
      rv$questions <- load_questions(rv$selected_text$sample_id)
      
      showNotification(
        sprintf("✅ Sual %d uğurla saxlanıldı!", q$question_number),
        type = "message",
        duration = 3,
        id = sprintf("question_saved_%d", question_id)
      )
    }, error = function(e) {
      showNotification(
        sprintf("❌ Xəta: %s", e$message),
        type = "error",
        duration = 5
      )
    })
  })
  
  # ═══════════════════════════════════════════════════════
  # TAB 4: Statistika
  # ═══════════════════════════════════════════════════════
  
  output$total_texts <- renderValueBox({
    req(rv$texts)
    valueBox(
      nrow(rv$texts),
      "Mətn sayı",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$total_questions <- renderValueBox({
    req(rv$texts)
    con <- get_db_connection()
    total <- dbGetQuery(con, "SELECT COUNT(*) as cnt FROM assessment.questions")$cnt
    dbDisconnect(con)
    
    valueBox(
      total,
      "Sual sayı",
      icon = icon("question-circle"),
      color = "yellow"
    )
  })
  
  output$avg_word_count <- renderValueBox({
    req(rv$texts)
    avg <- round(mean(rv$texts$word_count, na.rm = TRUE))
    
    valueBox(
      avg,
      "Orta söz sayı",
      icon = icon("font"),
      color = "green"
    )
  })
  
  output$compliant_rate <- renderValueBox({
    req(rv$texts)
    rate <- round(100 * sum(rv$texts$pirls_2026_compliant) / nrow(rv$texts))
    
    valueBox(
      sprintf("%d%%", rate),
      "PIRLS Uyğunluq",
      icon = icon("check-circle"),
      color = "purple"
    )
  })
  
  output$text_types_chart <- renderPlot({
    req(rv$texts)
    
    data <- rv$texts %>%
      group_by(text_type) %>%
      summarise(count = n())
    
    barplot(
      data$count,
      names.arg = data$text_type,
      col = c("#3498db", "#e74c3c"),
      main = "Mətn növü üzrə paylanma",
      ylab = "Sayı",
      las = 1,
      border = NA
    )
  })
  
  output$cognitive_chart <- renderPlot({
    req(rv$questions)
    
    if (nrow(rv$questions) > 0) {
      data <- rv$questions %>%
        group_by(cognitive_level) %>%
        summarise(count = n())
      
      barplot(
        data$count,
        names.arg = data$cognitive_level,
        col = rainbow(nrow(data)),
        main = "Cognitive səviyyə paylanması",
        ylab = "Sayı",
        las = 2,
        border = NA
      )
    }
  })
  
  output$all_texts_table <- renderDT({
    req(rv$texts)
    
    datatable(
      rv$texts %>%
        select(
          ID = sample_id,
          Başlıq = title_az,
          Növ = text_type,
          `Söz sayı` = word_count,
          `PIRLS 2026` = pirls_2026_compliant
        ),
      options = list(
        pageLength = 20,
        language = list(
          search = "Axtar:",
          lengthMenu = "Göstər _MENU_ mətn"
        )
      ),
      rownames = FALSE
    )
  })
}

# ═══════════════════════════════════════════════════════════
# RUN APP
# ═══════════════════════════════════════════════════════════

shinyApp(ui, server)