# ═══════════════════════════════════════════════════════════
# PIRLS 2026 TEST BUILDER - AZƏRBAYCAN DİLİ IV SİNİF
# ═══════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(DBI)
library(RPostgreSQL)
library(DT)
library(dplyr)  # data manipulation
library(jsonlite)  # JSON parsing
library(ggplot2)
library(scales)
library(officer)  # DOCX export
library(flextable)  # DOCX tables

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

load_texts <- function(pirls_only = TRUE) {
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  query <- "
    SELECT 
      ts.sample_id,
      ts.title_az as title,
      CASE 
        WHEN ts.text_type_id = 2 THEN 'Ədəbi'
        WHEN ts.text_type_id = 5 THEN 'İnformasiya'
        ELSE 'Digər'
      END as text_type,
      ts.word_count,
      COUNT(q.question_id) as question_count,
      SUM(q.max_score) as total_score
    FROM reading_literacy.text_samples ts
    LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
    WHERE ts.grade_id = 4
  "
  
  if (pirls_only) {
    query <- paste0(query, " AND ts.pirls_2026_compliant = TRUE")
  }
  
  query <- paste0(query, "
    GROUP BY ts.sample_id, ts.title_az, ts.text_type_id, ts.word_count
    ORDER BY ts.text_type_id, ts.title_az
  ")
  
  dbGetQuery(con, query)
}

get_cognitive_distribution <- function(sample_ids) {
  if (length(sample_ids) == 0) return(NULL)
  
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  ids <- paste(sample_ids, collapse = ",")
  query <- sprintf("
    SELECT 
      q.cognitive_level,
      COUNT(*) as count,
      SUM(q.max_score) as score
    FROM assessment.questions q
    WHERE q.text_sample_id IN (%s)
    GROUP BY q.cognitive_level
  ", ids)
  
  dbGetQuery(con, query)
}

get_full_test_data <- function(sample_ids) {
  if (length(sample_ids) == 0) return(NULL)
  
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  ids <- paste(sample_ids, collapse = ",")
  query <- sprintf("
    SELECT 
      ts.title_az,
      ts.content_az,
      ts.word_count,
      q.question_number,
      q.question_text,
      q.question_type,
      q.cognitive_level,
      q.max_score,
      q.options::text as options,
      q.correct_answer,
      q.sample_answer,
      q.scoring_rubric::text as scoring_rubric
    FROM reading_literacy.text_samples ts
    JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
    WHERE ts.sample_id IN (%s)
    ORDER BY ts.sample_id, q.question_number
  ", ids)
  
  dbGetQuery(con, query)
}

# ═══════════════════════════════════════════════════════════
# COGNITIVE BALANCE CHECKER
# ═══════════════════════════════════════════════════════════

check_cognitive_balance <- function(cognitive_dist) {
  if (is.null(cognitive_dist) || nrow(cognitive_dist) == 0) {
    return(list(
      status = "empty",
      message = "Mətn seçilməyib",
      color = "gray"
    ))
  }
  
  total <- sum(cognitive_dist$count, na.rm = TRUE)
  
  if (total == 0) {
    return(list(
      status = "empty",
      message = "Sual seçilməyib",
      color = "gray"
    ))
  }
  
  # PIRLS standartları
  standards <- data.frame(
    level = c("focus_retrieve", "make_inferences", 
              "interpret_integrate", "examine_evaluate"),
    min = c(30, 20, 20, 20),
    max = c(40, 25, 25, 25)
  )
  
  results <- merge(cognitive_dist, standards, 
                   by.x = "cognitive_level", by.y = "level", all = TRUE)
  
  # NA-ları təmizlə
  results$count[is.na(results$count)] <- 0
  results$percentage <- round(100 * results$count / total, 1)
  results$percentage[is.na(results$percentage)] <- 0
  
  # Check balance
  issues <- c()
  for (i in 1:nrow(results)) {
    pct <- results$percentage[i]
    min_val <- results$min[i]
    max_val <- results$max[i]
    
    if (is.na(pct)) pct <- 0
    if (is.na(min_val)) min_val <- 0
    if (is.na(max_val)) max_val <- 100
    
    if (pct < min_val) {
      issues <- c(issues, sprintf("%s: %s%% (min: %s%%)", 
                                  results$cognitive_level[i], pct, min_val))
    } else if (pct > max_val) {
      issues <- c(issues, sprintf("%s: %s%% (max: %s%%)", 
                                  results$cognitive_level[i], pct, max_val))
    }
  }
  
  if (length(issues) == 0) {
    return(list(
      status = "perfect",
      message = "✅ Cognitive balance mükəmməldir!",
      color = "green",
      details = results
    ))
  } else {
    return(list(
      status = "imbalanced",
      message = paste("⚠️ Balans problemləri:", paste(issues, collapse = "; ")),
      color = "orange",
      details = results
    ))
  }
}

# ═══════════════════════════════════════════════════════════
# TEXT TYPE BALANCE CHECKER
# ═══════════════════════════════════════════════════════════

check_text_type_balance <- function(selected_texts, all_texts) {
  if (nrow(selected_texts) == 0) {
    return(list(
      status = "empty",
      message = "Mətn seçilməyib",
      color = "gray"
    ))
  }
  
  type_dist <- table(selected_texts$text_type)
  edəbi <- ifelse("Ədəbi" %in% names(type_dist), type_dist["Ədəbi"], 0)
  info <- ifelse("İnformasiya" %in% names(type_dist), type_dist["İnformasiya"], 0)
  
  total <- edəbi + info
  edəbi_pct <- round(100 * edəbi / total, 1)
  info_pct <- round(100 * info / total, 1)
  
  # PIRLS tövsiyəsi: 50/50
  if (abs(edəbi_pct - 50) <= 10) {  # ±10% tolerance
    return(list(
      status = "balanced",
      message = sprintf("✅ Balans yaxşıdır: Ədəbi %s%%, İnfo %s%%", 
                        edəbi_pct, info_pct),
      color = "green",
      edəbi = edəbi,
      info = info
    ))
  } else {
    return(list(
      status = "imbalanced",
      message = sprintf("⚠️ Disbalans: Ədəbi %s%%, İnfo %s%% (tövsiyə: 50/50)", 
                        edəbi_pct, info_pct),
      color = "orange",
      edəbi = edəbi,
      info = info
    ))
  }
}

# ═══════════════════════════════════════════════════════════
# RANDOM TEST GENERATOR
# ═══════════════════════════════════════════════════════════

generate_random_test <- function(all_texts, n_texts = 6) {
  # 50/50 balance: 3 ədəbi, 3 info
  n_edəbi <- floor(n_texts / 2)
  n_info <- n_texts - n_edəbi
  
  edəbi_texts <- all_texts[all_texts$text_type == "Ədəbi", ]
  info_texts <- all_texts[all_texts$text_type == "İnformasiya", ]
  
  # Random sample
  selected_edəbi <- if (nrow(edəbi_texts) >= n_edəbi) {
    edəbi_texts[sample(nrow(edəbi_texts), n_edəbi), ]
  } else {
    edəbi_texts
  }
  
  selected_info <- if (nrow(info_texts) >= n_info) {
    info_texts[sample(nrow(info_texts), n_info), ]
  } else {
    info_texts
  }
  
  rbind(selected_edəbi, selected_info)
}

# ═══════════════════════════════════════════════════════════
# EXPORT TO DOCX
# ═══════════════════════════════════════════════════════════

export_to_docx <- function(test_data, filename) {
  doc <- read_docx()
  
  # Title
  doc <- doc %>%
    body_add_par("PIRLS 2026 TEST PAKETİ", style = "heading 1") %>%
    body_add_par(sprintf("Yaradılma tarixi: %s", Sys.Date()), style = "Normal") %>%
    body_add_par("", style = "Normal")
  
  # Group by text
  texts <- unique(test_data$title_az)
  
  for (txt in texts) {
    text_data <- test_data[test_data$title_az == txt, ]
    
    # Text title
    doc <- doc %>%
      body_add_par(txt, style = "heading 2") %>%
      body_add_par(sprintf("Söz sayı: %d", text_data$word_count[1]), 
                   style = "Normal") %>%
      body_add_par("", style = "Normal")
    
    # Text content
    doc <- doc %>%
      body_add_par(text_data$content_az[1], style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("SUALLAR:", style = "heading 3")
    
    # Questions
    for (i in 1:nrow(text_data)) {
      q <- text_data[i, ]
      
      doc <- doc %>%
        body_add_par(sprintf("%d. %s", q$question_number, q$question_text), 
                     style = "Normal") %>%
        body_add_par(sprintf("Tip: %s | Cognitive: %s | Bal: %d",
                             q$question_type, q$cognitive_level, q$max_score),
                     style = "Normal")
      
      if (!is.na(q$sample_answer)) {
        doc <- doc %>%
          body_add_par(sprintf("Nümunə cavab: %s", q$sample_answer), 
                       style = "Normal")
      }
      
      doc <- doc %>% body_add_par("", style = "Normal")
    }
    
    doc <- doc %>% body_add_break()
  }
  
  print(doc, target = filename)
  return(filename)
}

# ═══════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════

ui <- dashboardPage(
  dashboardHeader(title = "PIRLS 2026 Test Builder"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Mətn Seçimi", tabName = "selection", icon = icon("check-square")),
      menuItem("Mətn Təfsilat", tabName = "detail", icon = icon("book-open")),
      menuItem("Cognitive Balance", tabName = "cognitive", icon = icon("brain")),
      menuItem("Test Eksport", tabName = "export", icon = icon("file-export"))
    ),
    
    hr(),
    
    checkboxInput("pirls_filter", "PIRLS 2026 Mətnləri", value = TRUE),
    
    hr(),
    
    h4("Random Generator"),
    numericInput("n_random", "Mətn sayı:", value = 6, min = 2, max = 13),
    actionButton("generate_random", "Random Test Yarat", 
                 icon = icon("random"), class = "btn-primary btn-block")
  ),
  
  dashboardBody(
    tabItems(
      # ─────────────────────────────────────────────────────
      # TAB 1: Mətn Seçimi
      # ─────────────────────────────────────────────────────
      tabItem(tabName = "selection",
              fluidRow(
                box(width = 12, title = "Mövcud Mətnlər", status = "primary", 
                    solidHeader = TRUE,
                    DTOutput("texts_table")
                )
              ),
              
              fluidRow(
                valueBoxOutput("total_texts", width = 3),
                valueBoxOutput("selected_count", width = 3),
                valueBoxOutput("total_questions", width = 3),
                valueBoxOutput("total_score", width = 3)
              ),
              
              fluidRow(
                box(width = 6, title = "Text Type Balance", status = "info",
                    plotOutput("text_type_plot", height = "200px"),
                    uiOutput("text_type_status")
                ),
                
                box(width = 6, title = "Seçilmiş Mətnlər", status = "success",
                    tableOutput("selected_texts_table")
                )
              )
      ),
      
      # ─────────────────────────────────────────────────────
      # TAB 2: Mətn Təfsilat
      # ─────────────────────────────────────────────────────
      tabItem(tabName = "detail",
              fluidRow(
                box(width = 12, title = "Mətn Seçin", status = "info",
                    uiOutput("detail_instruction")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Mətn Məzmunu", status = "primary",
                    solidHeader = TRUE, collapsible = TRUE,
                    uiOutput("text_content")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Suallar və Cavablar", status = "success",
                    solidHeader = TRUE, collapsible = TRUE,
                    uiOutput("text_questions")
                )
              )
      ),
      
      # ─────────────────────────────────────────────────────
      # TAB 3: Cognitive Balance
      # ─────────────────────────────────────────────────────
      tabItem(tabName = "cognitive",
              fluidRow(
                box(width = 12, title = "Cognitive Balance Göstəricisi", 
                    status = "warning", solidHeader = TRUE,
                    uiOutput("cognitive_status"),
                    plotOutput("cognitive_plot", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cognitive Paylanma Cədvəli", 
                    status = "info",
                    tableOutput("cognitive_table")
                )
              )
      ),
      
      # ─────────────────────────────────────────────────────
      # TAB 4: Export
      # ─────────────────────────────────────────────────────
      tabItem(tabName = "export",
              fluidRow(
                box(width = 6, title = "Export Tənzimləmələri", status = "primary",
                    textInput("export_filename", "Fayl adı:", 
                              value = sprintf("pirls_test_%s", Sys.Date())),
                    radioButtons("export_format", "Format:",
                                 choices = c("DOCX" = "docx", "PDF" = "pdf"),
                                 selected = "docx"),
                    checkboxInput("include_rubric", "Rubric daxil et", value = TRUE),
                    checkboxInput("include_answers", "Cavablar daxil et", value = TRUE),
                    hr(),
                    downloadButton("download_test", "Testi Yüklə", 
                                   class = "btn-success btn-lg btn-block")
                ),
                
                box(width = 6, title = "Test Xülasəsi", status = "info",
                    uiOutput("export_summary")
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
  
  # ─────────────────────────────────────────────────────
  # Reactive Data
  # ─────────────────────────────────────────────────────
  
  all_texts <- reactive({
    load_texts(pirls_only = input$pirls_filter)
  })
  
  selected_ids <- reactive({
    input$texts_table_rows_selected
  })
  
  selected_texts <- reactive({
    ids <- selected_ids()
    if (is.null(ids) || length(ids) == 0) {
      return(data.frame())
    }
    all_texts()[ids, ]
  })
  
  cognitive_dist <- reactive({
    ids <- selected_texts()$sample_id
    if (length(ids) == 0) return(NULL)
    get_cognitive_distribution(ids)
  })
  
  # ─────────────────────────────────────────────────────
  # Mətn Cədvəli
  # ─────────────────────────────────────────────────────
  
  output$texts_table <- renderDT({
    datatable(
      all_texts() %>% select(-sample_id),
      selection = "multiple",
      options = list(
        pageLength = 15,
        language = list(
          search = "Axtar:",
          lengthMenu = "Göstər _MENU_ sətir",
          info = "_TOTAL_ mətn arasında _START_-dən _END_-ə qədər",
          paginate = list(previous = "Əvvəl", `next` = "Sonra")
        )
      ),
      rownames = FALSE
    )
  })
  
  # ─────────────────────────────────────────────────────
  # Value Boxes
  # ─────────────────────────────────────────────────────
  
  output$total_texts <- renderValueBox({
    valueBox(
      nrow(all_texts()),
      "Ümumi Mətn",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$selected_count <- renderValueBox({
    valueBox(
      nrow(selected_texts()),
      "Seçilmiş",
      icon = icon("check"),
      color = "green"
    )
  })
  
  output$total_questions <- renderValueBox({
    valueBox(
      sum(selected_texts()$question_count, na.rm = TRUE),
      "Toplam Sual",
      icon = icon("question-circle"),
      color = "yellow"
    )
  })
  
  output$total_score <- renderValueBox({
    valueBox(
      sum(selected_texts()$total_score, na.rm = TRUE),
      "Toplam Bal",
      icon = icon("star"),
      color = "red"
    )
  })
  
  # ─────────────────────────────────────────────────────
  # Text Type Balance
  # ─────────────────────────────────────────────────────
  
  output$text_type_plot <- renderPlot({
    if (nrow(selected_texts()) == 0) {
      ggplot() + 
        annotate("text", x = 0.5, y = 0.5, 
                 label = "Mətn seçilməyib", size = 6) +
        theme_void()
    } else {
      type_counts <- as.data.frame(table(selected_texts()$text_type))
      names(type_counts) <- c("Type", "Count")
      
      ggplot(type_counts, aes(x = Type, y = Count, fill = Type)) +
        geom_bar(stat = "identity") +
        geom_text(aes(label = Count), vjust = -0.5, size = 5) +
        scale_fill_manual(values = c("Ədəbi" = "#3498db", 
                                     "İnformasiya" = "#e74c3c")) +
        labs(title = "", x = "", y = "Sayı") +
        theme_minimal() +
        theme(legend.position = "none",
              text = element_text(size = 14))
    }
  })
  
  output$text_type_status <- renderUI({
    balance <- check_text_type_balance(selected_texts(), all_texts())
    
    tagList(
      tags$h4(balance$message, 
              style = sprintf("color: %s;", balance$color))
    )
  })
  
  # ─────────────────────────────────────────────────────
  # Seçilmiş Mətnlər Cədvəli
  # ─────────────────────────────────────────────────────
  
  output$selected_texts_table <- renderTable({
    if (nrow(selected_texts()) == 0) {
      data.frame(Mesaj = "Mətn seçilməyib")
    } else {
      selected_texts() %>%
        select(Başlıq = title, Tip = text_type, 
               Suallar = question_count, Bal = total_score)
    }
  })
  
  # ─────────────────────────────────────────────────────
  # Cognitive Balance
  # ─────────────────────────────────────────────────────
  
  output$cognitive_status <- renderUI({
    balance <- check_cognitive_balance(cognitive_dist())
    
    tagList(
      tags$h3(balance$message, 
              style = sprintf("color: %s;", balance$color))
    )
  })
  
  output$cognitive_plot <- renderPlot({
    cog <- cognitive_dist()
    
    if (is.null(cog) || nrow(cog) == 0) {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, 
                 label = "Mətn seçilməyib", size = 6) +
        theme_void()
    } else {
      total <- sum(cog$count)
      cog$percentage <- 100 * cog$count / total
      
      # PIRLS standartları
      pirls <- data.frame(
        level = c("focus_retrieve", "make_inferences",
                  "interpret_integrate", "examine_evaluate"),
        min = c(30, 20, 20, 20),
        max = c(40, 25, 25, 25),
        optimal = c(35, 22.5, 22.5, 22.5)
      )
      
      cog_full <- merge(cog, pirls, by.x = "cognitive_level", by.y = "level", all.y = TRUE)
      cog_full$percentage[is.na(cog_full$percentage)] <- 0
      
      ggplot(cog_full) +
        geom_rect(aes(xmin = as.numeric(factor(cognitive_level)) - 0.4,
                      xmax = as.numeric(factor(cognitive_level)) + 0.4,
                      ymin = min, ymax = max),
                  fill = "lightgreen", alpha = 0.3) +
        geom_bar(aes(x = cognitive_level, y = percentage, fill = cognitive_level),
                 stat = "identity", width = 0.6) +
        geom_hline(aes(yintercept = optimal), linetype = "dashed", color = "blue") +
        geom_text(aes(x = cognitive_level, y = percentage, 
                      label = sprintf("%.1f%%", percentage)),
                  vjust = -0.5, size = 5) +
        scale_fill_brewer(palette = "Set2") +
        labs(title = "Cognitive Balance (yaşıl zona = PIRLS standart)",
             x = "", y = "Faiz (%)") +
        theme_minimal() +
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 45, hjust = 1),
              text = element_text(size = 12))
    }
  })
  
  output$cognitive_table <- renderTable({
    balance <- check_cognitive_balance(cognitive_dist())
    
    if (balance$status == "empty") {
      data.frame(Mesaj = "Mətn seçilməyib")
    } else {
      details <- balance$details
      details %>%
        select(
          `Cognitive Level` = cognitive_level,
          Sual = count,
          Bal = score,
          `Faiz (%)` = percentage,
          `Min (%)` = min,
          `Max (%)` = max
        )
    }
  })
  
  # ─────────────────────────────────────────────────────
  # Mətn Təfsilat - Single Text Detail
  # ─────────────────────────────────────────────────────
  
  selected_single_text <- reactive({
    ids <- selected_ids()
    if (is.null(ids) || length(ids) == 0) {
      return(NULL)
    }
    # Son seçilmiş mətn
    last_id <- ids[length(ids)]
    all_texts()[last_id, ]
  })
  
  single_text_data <- reactive({
    txt <- selected_single_text()
    if (is.null(txt)) return(NULL)
    
    get_full_test_data(txt$sample_id)
  })
  
  output$detail_instruction <- renderUI({
    if (is.null(selected_single_text())) {
      tags$div(
        tags$h4("Mətn seçin", style = "color: #3498db;"),
        tags$p("Sol tərəfdəki 'Mətn Seçimi' tabına keçin və bir mətn seçin.")
      )
    } else {
      txt <- selected_single_text()
      tags$div(
        tags$h3(txt$title, style = "color: #27ae60;"),
        tags$p(sprintf("Tip: %s | Söz sayı: %d | Sual sayı: %d | Bal: %d",
                       txt$text_type, txt$word_count, 
                       txt$question_count, txt$total_score))
      )
    }
  })
  
  output$text_content <- renderUI({
    data <- single_text_data()
    if (is.null(data)) {
      return(tags$p("Mətn seçilməyib", style = "color: gray;"))
    }
    
    content <- data$content_az[1]
    
    # ASCII cədvəl → HTML table
    convert_ascii_table <- function(table_lines) {
      # Boş sətirləri sil
      table_lines <- table_lines[table_lines != ""]
      
      if (length(table_lines) < 2) {
        return(NULL)
      }
      
      # Header (birinci sətir)
      header_cells <- strsplit(gsub("^\\|\\s*|\\s*\\|$", "", table_lines[1]), "\\|")[[1]]
      header_cells <- trimws(header_cells)
      
      # Data rows (separator-dan sonra - 3-cü sətr və sonrakılar)
      if (length(table_lines) >= 3) {
        data_rows <- table_lines[3:length(table_lines)]
      } else {
        data_rows <- c()
      }
      
      rows_html <- lapply(data_rows, function(row) {
        cells <- strsplit(gsub("^\\|\\s*|\\s*\\|$", "", row), "\\|")[[1]]
        cells <- trimws(cells)
        
        tags$tr(
          lapply(cells, function(cell) {
            tags$td(cell, style = "padding: 12px; border: 1px solid #dee2e6;
                                   text-align: left;")
          })
        )
      })
      
      tags$table(
        style = "width: 100%; border-collapse: collapse; margin: 25px 0;
                 background: white; border-radius: 8px; overflow: hidden;
                 box-shadow: 0 3px 10px rgba(0,0,0,0.1);",
        tags$thead(
          tags$tr(
            style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
            lapply(header_cells, function(cell) {
              tags$th(cell, style = "padding: 15px; color: white; font-weight: 600;
                                     text-align: left; border: 1px solid #5a67d8;")
            })
          )
        ),
        tags$tbody(rows_html)
      )
    }
    
    # Mətn bloklarını və cədvəlləri ayırmaq
    process_content <- function(text) {
      lines <- strsplit(text, "\n")[[1]]
      
      result <- list()
      i <- 1
      current_block <- c()
      in_table <- FALSE
      table_lines <- c()
      
      while (i <= length(lines)) {
        line <- lines[i]
        
        # Cədvəl sətiri? (| ilə başlayır)
        if (grepl("^\\|", line)) {
          # Əvvəlki bloku əlavə et
          if (length(current_block) > 0) {
            block_text <- paste(current_block, collapse = "\n")
            result <- c(result, process_text_block(block_text))
            current_block <- c()
          }
          
          # Cədvəl toplayırıq
          in_table <- TRUE
          table_lines <- c(table_lines, line)
        } else if (in_table && trimws(line) == "") {
          # Cədvəl bitdi
          table_html <- convert_ascii_table(table_lines)
          if (!is.null(table_html)) {
            result[[length(result) + 1]] <- table_html
          }
          table_lines <- c()
          in_table <- FALSE
        } else if (in_table) {
          # Cədvəl separator və ya boş sətir
          if (grepl("^[\\|\\-\\s]+$", line)) {
            table_lines <- c(table_lines, line)
          } else {
            # Cədvəl bitdi
            table_html <- convert_ascii_table(table_lines)
            if (!is.null(table_html)) {
              result[[length(result) + 1]] <- table_html
            }
            table_lines <- c()
            in_table <- FALSE
            current_block <- c(current_block, line)
          }
        } else {
          # Normal mətn
          current_block <- c(current_block, line)
        }
        
        i <- i + 1
      }
      
      # Son cədvəl
      if (length(table_lines) > 0) {
        table_html <- convert_ascii_table(table_lines)
        if (!is.null(table_html)) {
          result[[length(result) + 1]] <- table_html
        }
      }
      
      # Son blok
      if (length(current_block) > 0) {
        block_text <- paste(current_block, collapse = "\n")
        result <- c(result, process_text_block(block_text))
      }
      
      result
    }
    
    # Mətn bloklarını işlə (başlıq, paraqraf)
    process_text_block <- function(text) {
      result <- list()
      paragraphs <- strsplit(text, "\n\n")[[1]]
      
      for (p in paragraphs) {
        p <- trimws(p)
        if (nchar(p) == 0) next
        
        # Markdown başlıqları
        if (grepl("^###", p)) {
          title <- gsub("^###\\s+", "", p)
          result[[length(result) + 1]] <- tags$h4(
            title, 
            style = "color: #34495e; margin-top: 20px; margin-bottom: 10px;
                     font-size: 18px; font-weight: 600;"
          )
        } else if (grepl("^##", p)) {
          title <- gsub("^##\\s+", "", p)
          result[[length(result) + 1]] <- tags$h3(
            title, 
            style = "color: #2c3e50; margin-top: 25px; margin-bottom: 15px;
                     border-bottom: 3px solid #3498db; padding-bottom: 8px;
                     font-size: 22px; font-weight: 600;"
          )
        } else if (grepl("^#", p)) {
          title <- gsub("^#\\s+", "", p)
          result[[length(result) + 1]] <- tags$h2(
            title, 
            style = "color: #1a1a1a; margin-top: 30px; margin-bottom: 15px;
                     font-size: 26px; font-weight: 700;"
          )
        } else {
          # Normal paraqraf
          result[[length(result) + 1]] <- tags$p(
            HTML(gsub("\n", "<br>", p)),
            style = "font-size: 17px; line-height: 2.0; 
                     text-align: justify; margin-bottom: 15px;
                     color: #2c3e50;"
          )
        }
      }
      
      result
    }
    
    content_html <- process_content(content)
    
    tags$div(
      style = "padding: 30px; background: #ffffff; 
               border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);",
      do.call(tagList, content_html)
    )
  })
  
  output$text_questions <- renderUI({
    tryCatch({
      data <- single_text_data()
      if (is.null(data)) {
        return(tags$p("Mətn seçilməyib", style = "color: gray;"))
      }
      
      if (nrow(data) == 0) {
        return(tags$p("Bu mətn üçün sual tapılmadı", style = "color: orange;"))
      }
      
      questions_html <- lapply(1:nrow(data), function(i) {
        q <- data[i, ]
        
        # Question card
        question_div <- tags$div(
          style = "margin-bottom: 40px; padding: 25px; background: #ffffff; 
                 border-radius: 10px; box-shadow: 0 3px 15px rgba(0,0,0,0.08);
                 border-left: 5px solid #3498db;",
          
          # Sual nömrəsi və tipi
          tags$div(
            style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;",
            tags$h3(
              sprintf("Sual %d", q$question_number),
              style = "color: #2c3e50; margin: 0; font-size: 22px;"
            ),
            tags$span(
              sprintf("🎯 %d bal", q$max_score),
              style = "background: #e74c3c; color: white; padding: 5px 15px; 
                     border-radius: 20px; font-weight: bold; font-size: 14px;"
            )
          ),
          
          # Sual mətni
          tags$div(
            style = "background: #ecf0f1; padding: 20px; border-radius: 8px; 
                   margin-bottom: 20px; border-left: 4px solid #95a5a6;",
            tags$p(
              q$question_text,
              style = "font-size: 18px; font-weight: 500; margin: 0; 
                     line-height: 1.6; color: #2c3e50;"
            )
          ),
          
          # Meta məlumat
          tags$div(
            style = "display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap;",
            tags$span(
              paste("📝", q$question_type),
              style = "background: #3498db; color: white; padding: 8px 15px; 
                     border-radius: 20px; font-size: 13px;"
            ),
            tags$span(
              paste("🧠", gsub("_", " ", q$cognitive_level)),
              style = "background: #9b59b6; color: white; padding: 8px 15px; 
                     border-radius: 20px; font-size: 13px;"
            )
          )
        )
        
        # ═══════════════════════════════════════════════════
        # MULTIPLE CHOICE VARIANTLARI - NƏFIS FORMAT
        # ═══════════════════════════════════════════════════
        
        if (!is.null(q$question_type) && 
            !is.na(q$question_type) &&
            q$question_type == "multiple_choice" && 
            !is.na(q$options) && 
            !is.null(q$options) && 
            nchar(as.character(q$options)) > 0) {
          # JSON parse
          options_list <- tryCatch({
            jsonlite::fromJSON(q$options)
          }, error = function(e) {
            NULL
          })
          
          if (!is.null(options_list) && 
              (is.data.frame(options_list) || is.list(options_list))) {
            
            # data.frame-i standart formata çevir
            if (is.data.frame(options_list)) {
              n_options <- nrow(options_list)
              get_option <- function(i) as.character(options_list$option[i])
              get_text <- function(i) as.character(options_list$text[i])
            } else {
              n_options <- length(options_list)
              get_option <- function(i) as.character(options_list[[i]]$option)
              get_text <- function(i) as.character(options_list[[i]]$text)
            }
            
            options_html <- lapply(1:n_options, function(i) {
              option_letter <- get_option(i)
              option_text <- get_text(i)
              
              # Düzgün cavabmı?
              is_correct <- isTRUE(
                !is.na(q$correct_answer) && 
                  !is.null(q$correct_answer) &&
                  trimws(as.character(q$correct_answer)) == trimws(option_letter)
              )
              
              # Rəng seçimi
              bg_color <- if (is_correct) "#d4edda" else "#ffffff"
              border_color <- if (is_correct) "#28a745" else "#dee2e6"
              text_color <- if (is_correct) "#155724" else "#495057"
              icon <- if (is_correct) "✓" else ""
              
              tags$div(
                style = sprintf("background: %s; border: 2px solid %s; 
                              padding: 15px 20px; border-radius: 8px; 
                              margin-bottom: 12px; display: flex; 
                              align-items: center; transition: all 0.3s;
                              cursor: pointer;", bg_color, border_color),
                
                # Variant hərfi
                tags$div(
                  option_letter,
                  style = sprintf("background: %s; color: white; 
                                width: 40px; height: 40px; 
                                border-radius: 50%%; display: flex; 
                                align-items: center; justify-content: center; 
                                font-weight: bold; font-size: 18px; 
                                margin-right: 15px;", border_color)
                ),
                
                # Variant mətni
                tags$span(
                  option_text,
                  style = sprintf("font-size: 16px; color: %s; 
                                flex-grow: 1; line-height: 1.5;", text_color)
                ),
                
                # Düzgün nişanı
                if (is_correct) {
                  tags$span(
                    icon,
                    style = "background: #28a745; color: white; 
                          width: 35px; height: 35px; border-radius: 50%; 
                          display: flex; align-items: center; 
                          justify-content: center; font-size: 20px; 
                          font-weight: bold; margin-left: 10px;"
                  )
                } else { NULL }
              )
            })
            
            # NULL-ları filtrə et
            options_html <- Filter(Negate(is.null), options_html)
            
            if (length(options_html) > 0) {
              variants_div <- tags$div(
                style = "margin: 20px 0;",
                tags$h4("Cavab Variantları:", 
                        style = "color: #34495e; margin-bottom: 15px; font-size: 18px;"),
                do.call(tagList, options_html)
              )
              
              question_div <- tagList(question_div, variants_div)
            }
          }
        }
        
        # ═══════════════════════════════════════════════════
        # NÜMUNƏ CAVAB
        # ═══════════════════════════════════════════════════
        
        if (!is.null(q$sample_answer) && 
            !is.na(q$sample_answer) && 
            nchar(as.character(q$sample_answer)) > 0) {
          sample_div <- tags$div(
            style = "background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%); 
                   padding: 20px; border-radius: 8px; margin: 20px 0;
                   border-left: 5px solid #f39c12;",
            tags$h4("💡 Nümunə Cavab:", 
                    style = "color: #7d4e00; margin-top: 0; margin-bottom: 10px; font-size: 16px;"),
            tags$p(
              q$sample_answer,
              style = "margin: 0; font-size: 15px; line-height: 1.8; 
                     color: #2c3e50; white-space: pre-wrap;"
            )
          )
          question_div <- tagList(question_div, sample_div)
        }
        
        # ═══════════════════════════════════════════════════
        # SCORING RUBRIC
        # ═══════════════════════════════════════════════════
        
        if (!is.null(q$scoring_rubric) && 
            !is.na(q$scoring_rubric) && 
            nchar(as.character(q$scoring_rubric)) > 0) {
          # JSON parse rubric
          rubric_data <- tryCatch({
            jsonlite::fromJSON(q$scoring_rubric)
          }, error = function(e) {
            return(q$scoring_rubric)
          })
          
          if (!is.null(rubric_data) && is.list(rubric_data) && length(rubric_data) > 0) {
            # Structured rubric
            rubric_items <- lapply(names(rubric_data), function(score) {
              tags$div(
                style = "display: flex; padding: 12px; background: white; 
                       border-radius: 6px; margin-bottom: 8px;
                       border-left: 4px solid #3498db;",
                tags$div(
                  score,
                  style = "background: #3498db; color: white; 
                        width: 35px; height: 35px; border-radius: 50%; 
                        display: flex; align-items: center; 
                        justify-content: center; font-weight: bold; 
                        margin-right: 15px; font-size: 16px;"
                ),
                tags$span(
                  rubric_data[[score]],
                  style = "font-size: 14px; line-height: 1.6; color: #2c3e50;"
                )
              )
            })
            
            rubric_div <- tags$div(
              style = "background: linear-gradient(135deg, #74b9ff 0%, #a29bfe 100%); 
                     padding: 20px; border-radius: 8px; margin: 20px 0;",
              tags$h4("📊 Qiymətləndirmə Rubric:", 
                      style = "color: white; margin-top: 0; margin-bottom: 15px; font-size: 16px;"),
              do.call(tagList, rubric_items)
            )
          } else {
            # Plain text rubric
            rubric_div <- tags$div(
              style = "background: #e8f4f8; padding: 15px; 
                     border-radius: 8px; margin: 20px 0;
                     border-left: 5px solid #00b894;",
              tags$h4("📊 Qiymətləndirmə:", 
                      style = "color: #00695c; margin-top: 0; margin-bottom: 10px; font-size: 16px;"),
              tags$pre(
                q$scoring_rubric,
                style = "background: white; padding: 15px; 
                       border-radius: 6px; margin: 0; 
                       font-size: 13px; line-height: 1.6; 
                       white-space: pre-wrap; color: #2c3e50;
                       font-family: 'Courier New', monospace;"
              )
            )
          }
          
          question_div <- tagList(question_div, rubric_div)
        }
        
        question_div
      })
      
      do.call(tagList, questions_html)
    }, error = function(e) {
      tags$div(
        style = "background: #ffebee; padding: 20px; border-radius: 8px; 
                 border-left: 5px solid #e74c3c;",
        tags$h4("⚠️ Xəta baş verdi", style = "color: #c0392b; margin-top: 0;"),
        tags$p(paste("Error:", e$message), style = "color: #7f8c8d;"),
        tags$p("Mətn və ya sual məlumatları düzgün oxuna bilmədi.", 
               style = "color: #7f8c8d;")
      )
    })
  })
  
  # ─────────────────────────────────────────────────────
  # Random Generator
  # ─────────────────────────────────────────────────────
  
  observeEvent(input$generate_random, {
    random_texts <- generate_random_test(all_texts(), input$n_random)
    
    # Select rows in table
    row_indices <- which(all_texts()$sample_id %in% random_texts$sample_id)
    dataTableProxy("texts_table") %>%
      selectRows(row_indices)
    
    showNotification(
      sprintf("✅ %d mətn random seçildi!", nrow(random_texts)),
      type = "message",
      duration = 3
    )
  })
  
  # ─────────────────────────────────────────────────────
  # Export Summary
  # ─────────────────────────────────────────────────────
  
  output$export_summary <- renderUI({
    if (nrow(selected_texts()) == 0) {
      tags$p("Mətn seçilməyib", style = "color: gray; font-size: 16px;")
    } else {
      n_texts <- nrow(selected_texts())
      n_questions <- sum(selected_texts()$question_count)
      n_score <- sum(selected_texts()$total_score)
      
      type_balance <- check_text_type_balance(selected_texts(), all_texts())
      cog_balance <- check_cognitive_balance(cognitive_dist())
      
      tagList(
        tags$h4("Test Məlumatları:"),
        tags$ul(
          tags$li(sprintf("Mətn sayı: %d", n_texts)),
          tags$li(sprintf("Sual sayı: %d", n_questions)),
          tags$li(sprintf("Toplam bal: %d", n_score))
        ),
        tags$hr(),
        tags$h4("Balans:"),
        tags$p(type_balance$message, 
               style = sprintf("color: %s;", type_balance$color)),
        tags$p(cog_balance$message, 
               style = sprintf("color: %s;", cog_balance$color))
      )
    }
  })
  
  # ─────────────────────────────────────────────────────
  # Download Handler
  # ─────────────────────────────────────────────────────
  
  output$download_test <- downloadHandler(
    filename = function() {
      sprintf("%s.%s", input$export_filename, input$export_format)
    },
    content = function(file) {
      # Get full test data
      test_data <- get_full_test_data(selected_texts()$sample_id)
      
      if (input$export_format == "docx") {
        export_to_docx(test_data, file)
      } else {
        # PDF - future implementation
        showNotification("PDF export hələ hazırlanır", type = "warning")
      }
    }
  )
}

# ═══════════════════════════════════════════════════════════
# RUN APP
# ═══════════════════════════════════════════════════════════

shinyApp(ui, server)