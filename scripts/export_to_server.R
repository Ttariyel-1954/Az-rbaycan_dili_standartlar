# ═══════════════════════════════════════════════════════════
# SERVER EXPORT - Lokal bazadan server bazaya köçürmə
# ═══════════════════════════════════════════════════════════

library(DBI)
library(RPostgreSQL)
library(jsonlite)

# ═══════════════════════════════════════════════════════════
# KONFIQURASIYA
# ═══════════════════════════════════════════════════════════

# Lokal baza
get_local_db <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

# Server baza (dəyişdirin!)
get_server_db <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "SERVER_IP",  # Məs: "192.168.1.100"
            port = 5432,
            user = "server_user",
            password = "server_password")
}

# ═══════════════════════════════════════════════════════════
# EXPORT FUNKSİYALARI
# ═══════════════════════════════════════════════════════════

export_results_to_json <- function(session_id = 1, output_file = "test_results_export.json") {
  
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  NƏTİCƏLƏRİ JSON-A EXPORT ET\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  con <- get_local_db()
  on.exit(dbDisconnect(con))
  
  # Şagirdlər
  students <- dbGetQuery(con, "SELECT * FROM assessment.students")
  cat(sprintf("📝 %d şagird\n", nrow(students)))
  
  # Test results
  results <- dbGetQuery(con, sprintf("
    SELECT * FROM assessment.student_test_results WHERE session_id = %d
  ", session_id))
  cat(sprintf("📊 %d test result\n", nrow(results)))
  
  # Answers
  answers <- dbGetQuery(con, sprintf("
    SELECT sa.* FROM assessment.student_answers sa
    JOIN assessment.student_test_results str ON sa.result_id = str.result_id
    WHERE str.session_id = %d
  ", session_id))
  cat(sprintf("✍️ %d cavab\n", nrow(answers)))
  
  # AI logs
  ai_logs <- dbGetQuery(con, sprintf("
    SELECT agl.* FROM assessment.ai_grading_log agl
    JOIN assessment.student_answers sa ON agl.answer_id = sa.answer_id
    JOIN assessment.student_test_results str ON sa.result_id = str.result_id
    WHERE str.session_id = %d
  ", session_id))
  cat(sprintf("🤖 %d AI log\n", nrow(ai_logs)))
  
  # Export
  export_data <- list(
    export_date = Sys.time(),
    session_id = session_id,
    students = students,
    test_results = results,
    student_answers = answers,
    ai_grading_logs = ai_logs
  )
  
  write(toJSON(export_data, pretty = TRUE, auto_unbox = TRUE), output_file)
  
  cat(sprintf("\n✅ Export tamamlandı: %s\n", output_file))
  cat(sprintf("📦 Fayl ölçüsü: %.2f KB\n", file.size(output_file)/1024))
  
  invisible(export_data)
}

# ═══════════════════════════════════════════════════════════

export_results_to_server <- function(session_id = 1) {
  
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  NƏTİCƏLƏRİ SERVERƏ KÖÇÜR\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  local_con <- get_local_db()
  on.exit(dbDisconnect(local_con), add = TRUE)
  
  server_con <- get_server_db()
  on.exit(dbDisconnect(server_con), add = TRUE)
  
  # Şagirdlər
  students <- dbGetQuery(local_con, "SELECT * FROM assessment.students")
  
  for (i in 1:nrow(students)) {
    s <- students[i, ]
    dbExecute(server_con, sprintf("
      INSERT INTO assessment.students 
      (student_code, first_name, last_name, grade_level, school_name)
      VALUES ('%s', '%s', '%s', %d, '%s')
      ON CONFLICT (student_code) DO NOTHING
    ", s$student_code, s$first_name, s$last_name, s$grade_level, s$school_name))
  }
  
  cat(sprintf("✅ %d şagird köçürüldü\n", nrow(students)))
  
  # Test results
  results <- dbGetQuery(local_con, sprintf("
    SELECT * FROM assessment.student_test_results WHERE session_id = %d
  ", session_id))
  
  for (i in 1:nrow(results)) {
    r <- results[i, ]
    
    # Server-də student_id tap
    server_student_id <- dbGetQuery(server_con, sprintf("
      SELECT student_id FROM assessment.students 
      WHERE student_code = (
        SELECT student_code FROM assessment.students WHERE student_id = %d
      )
    ", r$student_id))$student_id[1]
    
    # Insert result
    server_result_id <- dbGetQuery(server_con, sprintf("
      INSERT INTO assessment.student_test_results
      (student_id, session_id, start_time, end_time, duration_minutes,
       mc_score, mc_total, open_score, open_total, total_score, total_possible, percentage, is_completed)
      VALUES (%d, %d, '%s', '%s', %d, %d, %d, %f, %d, %f, %d, %f, %s)
      RETURNING result_id
    ", server_student_id, r$session_id, r$start_time, r$end_time, r$duration_minutes,
       r$mc_score, r$mc_total, r$open_score, r$open_total, r$total_score, r$total_possible,
       r$percentage, r$is_completed))$result_id[1]
    
    # Answers
    answers <- dbGetQuery(local_con, sprintf("
      SELECT * FROM assessment.student_answers WHERE result_id = %d
    ", r$result_id))
    
    for (j in 1:nrow(answers)) {
      a <- answers[j, ]
      
      server_answer_id <- dbGetQuery(server_con, sprintf("
        INSERT INTO assessment.student_answers
        (result_id, question_id, student_answer, correct_answer, is_correct, 
         score_received, max_score, ai_feedback, rubric_level)
        VALUES (%d, %d, '%s', '%s', %s, %f, %d, '%s', '%s')
        RETURNING answer_id
      ", server_result_id, a$question_id, 
         gsub("'", "''", a$student_answer), 
         ifelse(is.na(a$correct_answer), "", a$correct_answer),
         ifelse(is.na(a$is_correct), "NULL", a$is_correct),
         a$score_received, a$max_score,
         gsub("'", "''", ifelse(is.na(a$ai_feedback), "", a$ai_feedback)),
         ifelse(is.na(a$rubric_level), "", a$rubric_level)))$answer_id[1]
      
      # AI log
      ai_log <- dbGetQuery(local_con, sprintf("
        SELECT * FROM assessment.ai_grading_log WHERE answer_id = %d
      ", a$answer_id))
      
      if (nrow(ai_log) > 0) {
        al <- ai_log[1, ]
        dbExecute(server_con, sprintf("
          INSERT INTO assessment.ai_grading_log
          (answer_id, ai_model, prompt_tokens, response_tokens, ai_score, ai_reasoning, confidence_score)
          VALUES (%d, '%s', %d, %d, %f, '%s', %f)
        ", server_answer_id, al$ai_model, al$prompt_tokens, al$response_tokens,
           al$ai_score, gsub("'", "''", al$ai_reasoning), al$confidence_score))
      }
    }
  }
  
  cat(sprintf("✅ %d test result köçürüldü\n", nrow(results)))
  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("✅ EXPORT UĞURLA TAMAMLANDI!\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
}

# ═══════════════════════════════════════════════════════════

export_results_to_csv <- function(session_id = 1, output_dir = "exports") {
  
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  NƏTİCƏLƏRİ CSV-YƏ EXPORT ET\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  if (!dir.exists(output_dir)) dir.create(output_dir)
  
  con <- get_local_db()
  on.exit(dbDisconnect(con))
  
  # Summary
  summary <- dbGetQuery(con, sprintf("
    SELECT * FROM assessment.vw_test_results_summary 
    WHERE result_id IN (
      SELECT result_id FROM assessment.student_test_results WHERE session_id = %d
    )
  ", session_id))
  
  write.csv(summary, file.path(output_dir, "test_results_summary.csv"), row.names = FALSE)
  cat(sprintf("✅ %s\n", file.path(output_dir, "test_results_summary.csv")))
  
  # Detailed
  detailed <- dbGetQuery(con, sprintf("
    SELECT 
      s.student_code,
      s.first_name || ' ' || s.last_name AS student_name,
      q.question_number,
      q.question_type,
      sa.student_answer,
      sa.correct_answer,
      sa.is_correct,
      sa.score_received,
      sa.max_score,
      sa.ai_feedback
    FROM assessment.student_answers sa
    JOIN assessment.questions q ON sa.question_id = q.question_id
    JOIN assessment.student_test_results str ON sa.result_id = str.result_id
    JOIN assessment.students s ON str.student_id = s.student_id
    WHERE str.session_id = %d
    ORDER BY s.student_code, q.question_number
  ", session_id))
  
  write.csv(detailed, file.path(output_dir, "test_answers_detailed.csv"), row.names = FALSE)
  cat(sprintf("✅ %s\n", file.path(output_dir, "test_answers_detailed.csv")))
  
  cat(sprintf("\n📊 %d şagird, %d cavab export edildi\n", 
              length(unique(detailed$student_code)), nrow(detailed)))
  cat("═══════════════════════════════════════════════════════════\n\n")
}

# ═══════════════════════════════════════════════════════════
# İSTİFADƏ NÜMUNƏLƏRİ
# ═══════════════════════════════════════════════════════════

# # JSON export
# export_results_to_json(session_id = 1, output_file = "test_results.json")
# 
# # CSV export
# export_results_to_csv(session_id = 1, output_dir = "exports")
# 
# # Server export (əvvəlcə get_server_db() düzəlt!)
# export_results_to_server(session_id = 1)
