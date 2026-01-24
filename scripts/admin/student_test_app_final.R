# ═══════════════════════════════════════════════════════════
# PIRLS 2026 TEST TƏTBİQİ - Professional UI
# 4-cü sinif uşaqları üçün adaptasiya edilmiş
# SQLite Lokal + PostgreSQL Mətn
# ═══════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(DBI)
library(RSQLite)
library(RPostgreSQL)
library(httr)
library(jsonlite)
library(dotenv)

load_dot_env()

# ═══════════════════════════════════════════════════════════
# AVTOMATIK BAZA SETUP
# ═══════════════════════════════════════════════════════════

setup_database <- function() {
  db_path <- "~/Desktop/Azərbaycan_dili_standartlar/data/pirls_local.db"
  dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)
  
  if (!file.exists(db_path)) {
    con <- dbConnect(RSQLite::SQLite(), db_path)
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS students (
      student_id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_code TEXT UNIQUE,
      first_name TEXT,
      last_name TEXT,
      grade_level INTEGER DEFAULT 4,
      school_name TEXT
    )")
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS student_test_results (
      result_id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER,
      session_id INTEGER DEFAULT 1,
      text_sample_id INTEGER DEFAULT 228,
      start_time TEXT,
      end_time TEXT,
      mc_score INTEGER DEFAULT 0,
      mc_total INTEGER DEFAULT 10,
      open_score REAL DEFAULT 0,
      open_total INTEGER DEFAULT 26,
      total_score REAL DEFAULT 0,
      total_possible INTEGER DEFAULT 36,
      percentage REAL DEFAULT 0,
      is_completed INTEGER DEFAULT 0,
      duration_minutes REAL
    )")
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS student_answers (
      answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
      result_id INTEGER,
      question_id INTEGER,
      question_number INTEGER,
      question_text TEXT,
      question_type TEXT,
      student_answer TEXT,
      correct_answer TEXT,
      is_correct INTEGER,
      score_received REAL DEFAULT 0,
      max_score INTEGER,
      ai_feedback TEXT,
      rubric_level TEXT
    )")
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS ai_grading_log (
      log_id INTEGER PRIMARY KEY AUTOINCREMENT,
      answer_id INTEGER,
      ai_model TEXT DEFAULT 'gpt-4o-mini',
      prompt_tokens INTEGER,
      response_tokens INTEGER,
      ai_score REAL,
      ai_reasoning TEXT,
      confidence_score REAL,
      graded_at TEXT DEFAULT CURRENT_TIMESTAMP
    )")
    
    dbDisconnect(con)
    cat("✅ SQLite baza yaradıldı!\n")
  }
}

setup_database()

# ═══════════════════════════════════════════════════════════
# BAZA FUNKSİYALARI - SQLite Lokal
# ═══════════════════════════════════════════════════════════

get_db <- function() {
  # Lokal SQLite bazası
  db_path <- "~/Desktop/Azərbaycan_dili_standartlar/data/pirls_local.db"
  
  # Əgər baza yoxdursa, yarat
  if (!file.exists(db_path)) {
    dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)
  }
  
  dbConnect(RSQLite::SQLite(), db_path)
}

# PostgreSQL bazadan sualları oxumaq üçün
get_postgres_db <- function() {
  dbConnect(RPostgreSQL::PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

# ═══════════════════════════════════════════════════════════
# AI QİYMƏTLƏNDİRMƏ
# ═══════════════════════════════════════════════════════════

ai_grade <- function(question, answer, rubric, max_score) {
  prompt <- sprintf('Sən PIRLS mütəxəssisisən. Şagird cavabını qiymətləndir.

SUAL: %s
CAVAB: %s
RUBRİK: %s

JSON cavab ver: {"score": 2, "feedback": "...", "confidence": 0.85}',
                    question, answer, rubric)
  
  tryCatch({
    resp <- POST(
      "https://api.openai.com/v1/chat/completions",
      add_headers(
        "Authorization" = paste("Bearer", Sys.getenv("OPENAI_API_KEY")),
        "Content-Type" = "application/json"
      ),
      body = toJSON(list(
        model = "gpt-4o-mini",
        messages = list(list(role = "user", content = prompt)),
        temperature = 0.3,
        response_format = list(type = "json_object")
      ), auto_unbox = TRUE),
      encode = "json"
    )
    
    result <- content(resp, "parsed")
    if (resp$status_code != 200) stop(result$error$message)
    
    ai <- fromJSON(result$choices[[1]]$message$content)
    
    list(
      score = as.numeric(ai$score),
      feedback = ai$feedback,
      confidence = as.numeric(ai$confidence),
      tokens_in = result$usage$prompt_tokens,
      tokens_out = result$usage$completion_tokens,
      ok = TRUE
    )
  }, error = function(e) {
    list(score = 0, feedback = paste("Xəta:", e$message), ok = FALSE)
  })
}

# ═══════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════

ui <- dashboardPage(
  dashboardHeader(title = "PIRLS 2026 Oxu-Anlama Testi"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("📖 Test", tabName = "test", icon = icon("book-open")),
      menuItem("📊 Nəticə", tabName = "result", icon = icon("chart-bar"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML('
        /* ÜMUMİ */
        body { 
          font-family: "Arial", "DejaVu Sans", sans-serif;
          background: #f5f6fa;
        }
        .content-wrapper { background: #f5f6fa; }
        .box { margin: 15px; }
        
        /* MƏTN QOVLUĞU - PIRLS standartları */
        .text-container {
          background: #ffffff;
          padding: 35px 45px;
          margin: 25px 0;
          border: 4px solid #3498db;
          border-radius: 15px;
          box-shadow: 0 6px 12px rgba(0,0,0,0.1);
          line-height: 2.4;
          font-size: 21px;
          max-height: 650px;
          overflow-y: auto;
        }
        
        .text-container::-webkit-scrollbar {
          width: 12px;
        }
        
        .text-container::-webkit-scrollbar-track {
          background: #ecf0f1;
          border-radius: 10px;
        }
        
        .text-container::-webkit-scrollbar-thumb {
          background: #3498db;
          border-radius: 10px;
        }
        
        .text-title {
          color: #2c3e50;
          text-align: center;
          font-size: 28px;
          font-weight: bold;
          margin-bottom: 30px;
          padding-bottom: 15px;
          border-bottom: 3px solid #3498db;
        }
        
        .text-content p {
          text-align: justify;
          margin-bottom: 20px;
          color: #2c3e50;
          line-height: 2.4;
        }
        
        /* SUAL QOVLUĞU */
        .question-box {
          background: linear-gradient(to right, #ffffff 0%, #f8f9fa 100%);
          padding: 28px;
          margin: 25px 0;
          border-left: 7px solid #e74c3c;
          border-radius: 12px;
          box-shadow: 0 4px 8px rgba(0,0,0,0.12);
        }
        
        .question-number {
          display: inline-block;
          background: #e74c3c;
          color: white;
          padding: 8px 16px;
          border-radius: 25px;
          font-size: 18px;
          font-weight: bold;
          margin-bottom: 15px;
        }
        
        .question-text {
          font-size: 23px;
          font-weight: 600;
          color: #2c3e50;
          margin: 15px 0 25px 0;
          line-height: 1.8;
        }
        
        /* RADİO BUTTON - Böyük və aydın */
        .radio {
          margin: 16px 0;
          font-size: 20px;
          line-height: 2.0;
        }
        
        .radio label {
          color: #2c3e50;
          cursor: pointer;
          padding: 14px 20px;
          display: block;
          border: 2px solid transparent;
          border-radius: 10px;
          transition: all 0.25s ease;
          background: white;
          margin: 8px 0;
        }
        
        .radio label:hover {
          background: #e3f2fd;
          border-color: #3498db;
          transform: translateX(8px);
          box-shadow: 0 2px 8px rgba(52, 152, 219, 0.3);
        }
        
        .radio input[type="radio"] {
          margin-right: 15px;
          width: 22px;
          height: 22px;
          cursor: pointer;
          vertical-align: middle;
        }
        
        /* YAZILI CAVAB */
        textarea.form-control {
          font-size: 20px !important;
          line-height: 2.0 !important;
          padding: 18px !important;
          border: 3px solid #bdc3c7 !important;
          border-radius: 10px !important;
          font-family: "Arial", sans-serif !important;
          background: #ffffff !important;
        }
        
        textarea.form-control:focus {
          border-color: #3498db !important;
          box-shadow: 0 0 15px rgba(52, 152, 219, 0.4) !important;
          outline: none !important;
        }
        
        /* DÜYMƏLƏR */
        .btn-success {
          font-size: 22px !important;
          font-weight: bold;
          padding: 18px 60px !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 12px rgba(0,0,0,0.25) !important;
          transition: all 0.3s ease !important;
          border: none !important;
        }
        
        .btn-success:hover {
          transform: translateY(-3px) !important;
          box-shadow: 0 8px 16px rgba(0,0,0,0.35) !important;
        }
        
        .btn-lg {
          padding: 15px 50px !important;
          font-size: 20px !important;
        }
        
        /* NƏTİCƏ EKRANI */
        .result-gradient {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 45px;
          text-align: center;
          border-radius: 20px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.3);
        }
        
        .result-score {
          font-size: 72px;
          font-weight: bold;
          margin: 35px 0;
          text-shadow: 3px 3px 6px rgba(0,0,0,0.4);
          letter-spacing: 2px;
        }
        
        .result-percentage {
          font-size: 36px;
          margin: 20px 0;
        }
        
        /* DATATABLE */
        .dataTables_wrapper {
          font-size: 18px;
        }
        
        table.dataTable tbody td {
          padding: 12px !important;
          line-height: 1.6;
        }
        
        /* HTML CƏDVƏL - PIRLS standartları */
        .results-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0 12px;
          font-size: 18px;
        }
        
        .results-table thead th {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
          color: white;
          padding: 18px 15px;
          text-align: center;
          font-weight: bold;
          font-size: 20px;
          border: none;
          position: sticky;
          top: 0;
          z-index: 10;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .results-table thead th:first-child {
          border-radius: 10px 0 0 10px;
        }
        
        .results-table thead th:last-child {
          border-radius: 0 10px 10px 0;
        }
        
        .results-table tbody tr {
          background: white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.08);
          transition: all 0.3s ease;
        }
        
        .results-table tbody tr:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(52, 152, 219, 0.3);
          background: #f8f9fa;
        }
        
        .results-table tbody td {
          padding: 20px 15px;
          border: none;
          vertical-align: top;
          line-height: 1.8;
        }
        
        .results-table tbody tr td:first-child {
          border-radius: 10px 0 0 10px;
          border-left: 4px solid #3498db;
        }
        
        .results-table tbody tr td:last-child {
          border-radius: 0 10px 10px 0;
        }
        
        /* Sual nömrəsi */
        .question-num {
          display: inline-block;
          background: #e74c3c;
          color: white;
          padding: 6px 14px;
          border-radius: 20px;
          font-weight: bold;
          font-size: 18px;
        }
        
        /* Tip badge */
        .type-badge {
          display: inline-block;
          padding: 6px 14px;
          border-radius: 20px;
          font-weight: bold;
          font-size: 16px;
        }
        
        .type-mc {
          background: #3498db;
          color: white;
        }
        
        .type-open {
          background: #9b59b6;
          color: white;
        }
        
        /* Bal göstəricisi */
        .score-display {
          font-size: 22px;
          font-weight: bold;
          color: #27ae60;
        }
        
        .score-display.full-score {
          color: #27ae60;
        }
        
        .score-display.partial-score {
          color: #f39c12;
        }
        
        .score-display.zero-score {
          color: #e74c3c;
        }
        
        /* Feedback */
        .feedback-text {
          color: #555;
          font-style: italic;
          line-height: 1.8;
        }
      '))
    ),
    
    tabItems(
      tabItem("test",
              box(width = 12, title = "Şagird Məlumatı", status = "primary", solidHeader = TRUE,
                  fluidRow(
                    column(4, textInput("code", "Şagird Kodu:", placeholder = "S2024-001")),
                    column(4, textInput("fname", "Adı:", placeholder = "Ayşən")),
                    column(4, textInput("lname", "Soyadı:", placeholder = "Məmmədova"))
                  ),
                  div(style = "text-align: center; margin-top: 15px;",
                      actionButton("start", "🚀 TESTƏ BAŞLA", class = "btn-success btn-lg")
                  )
              ),
              uiOutput("test_ui")
      ),
      
      tabItem("result",
              box(width = 12, title = "📊 Test Nəticəniz", status = "success", solidHeader = TRUE,
                  uiOutput("result_ui")
              ),
              box(width = 12, title = "📝 Detallı Cavablar", status = "info", solidHeader = TRUE,
                  uiOutput("details_table")
              )
      )
    )
  )
)

# ═══════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════

server <- function(input, output, session) {
  
  v <- reactiveValues(
    started = FALSE,
    text = NULL,
    questions = NULL,
    result_id = NULL,
    done = FALSE
  )
  
  # ──────────────────────────────────────────────────────────
  # START TEST
  # ──────────────────────────────────────────────────────────
  
  observeEvent(input$start, {
    req(input$code, input$fname, input$lname)
    
    # SQLite lokal baza
    con <- get_db()
    on.exit(dbDisconnect(con))
    
    # PostgreSQL-dən mətn və sualları oxu
    pg_con <- get_postgres_db()
    on.exit(dbDisconnect(pg_con), add = TRUE)
    
    # Şagird - SQLite-a yaz
    dbExecute(con, sprintf("
      INSERT OR REPLACE INTO students (student_code, first_name, last_name, grade_level, school_name)
      VALUES ('%s', '%s', '%s', 4, 'Test Məktəbi')
    ", input$code, input$fname, input$lname))
    
    sid <- dbGetQuery(con, sprintf("SELECT student_id FROM students WHERE student_code = '%s'", input$code))$student_id[1]
    
    # Mətn - PostgreSQL-dən
    v$text <- dbGetQuery(pg_con, "SELECT * FROM reading_literacy.text_samples WHERE sample_id = 228")
    
    # Suallar - PostgreSQL-dən
    v$questions <- dbGetQuery(pg_con, "
      SELECT question_id, question_number, question_text, question_type, max_score,
             options::text as options, correct_answer
      FROM assessment.questions WHERE text_sample_id = 228
      ORDER BY question_number
    ")
    
    # Result - SQLite-a
    r <- dbGetQuery(con, sprintf("
      SELECT result_id FROM student_test_results 
      WHERE student_id = %d AND session_id = 1
    ", sid))
    
    if (nrow(r) > 0) {
      v$result_id <- r$result_id[1]
      dbExecute(con, sprintf("
        DELETE FROM ai_grading_log 
        WHERE answer_id IN (SELECT answer_id FROM student_answers WHERE result_id = %d)
      ", v$result_id))
      dbExecute(con, sprintf("DELETE FROM student_answers WHERE result_id = %d", v$result_id))
      dbExecute(con, sprintf("
        UPDATE student_test_results 
        SET start_time = datetime('now'), is_completed = 0
        WHERE result_id = %d
      ", v$result_id))
    } else {
      # Ümumi balları hesabla
      mc_total <- sum(v$questions$max_score[v$questions$question_type == 'multiple_choice'])
      open_total <- sum(v$questions$max_score[v$questions$question_type == 'open_response'])
      total_possible <- sum(v$questions$max_score)
      
      dbExecute(con, sprintf("
        INSERT INTO student_test_results
        (student_id, session_id, text_sample_id, start_time, mc_total, open_total, total_possible)
        VALUES (%d, 1, 228, datetime('now'), %d, %d, %d)
      ", sid, mc_total, open_total, total_possible))
      
      v$result_id <- dbGetQuery(con, sprintf(
        "SELECT result_id FROM student_test_results WHERE student_id = %d AND session_id = 1 ORDER BY result_id DESC LIMIT 1", 
        sid))$result_id[1]
    }
    
    v$started <- TRUE
  })
  
  # ──────────────────────────────────────────────────────────
  # TEST UI - PIRLS Standartları
  # ──────────────────────────────────────────────────────────
  
  output$test_ui <- renderUI({
    req(v$started, v$text, v$questions)
    
    # Mətn qovluğu - PIRLS formatında
    text_box <- box(
      width = 12, 
      title = "📖 Oxu və Anla", 
      status = "info", 
      solidHeader = TRUE,
      collapsible = TRUE,
      collapsed = FALSE,
      
      div(class = "text-container",
          div(class = "text-title", v$text$title_az),
          div(class = "text-content",
              HTML(gsub("\n\n", "</p><p>", 
                        gsub("\n", "<br>", 
                             paste0("<p>", v$text$content_az, "</p>"))))
          )
      )
    )
    
    # Suallar - PIRLS formatında
    q_boxes <- lapply(1:nrow(v$questions), function(i) {
      q <- v$questions[i, ]
      
      div(class = "question-box",
          div(class = "question-number", sprintf("Sual %d (%d bal)", q$question_number, q$max_score)),
          div(class = "question-text", q$question_text),
          
          if (q$question_type == "multiple_choice") {
            opts <- fromJSON(q$options)
            # SELECTED YOX - heç biri əvvəlcədən seçilməmiş
            radioButtons(
              sprintf("q%d", q$question_id),
              NULL,
              setNames(opts$option, sprintf("%s) %s", opts$option, opts$text)),
              selected = character(0)  # Heç biri seçilməyib!
            )
          } else {
            textAreaInput(
              sprintf("q%d", q$question_id), 
              NULL, 
              "", 
              rows = 5, 
              width = "100%",
              placeholder = "Cavabınızı buraya yazın..."
            )
          }
      )
    })
    
    tagList(
      text_box,
      box(width = 12, title = "❓ Suallar", status = "warning", solidHeader = TRUE,
          q_boxes,
          div(style = "text-align: center; margin-top: 30px; margin-bottom: 20px;",
              actionButton("submit", "✅ TƏSDİQ ET VƏ GÖNDƏR", 
                           class = "btn-success", 
                           style = "font-size: 24px; padding: 20px 80px;")
          )
      )
    )
  })
  
  # ──────────────────────────────────────────────────────────
  # SUBMIT
  # ──────────────────────────────────────────────────────────
  
  observeEvent(input$submit, {
    req(v$result_id, v$questions)
    
    showModal(modalDialog(
      title = "⏳ Qiymətləndirmə aparılır...",
      h4("AI cavablarınızı yoxlayır. Xahiş edirik, gözləyin..."),
      tags$div(
        style = "text-align: center; margin-top: 20px;",
        tags$img(src = "https://i.gifer.com/ZKZg.gif", height = "100px")
      ),
      footer = NULL,
      easyClose = FALSE
    ))
    
    con <- get_db()
    on.exit(dbDisconnect(con))
    
    for (i in 1:nrow(v$questions)) {
      q <- v$questions[i, ]
      ans <- input[[sprintf("q%d", q$question_id)]]
      if (is.null(ans) || ans == "") ans <- "[Cavab verilməyib]"
      
      if (q$question_type == "multiple_choice") {
        correct <- (ans == q$correct_answer)
        score <- if (correct) q$max_score else 0
        
        # SQLite-a YAZ - tam məlumat
        dbExecute(con, sprintf("
          INSERT INTO student_answers
          (result_id, question_id, question_number, question_text, question_type,
           student_answer, correct_answer, is_correct, score_received, max_score)
          VALUES (%d, %d, %d, '%s', '%s', '%s', '%s', %d, %d, %d)
        ", v$result_id, q$question_id, q$question_number,
                               gsub("'", "''", q$question_text), q$question_type,
                               ans, q$correct_answer, as.integer(correct), score, q$max_score))
        
      } else {
        # SQLite-a YAZ - əvvəlcə score=0 ilə
        dbExecute(con, sprintf("
          INSERT INTO student_answers
          (result_id, question_id, question_number, question_text, question_type,
           student_answer, max_score, score_received)
          VALUES (%d, %d, %d, '%s', '%s', '%s', %d, 0)
        ", v$result_id, q$question_id, q$question_number,
                               gsub("'", "''", q$question_text), q$question_type,
                               gsub("'", "''", ans), q$max_score))
        
        # answer_id tap
        aid <- dbGetQuery(con, sprintf(
          "SELECT answer_id FROM student_answers WHERE result_id = %d AND question_id = %d ORDER BY answer_id DESC LIMIT 1",
          v$result_id, q$question_id))$answer_id[1]
        
        # AI qiymətləndirmə
        rubric <- sprintf("%d bal: Tam və mükəmməl | %d bal: Yaxşı | 1 bal: Qismən | 0 bal: Cavab yoxdur və ya tamamilə yanlış", 
                          q$max_score, q$max_score - 1)
        ai <- ai_grade(q$question_text, ans, rubric, q$max_score)
        
        if (ai$ok) {
          # UPDATE score və feedback
          dbExecute(con, sprintf("
            UPDATE student_answers
            SET score_received = %f, ai_feedback = '%s', rubric_level = 'auto'
            WHERE answer_id = %d
          ", ai$score, gsub("'", "''", ai$feedback), aid))
          
          # LOG-a yaz
          dbExecute(con, sprintf("
            INSERT INTO ai_grading_log 
            (answer_id, ai_model, prompt_tokens, response_tokens, ai_score, ai_reasoning, confidence_score)
            VALUES (%d, 'gpt-4o-mini', %d, %d, %f, '%s', %f)
          ", aid, ai$tokens_in, ai$tokens_out, ai$score, gsub("'", "''", ai$feedback), ai$confidence))
        }
        
        Sys.sleep(0.5)
      }
    }
    
    # Hesabla - SQLite-dan oxu
    ans <- dbGetQuery(con, sprintf("
      SELECT question_type, score_received, max_score
      FROM student_answers
      WHERE result_id = %d
    ", v$result_id))
    
    mc <- ans[ans$question_type == 'multiple_choice', ]
    op <- ans[ans$question_type == 'open_response', ]
    
    mc_score <- sum(mc$score_received, na.rm = TRUE)
    op_score <- sum(op$score_received, na.rm = TRUE)
    total <- mc_score + op_score
    possible <- sum(ans$max_score, na.rm = TRUE)
    pct <- round(100 * total / possible, 2)
    
    # UPDATE - SQLite
    dbExecute(con, sprintf("
      UPDATE student_test_results
      SET mc_score = %d, open_score = %f, total_score = %f, percentage = %f,
          is_completed = 1, end_time = datetime('now'),
          duration_minutes = (julianday(datetime('now')) - julianday(start_time)) * 1440
      WHERE result_id = %d
    ", mc_score, op_score, total, pct, v$result_id))
    
    v$done <- TRUE
    removeModal()
    updateTabItems(session, "sidebar", "result")
  })
  
  # ──────────────────────────────────────────────────────────
  # RESULT - Gözəl formatda
  # ──────────────────────────────────────────────────────────
  
  output$result_ui <- renderUI({
    req(v$done, v$result_id)
    
    con <- get_db()
    on.exit(dbDisconnect(con))
    
    # SQLite-dan oxu
    r <- dbGetQuery(con, sprintf("
      SELECT 
        s.first_name || ' ' || s.last_name as student_name,
        str.mc_score as qapalı_bal,
        str.mc_total as qapalı_maksimum,
        str.open_score as açıq_bal,
        str.open_total as açıq_maksimum,
        str.total_score as ümumi_bal,
        str.total_possible as maksimum_bal,
        str.percentage as faiz
      FROM student_test_results str
      JOIN students s ON str.student_id = s.student_id
      WHERE str.result_id = %d
    ", v$result_id))
    
    if (nrow(r) == 0) return(h3("Məlumat tapılmadı"))
    
    # Qiymət hesabla
    grade <- if (r$faiz >= 90) "Əla (5)" 
    else if (r$faiz >= 70) "Yaxşı (4)"
    else if (r$faiz >= 50) "Kafi (3)"
    else if (r$faiz >= 30) "Qeyri-kafi (2)"
    else "Zəif (1)"
    
    div(class = "result-gradient",
        h2(style = "font-size: 32px; margin-bottom: 10px;", "🎓 Təbriklər!"),
        h1(style = "font-size: 36px; font-weight: bold;", r$student_name),
        div(class = "result-score", sprintf("%.1f / %d", r$ümumi_bal, r$maksimum_bal)),
        div(class = "result-percentage", sprintf("%.1f%% - %s", r$faiz, grade)),
        hr(style = "border-color: white; margin: 30px 0;"),
        fluidRow(
          column(6, 
                 h3("📝 Qapalı Suallar"),
                 h2(style = "font-size: 42px; margin-top: 15px;", sprintf("%d / %d", r$qapalı_bal, r$qapalı_maksimum))
          ),
          column(6, 
                 h3("✍️ Açıq Suallar"),
                 h2(style = "font-size: 42px; margin-top: 15px;", sprintf("%.1f / %d", r$açıq_bal, r$açıq_maksimum))
          )
        )
    )
  })
  
  output$details_table <- renderUI({
    req(v$done, v$result_id)
    
    con <- get_db()
    on.exit(dbDisconnect(con))
    
    # SQLite-dan birbaşa oxu - artıq hər şey student_answers-də var
    d <- dbGetQuery(con, sprintf("
      SELECT 
        question_number,
        question_type,
        student_answer,
        score_received,
        max_score,
        ai_feedback
      FROM student_answers
      WHERE result_id = %d
      ORDER BY question_number
    ", v$result_id))
    
    if (nrow(d) == 0) return(h3("Məlumat yoxdur"))
    
    # HTML cədvəl yaradırıq
    rows <- lapply(1:nrow(d), function(i) {
      row <- d[i, ]
      
      # Tip badge
      type_badge <- if (row$question_type == "multiple_choice") {
        '<span class="type-badge type-mc">📝 Qapalı</span>'
      } else {
        '<span class="type-badge type-open">✍️ Açıq</span>'
      }
      
      # Bal rəngi
      score_class <- if (row$score_received == row$max_score) {
        "full-score"
      } else if (row$score_received > 0) {
        "partial-score"
      } else {
        "zero-score"
      }
      
      # Cavabı qısalt
      answer_text <- if (nchar(row$student_answer) > 100) {
        paste0(substr(row$student_answer, 1, 100), "...")
      } else {
        row$student_answer
      }
      
      # Feedback
      feedback_text <- if (!is.na(row$ai_feedback) && row$ai_feedback != "") {
        sprintf('<div class="feedback-text">%s</div>', row$ai_feedback)
      } else {
        ""
      }
      
      sprintf('
        <tr>
          <td style="text-align: center;">
            <span class="question-num">%d</span>
          </td>
          <td style="text-align: center;">%s</td>
          <td>%s</td>
          <td style="text-align: center;">
            <span class="score-display %s">%.1f / %d</span>
          </td>
          <td>%s</td>
        </tr>
      ', 
              row$question_number,
              type_badge,
              answer_text,
              score_class,
              row$score_received,
              row$max_score,
              feedback_text)
    })
    
    table_html <- sprintf('
      <div style="overflow-x: auto;">
        <table class="results-table">
          <thead>
            <tr>
              <th style="width: 8%%;">Sual №</th>
              <th style="width: 12%%;">Növ</th>
              <th style="width: 35%%;">Sizin Cavabınız</th>
              <th style="width: 12%%;">Bal</th>
              <th style="width: 33%%;">Rəy</th>
            </tr>
          </thead>
          <tbody>
            %s
          </tbody>
        </table>
      </div>
    ', paste(rows, collapse = "\n"))
    
    HTML(table_html)
  })
}

# ═══════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════

shinyApp(ui, server)
