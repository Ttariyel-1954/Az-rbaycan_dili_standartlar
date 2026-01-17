# Mətn Redaktoru - 4 Sinif (I-IV)
# Author: Talıbov Tariyel İsmayıl oğlu
# ARTI - Azerbaijan Republic Education Institute
# Mətnləri redaktə etmək və bazaya saxlamaq üçün

library(shiny)
library(shinydashboard)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(DT)
library(shinyjs)

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Mətn Redaktoru"),
  
  dashboardSidebar(
    useShinyjs(),
    sidebarMenu(
      id = "sidebar",
      menuItem("Mətn Bankı", tabName = "texts", icon = icon("book")),
      menuItem("Redaktə Et", tabName = "edit", icon = icon("edit"))
    ),
    hr(),
    h4("Filtrlər:", style="padding-left:15px; color:#ecf0f1;"),
    selectInput("filter_grade", "Sinif:",
                choices = c("Hamısı" = "all", 
                            "I sinif" = "1", 
                            "II sinif" = "2",
                            "III sinif" = "3",
                            "IV sinif" = "4")),
    selectInput("filter_text_type", "Mətn Növü:", choices = NULL),
    selectInput("filter_standard", "Standart:", choices = NULL),
    actionButton("reset_filters", "Sıfırla", icon = icon("refresh"),
                 style="margin-left:15px; margin-top:10px;")
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      .text-display { 
        background: white; 
        padding: 25px; 
        border-radius: 8px;
        border-left: 5px solid #3498db;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      
      /* REDAKTƏ SAHƏSI - BÖYÜK ŞRİFT */
      #edited_text {
        width: 100% !important;
        min-height: 400px !important;
        font-size: 20px !important;
        line-height: 1.8 !important;
        padding: 20px !important;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif !important;
        border: 2px solid #3498db !important;
        border-radius: 8px !important;
        background: #f8f9fa !important;
      }
      
      .text-title { 
        color: #2c3e50; 
        font-size: 28px; 
        font-weight: bold;
        margin-bottom: 20px;
        border-bottom: 2px solid #ecf0f1;
        padding-bottom: 10px;
      }
      
      .text-content { 
        font-size: 18px; 
        line-height: 2;
        color: #34495e;
        text-align: justify;
        margin: 20px 0;
        padding: 15px;
        background: #f8f9fa;
        border-radius: 5px;
      }
      
      .metadata { 
        background: #ecf0f1; 
        padding: 20px; 
        border-radius: 8px;
        margin-top: 20px;
      }
      
      .metadata-item { 
        margin: 12px 0;
        font-size: 15px;
        padding: 8px;
        background: white;
        border-radius: 4px;
      }
      
      .metadata-label {
        font-weight: bold;
        color: #2c3e50;
        display: inline-block;
        min-width: 180px;
      }
      
      .edit-btn {
        background: #3498db;
        color: white;
        font-size: 16px;
        padding: 10px 20px;
        margin-top: 15px;
      }
      
      .edit-btn:hover {
        background: #2980b9;
      }
      
      .save-btn {
        background: #27ae60;
        color: white;
        font-size: 18px;
        padding: 12px;
        font-weight: bold;
      }
      
      .save-btn:hover {
        background: #229954;
      }
      
      .cancel-btn {
        background: #e74c3c;
        color: white;
        font-size: 18px;
        padding: 12px;
      }
      
      .cancel-btn:hover {
        background: #c0392b;
      }
      
      .word-count {
        font-size: 18px;
        color: #2c3e50;
        background: #ecf0f1;
        padding: 15px;
        border-radius: 5px;
        margin: 15px 0;
        font-weight: bold;
      }
      
      .original-text {
        background: #fff9e6;
        padding: 20px;
        border-radius: 8px;
        border-left: 5px solid #f39c12;
        margin-bottom: 25px;
      }
      
      .original-text h4 {
        color: #f39c12;
        margin-top: 0;
      }
      
      .alert {
        padding: 15px;
        border-radius: 5px;
        margin: 15px 0;
        font-size: 16px;
      }
      
      .alert-success {
        background: #d4edda;
        border-left: 5px solid #28a745;
        color: #155724;
      }
      
      .alert-danger {
        background: #f8d7da;
        border-left: 5px solid #dc3545;
        color: #721c24;
      }
      
      .edited-badge {
        background: #27ae60;
        color: white;
        padding: 3px 8px;
        border-radius: 3px;
        font-size: 12px;
        margin-left: 8px;
      }
    "))),
    
    tabItems(
      # Mətn Bankı
      tabItem(tabName = "texts",
              fluidRow(
                valueBoxOutput("total_texts", width = 12)
              ),
              
              fluidRow(
                valueBoxOutput("grade_1_texts", width = 3),
                valueBoxOutput("grade_2_texts", width = 3),
                valueBoxOutput("grade_3_texts", width = 3),
                valueBoxOutput("grade_4_texts", width = 3)
              ),
              
              fluidRow(
                box(width = 12, title = "Mətn Siyahısı - Sətri seçin", 
                    solidHeader = TRUE, status = "primary",
                    DTOutput("texts_table"))
              ),
              
              fluidRow(
                box(width = 12, title = "Seçilmiş Mətn",
                    solidHeader = TRUE, status = "info",
                    uiOutput("selected_text_display"),
                    uiOutput("edit_button"))
              )
      ),
      
      # Redaktə Et
      tabItem(tabName = "edit",
              fluidRow(
                box(width = 12, 
                    title = uiOutput("edit_title"),
                    solidHeader = TRUE, status = "warning",
                    
                    uiOutput("original_text_display"),
                    
                    h4(icon("edit"), " Yeni Mətn:"),
                    p("Mətni redaktə edin. Yalnız mətn məzmunu və söz sayı dəyişəcək."),
                    
                    textAreaInput("edited_text", NULL, 
                                  value = "", 
                                  width = "100%",
                                  placeholder = "Mətni bura yazın..."),
                    
                    div(class = "word-count",
                        icon("arrows-alt-h"), " ",
                        "Orijinal söz sayı: ", textOutput("orig_word_count", inline = TRUE), 
                        " → ",
                        "Yeni söz sayı: ", textOutput("new_word_count", inline = TRUE)
                    ),
                    
                    hr(),
                    
                    fluidRow(
                      column(6, 
                             actionButton("save_changes", "Dəyişiklikləri Saxla", 
                                          icon = icon("save"),
                                          class = "save-btn btn-block")),
                      column(6,
                             actionButton("cancel_edit", "Ləğv Et", 
                                          icon = icon("times"),
                                          class = "cancel-btn btn-block"))
                    ),
                    
                    hr(),
                    uiOutput("save_status")
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  rv <- reactiveValues(
    texts = NULL,
    selected_text = NULL,
    editing_id = NULL,
    save_message = NULL,
    edited_ids = c()
  )
  
  # Mətnləri yüklə
  load_texts <- function() {
    con <- dbConnect(PostgreSQL(), 
                     dbname = "azerbaijan_language_standards",
                     host = "localhost", 
                     port = 5432, 
                     user = Sys.getenv("USER"))
    
    data <- dbGetQuery(con,
                       "SELECT 
         ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
         ts.themes, ts.cultural_context, ts.source,
         g.grade_level, g.grade_name_az, tt.type_name_az
       FROM reading_literacy.text_samples ts
       JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
       JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
       ORDER BY g.grade_level, ts.sample_id")
    
    dbDisconnect(con)
    
    data <- data %>%
      mutate(
        pedagogical_purpose = str_replace(
          str_extract(cultural_context, "Məqsəd: [^|]+"), "Məqsəd: ", ""),
        standard_code = str_extract(source, "[0-9]-[0-9]\\.[0-9]")
      )
    
    data
  }
  
  # İlk yükləmə
  observe({
    rv$texts <- load_texts()
  })
  
  # Filtrlənmiş məlumat
  filtered_data <- reactive({
    req(rv$texts)
    data <- rv$texts
    
    if(input$filter_grade != "all") {
      data <- data %>% filter(grade_level == as.integer(input$filter_grade))
    }
    
    if(!is.null(input$filter_text_type) && input$filter_text_type != "all") {
      data <- data %>% filter(type_name_az == input$filter_text_type)
    }
    
    if(!is.null(input$filter_standard) && input$filter_standard != "all") {
      data <- data %>% filter(standard_code == input$filter_standard)
    }
    
    data
  })
  
  # Dinamik filterlər
  observe({
    req(rv$texts)
    types <- unique(rv$texts$type_name_az)
    updateSelectInput(session, "filter_text_type",
                      choices = c("Hamısı" = "all", setNames(types, types)))
  })
  
  observe({
    req(rv$texts)
    stds <- unique(rv$texts$standard_code) %>% na.omit() %>% sort()
    updateSelectInput(session, "filter_standard",
                      choices = c("Hamısı" = "all", setNames(stds, stds)))
  })
  
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "filter_grade", selected = "all")
    updateSelectInput(session, "filter_text_type", selected = "all")
    updateSelectInput(session, "filter_standard", selected = "all")
  })
  
  # Value boxes
  output$total_texts <- renderValueBox({
    req(rv$texts)
    valueBox(nrow(rv$texts), "Ümumi Mətn Sayı", 
             icon = icon("book"), color = "blue")
  })
  
  output$grade_1_texts <- renderValueBox({
    req(rv$texts)
    count <- rv$texts %>% filter(grade_level == 1) %>% nrow()
    valueBox(count, "I Sinif", icon = icon("child"), color = "green")
  })
  
  output$grade_2_texts <- renderValueBox({
    req(rv$texts)
    count <- rv$texts %>% filter(grade_level == 2) %>% nrow()
    valueBox(count, "II Sinif", icon = icon("graduation-cap"), color = "yellow")
  })
  
  output$grade_3_texts <- renderValueBox({
    req(rv$texts)
    count <- rv$texts %>% filter(grade_level == 3) %>% nrow()
    valueBox(count, "III Sinif", icon = icon("book-reader"), color = "orange")
  })
  
  output$grade_4_texts <- renderValueBox({
    req(rv$texts)
    count <- rv$texts %>% filter(grade_level == 4) %>% nrow()
    valueBox(count, "IV Sinif", icon = icon("user-graduate"), color = "red")
  })
  
  # Mətn cədvəli
  output$texts_table <- renderDT({
    req(filtered_data())
    data <- filtered_data() %>%
      mutate(
        status = ifelse(sample_id %in% rv$edited_ids, "✓", "")
      ) %>%
      select(sample_id, status, grade_name_az, title_az, type_name_az, 
             word_count, standard_code)
    
    datatable(data, 
              selection = 'single',
              options = list(
                pageLength = 10,
                language = list(
                  search = "Axtar:",
                  lengthMenu = "Səhifədə _MENU_ mətn",
                  info = "_TOTAL_ mətn içərisindən _START_-dən _END_-ə qədər",
                  paginate = list(
                    first = "İlk",
                    last = "Son",
                    `next` = "Növbəti",
                    previous = "Əvvəlki"
                  )
                )
              ),
              colnames = c("ID", "✓", "Sinif", "Başlıq", "Növ", "Söz", "Standart"),
              rownames = FALSE)
  })
  
  # Seçilmiş mətn
  output$selected_text_display <- renderUI({
    s <- input$texts_table_rows_selected
    
    if(length(s) == 0) {
      return(div(style="text-align:center; padding:30px; color:#7f8c8d;",
                 h3("Mətn seçin"),
                 p("Yuxarıdakı cədvəldən bir sətir seçin")))
    }
    
    text_data <- filtered_data()[s, ]
    rv$selected_text <- text_data
    
    tagList(
      div(class = "text-display",
          div(class = "text-title", 
              icon("book-open"), " ", text_data$title_az,
              if(text_data$sample_id %in% rv$edited_ids) {
                span(class = "edited-badge", "Redaktə edilib")
              }
          ),
          
          div(class = "text-content", 
              text_data$content_az),
          
          div(class = "metadata",
              div(class = "metadata-item",
                  span(class = "metadata-label", "📚 Sinif:"),
                  text_data$grade_name_az
              ),
              div(class = "metadata-item",
                  span(class = "metadata-label", "📝 Mətn Növü:"),
                  text_data$type_name_az
              ),
              div(class = "metadata-item",
                  span(class = "metadata-label", "📊 Standart:"),
                  text_data$standard_code
              ),
              div(class = "metadata-item",
                  span(class = "metadata-label", "🔢 Söz Sayı:"),
                  text_data$word_count
              )
          )
      )
    )
  })
  
  # Redaktə düyməsi
  output$edit_button <- renderUI({
    req(rv$selected_text)
    actionButton("start_edit", "Bu mətni redaktə et", 
                 icon = icon("edit"),
                 class = "edit-btn")
  })
  
  # Redaktəyə başla
  observeEvent(input$start_edit, {
    req(rv$selected_text)
    rv$editing_id <- rv$selected_text$sample_id
    updateTextAreaInput(session, "edited_text", 
                        value = rv$selected_text$content_az)
    rv$save_message <- NULL
    updateTabItems(session, "sidebar", "edit")
  })
  
  # Redaktə başlığı
  output$edit_title <- renderUI({
    if(is.null(rv$editing_id)) {
      h3("Mətn seçilməyib")
    } else {
      text <- rv$texts %>% filter(sample_id == rv$editing_id)
      h3(icon("edit"), " Redaktə: ", text$title_az)
    }
  })
  
  # Orijinal mətn
  output$original_text_display <- renderUI({
    req(rv$editing_id)
    text <- rv$texts %>% filter(sample_id == rv$editing_id)
    
    div(class = "original-text",
        h4(icon("book"), " Orijinal Mətn (müqayisə üçün):"),
        p(text$content_az, style="font-size: 16px; line-height: 1.8;")
    )
  })
  
  # Söz sayı hesablamaları
  output$orig_word_count <- renderText({
    req(rv$editing_id)
    text <- rv$texts %>% filter(sample_id == rv$editing_id)
    as.character(text$word_count)
  })
  
  output$new_word_count <- renderText({
    if(is.null(input$edited_text) || input$edited_text == "") {
      return("0")
    }
    words <- str_split(input$edited_text, "\\s+")[[1]]
    words <- words[words != ""]
    as.character(length(words))
  })
  
  # Dəyişiklikləri saxla
  observeEvent(input$save_changes, {
    req(rv$editing_id)
    req(input$edited_text)
    
    if(input$edited_text == "") {
      rv$save_message <- div(class="alert alert-danger",
                             icon("times"), " Xəta: Mətn boş ola bilməz!")
      return()
    }
    
    tryCatch({
      # Yeni söz sayını hesabla
      new_words <- str_split(input$edited_text, "\\s+")[[1]]
      new_words <- new_words[new_words != ""]
      new_word_count <- length(new_words)
      
      # Bazaya yaz
      con <- dbConnect(PostgreSQL(), 
                       dbname = "azerbaijan_language_standards",
                       host = "localhost", 
                       port = 5432, 
                       user = Sys.getenv("USER"))
      
      query <- sprintf(
        "UPDATE reading_literacy.text_samples 
         SET content_az = '%s', word_count = %d 
         WHERE sample_id = %d",
        gsub("'", "''", input$edited_text),
        new_word_count,
        rv$editing_id
      )
      
      dbExecute(con, query)
      dbDisconnect(con)
      
      # Mətnləri yenidən yüklə
      rv$texts <- load_texts()
      
      # Redaktə edilmiş kimi işarələ
      rv$edited_ids <- unique(c(rv$edited_ids, rv$editing_id))
      
      rv$save_message <- div(class="alert alert-success",
                             icon("check"), " Uğurla saxlanıldı! ",
                             "Yeni söz sayı: ", new_word_count)
      
      # 3 saniyə sonra tab-ı dəyiş
      shinyjs::delay(3000, {
        updateTextAreaInput(session, "edited_text", value = "")
        rv$editing_id <- NULL
        updateTabItems(session, "sidebar", "texts")
      })
      
    }, error = function(e) {
      rv$save_message <- div(class="alert alert-danger",
                             icon("times"), " Xəta: ", e$message)
    })
  })
  
  # Ləğv et
  observeEvent(input$cancel_edit, {
    updateTextAreaInput(session, "edited_text", value = "")
    rv$editing_id <- NULL
    rv$save_message <- NULL
    updateTabItems(session, "sidebar", "texts")
  })
  
  # Status mesajı
  output$save_status <- renderUI({
    rv$save_message
  })
}

shinyApp(ui, server)