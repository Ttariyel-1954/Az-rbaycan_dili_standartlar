# Sadə Qiymətləndirmə Sistemi - Yalnız Multiple Choice
library(DBI)
library(RPostgreSQL)
library(tidyverse)

grade_student_test <- function(student_id, test_session_id) {
  
  con <- dbConnect(PostgreSQL(), 
                   dbname = "azerbaijan_language_standards",
                   host = "localhost", 
                   port = 5432, 
                   user = "royatalibova")
  
  # Cavabları al
  answers <- dbGetQuery(con, sprintf("
    SELECT 
      sa.answer_id,
      sa.student_answer,
      q.question_type,
      q.correct_answer,
      q.cognitive_level
    FROM assessment.student_answers sa
    JOIN assessment.questions q ON sa.question_id = q.question_id
    WHERE sa.test_session_id = %d
  ", test_session_id))
  
  total_score <- 0
  max_score <- nrow(answers)
  
  # Hər cavabı qiymətləndir
  for (i in 1:nrow(answers)) {
    is_correct <- answers$student_answer[i] == answers$correct_answer[i]
    score <- ifelse(is_correct, 1, 0)
    
    feedback <- ifelse(is_correct, 
                      "Düzgün cavab! ✓", 
                      sprintf("Düzgün cavab: %s", answers$correct_answer[i]))
    
    # Bazaya yaz
    dbExecute(con, sprintf("
      UPDATE assessment.student_answers
      SET score = %d, feedback = '%s', graded_at = CURRENT_TIMESTAMP
      WHERE answer_id = %d
    ", score, gsub("'", "''", feedback), answers$answer_id[i]))
    
    total_score <- total_score + score
  }
  
  # Session-u yenilə
  percentage <- round((total_score / max_score) * 100, 1)
  
  dbExecute(con, sprintf("
    UPDATE assessment.test_sessions
    SET total_score = %f, max_score = %f, percentage = %f,
        status = 'graded', completed_at = CURRENT_TIMESTAMP
    WHERE session_id = %d
  ", total_score, max_score, percentage, test_session_id))
  
  dbDisconnect(con)
  
  cat(sprintf("✅ Qiymətləndirildi: %s/%s (%.1f%%)\n", 
              total_score, max_score, percentage))
  
  return(list(total_score = total_score, max_score = max_score, percentage = percentage))
}

generate_student_report <- function(student_id, test_session_id) {
  
  con <- dbConnect(PostgreSQL(), 
                   dbname = "azerbaijan_language_standards",
                   host = "localhost", 
                   port = 5432, 
                   user = "royatalibova")
  
  # Cognitive level statistika
  cognitive_stats <- dbGetQuery(con, sprintf("
    SELECT 
      q.cognitive_level,
      COUNT(*) as total_questions,
      SUM(COALESCE(sa.score, 0)) as total_score,
      COUNT(*) as max_score
    FROM assessment.student_answers sa
    JOIN assessment.questions q ON sa.question_id = q.question_id
    WHERE sa.test_session_id = %d
    GROUP BY q.cognitive_level
  ", test_session_id))
  
  dbDisconnect(con)
  
  # Tövsiyələr
  recommendations <- c()
  for (i in 1:nrow(cognitive_stats)) {
    performance <- cognitive_stats$total_score[i] / cognitive_stats$max_score[i]
    if (performance < 0.6) {
      if (cognitive_stats$cognitive_level[i] == "literal") {
        recommendations <- c(recommendations, "Mətnin əsas faktlarını daha diqqətlə oxu")
      } else if (cognitive_stats$cognitive_level[i] == "inferential") {
        recommendations <- c(recommendations, "Mətnin gizli mənaları haqqında düşün")
      } else {
        recommendations <- c(recommendations, "Mətnə öz fikrini bildir və əsaslandır")
      }
    }
  }
  
  return(list(
    cognitive_breakdown = cognitive_stats,
    recommendations = recommendations
  ))
}

cat("✅ Sadə qiymətləndirmə sistemi yükləndi\n")
