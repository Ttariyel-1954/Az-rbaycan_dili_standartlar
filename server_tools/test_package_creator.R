# TEST PAKETI YARATMA ALƏTI
# ARTI - Server tərəf
# Müəllimlər məktəblər üçün test paketləri hazırlayır

library(DBI)
library(RPostgreSQL)
library(RSQLite)
library(tidyverse)
library(jsonlite)

# PostgreSQL bağlantısı
get_pg_connection <- function() {
  dbConnect(PostgreSQL(), 
            dbname = "azerbaijan_language_standards",
            host = "localhost", 
            port = 5432, 
            user = "royatalibova")
}

# Test paketi yaratmaq - SQLite database
create_test_package <- function(
    package_name,
    grade_level,
    num_texts = 3,
    output_dir = "test_packages"
) {
  
  cat(sprintf("\n📦 Test paketi yaradılır: %s\n", package_name))
  cat(sprintf("   Sinif: %d | Mətn sayı: %d\n\n", grade_level, num_texts))
  
  # PostgreSQL-dən məlumat al
  pg_con <- get_pg_connection()
  
  # Mətnləri seç
  texts <- dbGetQuery(pg_con, sprintf("
    SELECT 
      ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
      ts.text_type_id, g.grade_id, g.grade_level, g.grade_name_az
    FROM reading_literacy.text_samples ts
    JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
    WHERE g.grade_level = %d
    ORDER BY RANDOM()
    LIMIT %d
  ", grade_level, num_texts))
  
  cat(sprintf("✓ %d mətn seçildi\n", nrow(texts)))
  
  # Sualları seç
  text_ids <- paste(texts$sample_id, collapse = ",")
  
  questions <- dbGetQuery(pg_con, sprintf("
    SELECT 
      q.question_id, q.text_sample_id, q.question_number,
      q.question_text, q.question_type, q.cognitive_level,
      q.max_score, q.options::text as options_json,
      q.correct_answer, q.sample_answer,
      q.scoring_rubric::text as rubric_json
    FROM assessment.questions q
    WHERE q.text_sample_id IN (%s)
    ORDER BY q.text_sample_id, q.question_number
  ", text_ids))
  
  cat(sprintf("✓ %d sual seçildi\n", nrow(questions)))
  
  dbDisconnect(pg_con)
  
  # SQLite paketi yarat
  package_file <- file.path(output_dir, sprintf("%s.db", package_name))
  
  if (file.exists(package_file)) {
    file.remove(package_file)
  }
  
  sqlite_con <- dbConnect(RSQLite::SQLite(), package_file)
  
  # Package metadata
  metadata <- data.frame(
    package_name = package_name,
    grade_level = grade_level,
    num_texts = num_texts,
    num_questions = nrow(questions),
    created_date = as.character(Sys.Date()),
    created_by = "ARTI",
    version = "1.0"
  )
  
  dbWriteTable(sqlite_con, "package_metadata", metadata, overwrite = TRUE)
  
  # Mətnlər
  dbWriteTable(sqlite_con, "texts", texts, overwrite = TRUE)
  
  # Suallar
  dbWriteTable(sqlite_con, "questions", questions, overwrite = TRUE)
  
  # Students cədvəli (boş)
  dbExecute(sqlite_con, "
    CREATE TABLE students (
      student_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      school_name TEXT,
      class_name TEXT,
      test_date TEXT
    )
  ")
  
  # Answers cədvəli (boş)
  dbExecute(sqlite_con, "
    CREATE TABLE student_answers (
      answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER,
      question_id INTEGER,
      student_answer TEXT,
      score REAL,
      feedback TEXT,
      answered_at TEXT
    )
  ")
  
  # Indexes
  dbExecute(sqlite_con, "CREATE INDEX idx_answers_student ON student_answers(student_id)")
  dbExecute(sqlite_con, "CREATE INDEX idx_answers_question ON student_answers(question_id)")
  
  dbDisconnect(sqlite_con)
  
  # Statistika
  file_size <- file.size(package_file) / 1024  # KB
  
  cat(sprintf("\n✅ Paket hazırdır!\n"))
  cat(sprintf("   Fayl: %s\n", package_file))
  cat(sprintf("   Həcm: %.1f KB\n", file_size))
  cat(sprintf("   Mətnlər: %d\n", nrow(texts)))
  cat(sprintf("   Suallar: %d\n", nrow(questions)))
  cat(sprintf("   Max bal: %d\n\n", sum(questions$max_score)))
  
  return(package_file)
}

# Test paketini yoxlamaq
inspect_test_package <- function(package_file) {
  
  if (!file.exists(package_file)) {
    stop("Paket tapılmadı: ", package_file)
  }
  
  con <- dbConnect(RSQLite::SQLite(), package_file)
  
  cat("\n📦 TEST PAKETI MƏLUMATI\n")
  cat("═══════════════════════════════════\n\n")
  
  # Metadata
  meta <- dbGetQuery(con, "SELECT * FROM package_metadata")
  cat("Ad:", meta$package_name, "\n")
  cat("Sinif:", meta$grade_level, "\n")
  cat("Yaradılma tarixi:", meta$created_date, "\n")
  cat("Versiya:", meta$version, "\n\n")
  
  # Mətnlər
  texts <- dbGetQuery(con, "SELECT sample_id, title_az, word_count FROM texts")
  cat("MƏTNLƏR:\n")
  for (i in 1:nrow(texts)) {
    cat(sprintf("  %d. %s (%d söz)\n", i, texts$title_az[i], texts$word_count[i]))
  }
  
  # Suallar
  questions <- dbGetQuery(con, "
    SELECT question_type, cognitive_level, COUNT(*) as count, SUM(max_score) as total_score
    FROM questions
    GROUP BY question_type, cognitive_level
  ")
  
  cat("\nSUALLAR:\n")
  print(questions)
  
  # Cədvəllər
  tables <- dbListTables(con)
  cat("\nCƏDVƏLLƏR:\n")
  for (tbl in tables) {
    row_count <- dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
    cat(sprintf("  • %s: %d sətir\n", tbl, row_count))
  }
  
  dbDisconnect(con)
  
  cat("\n")
}

# Toplu paket yaratmaq
create_packages_for_all_grades <- function() {
  
  for (grade in 1:4) {
    package_name <- sprintf("test_grade_%d_%s", grade, format(Sys.Date(), "%Y%m%d"))
    
    create_test_package(
      package_name = package_name,
      grade_level = grade,
      num_texts = 3
    )
    
    Sys.sleep(1)
  }
  
  cat("\n✅ Bütün siniflər üçün paketlər yaradıldı!\n")
  cat(sprintf("   Qovluq: test_packages/\n\n"))
  
  # Faylları göstər
  files <- list.files("test_packages", pattern = "\\.db$", full.names = TRUE)
  
  cat("YARADILMIŞ PAKETLƏR:\n")
  for (f in files) {
    size_kb <- file.size(f) / 1024
    cat(sprintf("  • %s (%.1f KB)\n", basename(f), size_kb))
  }
}

# JSON export (alternativ)
export_package_to_json <- function(package_file) {
  
  con <- dbConnect(RSQLite::SQLite(), package_file)
  
  package_data <- list(
    metadata = dbGetQuery(con, "SELECT * FROM package_metadata"),
    texts = dbGetQuery(con, "SELECT * FROM texts"),
    questions = dbGetQuery(con, "SELECT * FROM questions")
  )
  
  dbDisconnect(con)
  
  json_file <- gsub("\\.db$", ".json", package_file)
  write_json(package_data, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  cat(sprintf("✓ JSON export: %s\n", json_file))
  
  return(json_file)
}

cat("✅ Test Package Creator yükləndi\n\n")
cat("İSTİFADƏ:\n")
cat("  # Bir paket yarat\n")
cat("  pkg <- create_test_package('test_school_1', grade_level = 2, num_texts = 3)\n\n")
cat("  # Yoxla\n")
cat("  inspect_test_package(pkg)\n\n")
cat("  # Bütün siniflər üçün\n")
cat("  create_packages_for_all_grades()\n\n")

