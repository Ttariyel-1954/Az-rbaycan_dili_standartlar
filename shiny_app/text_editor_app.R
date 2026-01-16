# Mətn Redaktoru - Böyük şrift
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
      menuItem("Mətn Bankı", tabName = "texts", icon = icon("book")),
      menuItem("Redaktə Et", tabName = "edit", icon = icon("edit"))
    ),
    hr(),
    h4("Filtrlər:", style="padding-left:15px; color:#ecf0f1;"),
    selectInput("filter_grade", "Sinif:",
                choices = c("Hamısı" = "all", "I sinif" = "1", "II sinif" = "2")),
    selectInput("filter_text_type", "Mətn Növü:", choices = NULL),
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
      
      /* REDAKTƏ SAHƏSI - BÖYÜK ŞRIFT */
      #edited_text {
        width: 100% !important;
        min-height: 400px !important;
        font-size: 20px !important;
        line-height: 1.8 !important;
        padding: 20px !important;
        border: 3px solid #3498db !important;
        border-radius: 8px !important;
        font-family: 'Segoe UI', Arial, sans-serif !important;
        background-color: #f8f9fa !important;
      }
      
      /* Orijinal mətn */
      #original_text {
        font-size: 18px !important;
        line-height: 1.8 !important;
        padding: 15px !important;
        background-color: #ecf0f1 !important;
        border-radius: 5px !important;
      }
      
      .save-btn {
        background-color: #27ae60 !important;
        color: white !important;
        font-size: 20px !important;
        padding: 15px 40px !important;
        margin-top: 15px !important;
        font-weight: bold !important;
      }
      .cancel-btn {
        background-color: #e74c3c !important;
        color: white !important;
        font-size: 20px !important;
        padding: 15px 40px !important;
        margin-top: 15px !important;
        font-weight: bold !important;
      }
      .word-count {
        font-size: 22px !important;
        font-weight: bold !important;
        color: #3498db !important;
        margin: 15px 0 !important;
        padding: 15px !important;
        background: #e3f2fd !important;
        border-radius: 8px !important;
      }
      
      .alert-success {
        font-size: 18px !important;
        padding: 20px !important;
      }
    "))),
    
    tabItems(
      # Mətn siyahısı
      tabItem(tabName = "texts",
        fluidRow(
          valueBoxOutput("total_texts", width = 4),
          valueBoxOutput("avg_words", width = 4),
          valueBoxOutput("edited_count", width = 4)
        ),
        
        fluidRow(
          box(width = 12, title = "Mətn Siyahısı - Redaktə etmək üçün seçin", 
              solidHeader = TRUE, status = "primary",
              DTOutput("texts_table"))
        ),
        
        fluidRow(
          box(width = 12, title = "Seçilmiş Mətn",
              solidHeader = TRUE, status = "info",
              uiOutput("selected_text_display"),
              hr(),
              actionButton("edit_button", "Bu mətni redaktə et", 
                          icon = icon("edit"), 
                          class = "btn-warning btn-lg"))
        )
      ),
      
      # Redaktə səhifəsi
      tabItem(tabName = "edit",
        fluidRow(
          box(width = 12, title = "Mətn Redaktəsi",
              solidHeader = TRUE, status = "warning",
              
              uiOutput("edit_info"),
              
              hr(),
              
              h3("Orijinal mətn (müqayisə üçün):"),
              verbatimTextOutput("original_text"),
              
              hr(),
              
              h3("Redaktə olunan mətn:", style="color:#e67e22;"),
              p(style="font-size:16px;", 
                "Mətni aşağıda dəyişdirin. Yalnız mətn məzmunu və söz sayı dəyişəcək."),
              
              textAreaInput("edited_text", NULL, 
                           value = "", 
                           width = "100%",
                           height = "400px",
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
    save_message = NULL
  )
  
  load_texts <- function() {
    con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                     host = "localhost", port = 5432, user = Sys.getenv("USER"))
    
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
        standard_code = str_extract(source, "[0-9]-[0-9]\\.[0-9]"),
        is_edited = str_detect(source, "REDAKTƏ")
      )
    
    data
  }
  
  observe({
    rv$texts <- load_texts()
  })
  
  filtered_data <- reactive({
    req(rv$texts)
    data <- rv$texts
    
    if(input$filter_grade != "all") {
      data <- data %>% filter(grade_level == as.integer(input$filter_grade))
    }
    
    if(!is.null(input$filter_text_type) && input$filter_text_type != "all") {
      data <- data %>% filter(type_name_az == input$filter_text_type)
    }
    
    data
  })
  
  observe({
    req(rv$texts)
    types <- unique(rv$texts$type_name_az)
    updateSelectInput(session, "filter_text_type",
                     choices = c("Hamısı" = "all", setNames(types, types)))
  })
  
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "filter_grade", selected = "all")
    updateSelectInput(session, "filter_text_type", selected = "all")
  })
  
  output$total_texts <- renderValueBox({
    req(rv$texts)
    valueBox(nrow(rv$texts), "Ümumi Mətn", icon = icon("book"), color = "blue")
  })
  
  output$avg_words <- renderValueBox({
    req(rv$texts)
    avg <- round(mean(rv$texts$word_count, na.rm = TRUE))
    valueBox(avg, "Orta Söz", icon = icon("align-left"), color = "green")
  })
  
  output$edited_count <- renderValueBox({
    req(rv$texts)
    edited <- sum(rv$texts$is_edited, na.rm = TRUE)
    valueBox(edited, "Redaktə edilib", icon = icon("edit"), color = "orange")
  })
  
  output$texts_table <- renderDT({
    req(filtered_data())
    
    data <- filtered_data() %>%
      select(sample_id, grade_name_az, title_az, type_name_az, 
             word_count, is_edited) %>%
      mutate(is_edited = ifelse(is_edited, "✓", ""))
    
    datatable(data, 
              selection = 'single',
              options = list(pageLength = 10),
              colnames = c("ID", "Sinif", "Başlıq", "Növ", "Söz", "Redaktə"),
              rownames = FALSE)
  })
  
  output$selected_text_display <- renderUI({
    s <- input$texts_table_rows_selected
    
    if(length(s) == 0) {
      return(div(style="text-align:center; padding:30px;",
                h4("Mətn seçin")))
    }
    
    text_data <- filtered_data()[s, ]
    rv$selected_text <- text_data
    
    div(class = "text-display",
      h3(text_data$title_az),
      p(style="font-size:16px; line-height:1.8;", text_data$content_az),
      hr(),
      p(strong("Söz sayı: "), text_data$word_count),
      p(strong("Sinif: "), text_data$grade_name_az),
      p(strong("Növ: "), text_data$type_name_az)
    )
  })
  
  observeEvent(input$edit_button, {
    req(rv$selected_text)
    
    rv$editing_id <- rv$selected_text$sample_id
    updateTextAreaInput(session, "edited_text", 
                       value = rv$selected_text$content_az)
    updateTabItems(session, "sidebar", "edit")
  })
  
  output$edit_info <- renderUI({
    req(rv$editing_id)
    text <- rv$texts %>% filter(sample_id == rv$editing_id)
    
    div(
      h4(style="color:#e67e22;", 
        icon("edit"), " Redaktə edilir: ", text$title_az),
      p(strong("ID: "), text$sample_id, " | ",
        strong("Sinif: "), text$grade_name_az)
    )
  })
  
  output$original_text <- renderText({
    req(rv$editing_id)
    text <- rv$texts %>% filter(sample_id == rv$editing_id)
    text$content_az
  })
  
  output$orig_word_count <- renderText({
    req(rv$editing_id)
    text <- rv$texts %>% filter(sample_id == rv$editing_id)
    as.character(text$word_count)
  })
  
  output$new_word_count <- renderText({
    if(is.null(input$edited_text) || input$edited_text == "") return("0")
    length(str_split(input$edited_text, "\\s+")[[1]])
  })
  
  observeEvent(input$save_changes, {
    req(rv$editing_id, input$edited_text)
    
    new_text <- str_trim(input$edited_text)
    new_word_count <- length(str_split(new_text, "\\s+")[[1]])
    
    if(new_text == "") {
      rv$save_message <- div(class="alert alert-danger", 
                            icon("times"), " Mətn boş ola bilməz!")
      return()
    }
    
    tryCatch({
      con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                       host = "localhost", port = 5432, user = Sys.getenv("USER"))
      
      query <- sprintf(
        "UPDATE reading_literacy.text_samples 
         SET content_az = '%s',
             word_count = %d,
             source = CASE 
               WHEN source LIKE '%%REDAKTƏ OLUNUB%%' THEN source
               ELSE source || ' - REDAKTƏ OLUNUB'
             END
         WHERE sample_id = %d",
        gsub("'", "''", new_text),
        new_word_count,
        rv$editing_id
      )
      
      dbExecute(con, query)
      dbDisconnect(con)
      
      rv$texts <- load_texts()
      
      rv$save_message <- div(class="alert alert-success",
                            h4(icon("check-circle"), " Uğurla saxlanıldı!"),
                            p("Yeni söz sayı: ", strong(new_word_count)))
      
      delay(2000, {
        updateTextAreaInput(session, "edited_text", value = "")
        rv$editing_id <- NULL
        updateTabItems(session, "sidebar", "texts")
        rv$save_message <- NULL
      })
      
    }, error = function(e) {
      rv$save_message <- div(class="alert alert-danger",
                            icon("times"), " Xəta: ", e$message)
    })
  })
  
  observeEvent(input$cancel_edit, {
    updateTextAreaInput(session, "edited_text", value = "")
    rv$editing_id <- NULL
    rv$save_message <- NULL
    updateTabItems(session, "sidebar", "texts")
  })
  
  output$save_status <- renderUI({
    rv$save_message
  })
}

shinyApp(ui, server)
