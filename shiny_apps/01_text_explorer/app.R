# Mətn Kəşfiyyatçısı - 4 Sinif (I-IV)
# Author: Talıbov Tariyel İsmayıl oğlu
# ARTI - Azerbaijan Republic Education Institute
# Date: 2025

library(shiny)
library(shinydashboard)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(DT)

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Mətn Kəşfiyyatçısı"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Mətn Bankı", tabName = "texts", icon = icon("book"))
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
        margin: 15px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
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
    "))),
    
    tabItems(
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
              uiOutput("selected_text_display"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reaktiv məlumat - PostgreSQL-dən mətnləri oxuyur
  texts_data <- reactive({
    con <- dbConnect(PostgreSQL(), 
                     dbname = "azerbaijan_language_standards",
                     host = "localhost", 
                     port = 5432, 
                     user = Sys.getenv("USER"))
    
    data <- dbGetQuery(con,
      "SELECT 
         ts.sample_id,
         ts.title_az,
         ts.content_az,
         ts.word_count,
         ts.themes,
         ts.cultural_context,
         ts.source,
         g.grade_level,
         g.grade_name_az,
         tt.type_name_az
       FROM reading_literacy.text_samples ts
       JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
       JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
       ORDER BY g.grade_level, ts.sample_id")
    
    dbDisconnect(con)
    
    # Cultural context məlumatlarını parse edirik
    data <- data %>%
      mutate(
        pedagogical_purpose = str_replace(
          str_extract(cultural_context, "Məqsəd: [^|]+"), "Məqsəd: ", ""),
        best_practice = str_replace(
          str_extract(cultural_context, "BP: [^|]+"), "BP: ", ""),
        skill_focus = str_replace(
          str_extract(cultural_context, "Bacarıq: [^|]+"), "Bacarıq: ", ""),
        context_text = str_replace(
          str_extract(cultural_context, "Kontekst: .+"), "Kontekst: ", ""),
        standard_code = str_extract(source, "[0-9]-[0-9]\\.[0-9]")
      )
    
    data
  })
  
  # Filtrlənmiş məlumat
  filtered_data <- reactive({
    data <- texts_data()
    
    # Sinif filtri
    if(input$filter_grade != "all") {
      data <- data %>% filter(grade_level == as.integer(input$filter_grade))
    }
    
    # Mətn növü filtri
    if(!is.null(input$filter_text_type) && input$filter_text_type != "all") {
      data <- data %>% filter(type_name_az == input$filter_text_type)
    }
    
    # Standart filtri
    if(!is.null(input$filter_standard) && input$filter_standard != "all") {
      data <- data %>% filter(standard_code == input$filter_standard)
    }
    
    data
  })
  
  # Dinamik mətn növü filtri
  observe({
    types <- unique(texts_data()$type_name_az)
    updateSelectInput(session, "filter_text_type",
                     choices = c("Hamısı" = "all", setNames(types, types)))
  })
  
  # Dinamik standart filtri
  observe({
    stds <- unique(texts_data()$standard_code) %>% na.omit() %>% sort()
    updateSelectInput(session, "filter_standard",
                     choices = c("Hamısı" = "all", setNames(stds, stds)))
  })
  
  # Filtrləri sıfırlama
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "filter_grade", selected = "all")
    updateSelectInput(session, "filter_text_type", selected = "all")
    updateSelectInput(session, "filter_standard", selected = "all")
  })
  
  # Value boxes - Statistika
  output$total_texts <- renderValueBox({
    valueBox(nrow(texts_data()), "Ümumi Mətn Sayı", 
             icon = icon("book"), color = "blue")
  })
  
  output$grade_1_texts <- renderValueBox({
    count <- texts_data() %>% filter(grade_level == 1) %>% nrow()
    valueBox(count, "I Sinif", icon = icon("child"), color = "green")
  })
  
  output$grade_2_texts <- renderValueBox({
    count <- texts_data() %>% filter(grade_level == 2) %>% nrow()
    valueBox(count, "II Sinif", icon = icon("graduation-cap"), color = "yellow")
  })
  
  output$grade_3_texts <- renderValueBox({
    count <- texts_data() %>% filter(grade_level == 3) %>% nrow()
    valueBox(count, "III Sinif", icon = icon("book-reader"), color = "orange")
  })
  
  output$grade_4_texts <- renderValueBox({
    count <- texts_data() %>% filter(grade_level == 4) %>% nrow()
    valueBox(count, "IV Sinif", icon = icon("user-graduate"), color = "red")
  })
  
  # Mətn cədvəli
  output$texts_table <- renderDT({
    data <- filtered_data() %>%
      select(sample_id, grade_name_az, title_az, type_name_az, 
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
              colnames = c("ID", "Sinif", "Başlıq", "Növ", "Söz Sayı", "Standart"),
              rownames = FALSE)
  })
  
  # Seçilmiş mətnin göstərilməsi
  output$selected_text_display <- renderUI({
    s <- input$texts_table_rows_selected
    
    if(length(s) == 0) {
      return(div(style="text-align:center; padding:30px; color:#7f8c8d;",
                h3("Mətn seçin"),
                p("Yuxarıdakı cədvəldən bir sətir seçin")))
    }
    
    # Seçilmiş sətri filtered_data-dan götürürük
    text_data <- filtered_data()[s, ]
    
    tagList(
      div(class = "text-display",
        div(class = "text-title", 
          icon("book-open"), " ", text_data$title_az),
        
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
          ),
          div(class = "metadata-item",
            span(class = "metadata-label", "🎯 Pedaqoji Məqsəd:"),
            text_data$pedagogical_purpose
          ),
          div(class = "metadata-item",
            span(class = "metadata-label", "🌍 Best Practice:"),
            text_data$best_practice
          ),
          div(class = "metadata-item",
            span(class = "metadata-label", "💡 Bacarıq:"),
            text_data$skill_focus
          ),
          div(class = "metadata-item",
            span(class = "metadata-label", "🏛️ Mədəni Kontekst:"),
            text_data$context_text
          ),
          if(!is.na(text_data$themes) && text_data$themes != "") {
            div(class = "metadata-item",
              span(class = "metadata-label", "🎨 Mövzular:"),
              text_data$themes
            )
          }
        )
      )
    )
  })
}

shinyApp(ui, server)
