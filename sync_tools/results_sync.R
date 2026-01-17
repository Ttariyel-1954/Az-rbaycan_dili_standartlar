# NƏTİCƏLƏRİ SYNC ETMƏK
# Məktəb SQLite → ARTI PostgreSQL
# USB-dən gələn test_package.db faylını server bazasına yükləyir

library(DBI)
library(RSQLite)
library(RPostgreSQL)
library(tidyverse)

# PostgreSQL bağlantısı (ARTI server)
get_pg_connection <- function() {
  dbConnect(PostgreSQL(), 
            dbname = "azerbaijan_language_standards",
            host = "localhost", 
            port = 5432, 
            user = "royatalibova")
}

# Server cədvəllərini yarat (ilk dəfə)
create_server_tables <- function() {
  
  cat("📊 Server cədvəlləri yaradılır...\n")
  
  con <- get_pg_connection()
  
  # Schema
  dbExecute(con, "CREATE SCHEMA IF NOT EXISTS school_tests")
  
  # Students cədvəli
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS school_tests.students (
      student_id SERIAL PRIMARY KEY,
      school_name TEXT,
      class_name TEXT,
      first_name TEXT,
      last_name TEXT,
      test_date DATE,
      package_name TEXT,
      synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")
  
  # Answers cədvəli
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS school_tests.answers (
      answer_id SERIAL PRIMARY KEY,
      student_id INTEGER REFERENCES school_tests.students(student_id),
      question_id INTEGER,
      text_sample_id INTEGER,
      student_answer TEXT,
      score REAL,
      max_score INTEGER,
      feedback TEXT,
      question_type TEXT,
      cognitive_level TEXT,
      answered_at TIMESTAMP
    )
  ")
  
  # Indexes
  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_school_students 
    ON school_tests.students(school_name, test_date)
  ")
  
  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_school_answers 
    ON school_tests.answers(student_id)
  ")
  
  dbDisconnect(con)
  
  cat("✅ Server cədvəlləri hazırdır!\n")
  cat("   Schema: school_tests\n")
  cat("   Cədvəllər: students, answers\n\n")
}

# Məktəb paketini import etmək
import_school_package <- function(package_file, school_name = NULL) {
  
  if (!file.exists(package_file)) {
    stop("Fayl tapılmadı: ", package_file)
  }
  
  cat(sprintf("\n📦 Import başlayır: %s\n", basename(package_file)))
  
  # SQLite-dan oxu
  sqlite_con <- dbConnect(RSQLite::SQLite(), package_file)
  
  # Metadata
  meta <- dbGetQuery(sqlite_con, "SELECT * FROM package_metadata")
  package_name <- meta$package_name
  
  cat(sprintf("   Paket: %s\n", package_name))
  
  # Şagirdləri oxu
  students <- dbGetQuery(sqlite_con, "SELECT * FROM students")
  
  if (nrow(students) == 0) {
    dbDisconnect(sqlite_con)
    cat("⚠️  Heç bir şagird məlumatı yoxdur!\n")
    return(invisible(NULL))
  }
  
  cat(sprintf("   Şagirdlər: %d\n", nrow(students)))
  
  # Cavabları oxu
  answers <- dbGetQuery(sqlite_con, "
    SELECT 
      sa.student_id, sa.question_id, sa.student_answer,
      sa.score, sa.feedback, sa.answered_at,
      q.text_sample_id, q.max_score, q.question_type, q.cognitive_level
    FROM student_answers sa
    JOIN questions q ON sa.question_id = q.question_id
  ")
  
  cat(sprintf("   Cavablar: %d\n\n", nrow(answers)))
  
  dbDisconnect(sqlite_con)
  
  # PostgreSQL-ə yaz
  pg_con <- get_pg_connection()
  
  cat("💾 PostgreSQL-ə yazılır...\n")
  
  # Şagirdləri yaz
  student_mapping <- list()
  
  for (i in 1:nrow(students)) {
    s <- students[i,]
    
    # School name
    final_school_name <- ifelse(is.null(school_name), 
                                s$school_name, 
                                school_name)
    
    new_id <- dbGetQuery(pg_con, sprintf("
      INSERT INTO school_tests.students 
        (school_name, class_name, first_name, last_name, test_date, package_name)
      VALUES ('%s', '%s', '%s', '%s', '%s', '%s')
      RETURNING student_id
    ", 
                                         final_school_name,
                                         s$class_name,
                                         s$first_name,
                                         s$last_name,
                                         s$test_date,
                                         package_name
    ))$student_id
    
    student_mapping[[as.character(s$student_id)]] <- new_id
  }
  
  cat(sprintf("✓ %d şagird yükləndi\n", nrow(students)))
  
  # Cavabları yaz
  for (i in 1:nrow(answers)) {
    a <- answers[i,]
    
    new_student_id <- student_mapping[[as.character(a$student_id)]]
    
    dbExecute(pg_con, sprintf("
      INSERT INTO school_tests.answers 
        (student_id, question_id, text_sample_id, student_answer, 
         score, max_score, feedback, question_type, cognitive_level, answered_at)
      VALUES (%d, %d, %d, '%s', %.2f, %d, '%s', '%s', '%s', '%s')
    ",
                              new_student_id,
                              a$question_id,
                              a$text_sample_id,
                              gsub("'", "''", a$student_answer),
                              a$score,
                              a$max_score,
                              gsub("'", "''", a$feedback),
                              a$question_type,
                              a$cognitive_level,
                              a$answered_at
    ))
  }
  
  cat(sprintf("✓ %d cavab yükləndi\n", nrow(answers)))
  
  dbDisconnect(pg_con)
  
  cat("\n✅ Import tamamlandı!\n\n")
  
  # Statistika
  show_import_stats(package_name)
}

# Import statistikası
show_import_stats <- function(package_name = NULL) {
  
  con <- get_pg_connection()
  
  if (is.null(package_name)) {
    query <- "
      SELECT 
        package_name,
        COUNT(DISTINCT student_id) as students,
        COUNT(DISTINCT school_name) as schools
      FROM school_tests.students
      GROUP BY package_name
      ORDER BY package_name
    "
  } else {
    query <- sprintf("
      SELECT 
        school_name,
        class_name,
        COUNT(*) as students,
        MAX(test_date) as test_date
      FROM school_tests.students
      WHERE package_name = '%s'
      GROUP BY school_name, class_name
      ORDER BY school_name, class_name
    ", package_name)
  }
  
  stats <- dbGetQuery(con, query)
  
  dbDisconnect(con)
  
  cat("📊 STATISTIKA:\n")
  print(stats)
  cat("\n")
}

# Bütün nəticələri göstər
show_all_results <- function() {
  
  con <- get_pg_connection()
  
  cat("\n📊 MƏKTƏB TEST NƏTİCƏLƏRİ\n")
  cat("═════════════════════════════════════\n\n")
  
  # Ümumi statistika
  overall <- dbGetQuery(con, "
    SELECT 
      COUNT(DISTINCT s.student_id) as total_students,
      COUNT(DISTINCT s.school_name) as total_schools,
      COUNT(a.answer_id) as total_answers,
      ROUND(AVG(a.score / a.max_score * 100), 1) as avg_percentage
    FROM school_tests.students s
    LEFT JOIN school_tests.answers a ON s.student_id = a.student_id
  ")
  
  cat("Ümumi:\n")
  cat(sprintf("  Şagirdlər: %d\n", overall$total_students))
  cat(sprintf("  Məktəblər: %d\n", overall$total_schools))
  cat(sprintf("  Cavablar: %d\n", overall$total_answers))
  cat(sprintf("  Orta bal: %.1f%%\n\n", overall$avg_percentage))
  
  # Məktəblər üzrə
  schools <- dbGetQuery(con, "
    SELECT 
      s.school_name,
      COUNT(DISTINCT s.student_id) as students,
      ROUND(AVG(a.score / a.max_score * 100), 1) as avg_score
    FROM school_tests.students s
    LEFT JOIN school_tests.answers a ON s.student_id = a.student_id
    GROUP BY s.school_name
    ORDER BY s.school_name
  ")
  
  cat("Məktəblər üzrə:\n")
  print(schools)
  
  # Cognitive level üzrə
  cognitive <- dbGetQuery(con, "
    SELECT 
      cognitive_level,
      COUNT(*) as answers,
      ROUND(AVG(score / max_score * 100), 1) as avg_score
    FROM school_tests.answers
    GROUP BY cognitive_level
    ORDER BY cognitive_level
  ")
  
  cat("\nCognitive Level üzrə:\n")
  print(cognitive)
  
  dbDisconnect(con)
  
  cat("\n")
}

# Məktəb nəticələrini silmək (test üçün)
delete_school_results <- function(school_name) {
  
  cat(sprintf("⚠️  XƏBƏRDARLIQ: %s məktəbinin nəticələri silinəcək!\n", school_name))
  response <- readline("Davam etmək üçün 'yes' yazın: ")
  
  if (response != "yes") {
    cat("Ləğv edildi.\n")
    return(invisible(NULL))
  }
  
  con <- get_pg_connection()
  
  # Şagird ID-lərini tap
  student_ids <- dbGetQuery(con, sprintf("
    SELECT student_id FROM school_tests.students WHERE school_name = '%s'
  ", school_name))$student_id
  
  if (length(student_ids) == 0) {
    cat("Heç bir məlumat tapılmadı.\n")
    dbDisconnect(con)
    return(invisible(NULL))
  }
  
  # Cavabları sil
  dbExecute(con, sprintf("
    DELETE FROM school_tests.answers 
    WHERE student_id IN (%s)
  ", paste(student_ids, collapse = ",")))
  
  # Şagirdləri sil
  dbExecute(con, sprintf("
    DELETE FROM school_tests.students WHERE school_name = '%s'
  ", school_name))
  
  dbDisconnect(con)
  
  cat(sprintf("✅ %s məktəbinin nəticələri silindi.\n", school_name))
}

cat("✅ Results Sync Tool yükləndi\n\n")
cat("İSTİFADƏ:\n")
cat("  # İlk dəfə server cədvəllərini yarat\n")
cat("  create_server_tables()\n\n")
cat("  # Məktəb paketini import et\n")
cat("  import_school_package('test_packages/test_grade_2_20260117.db', \n")
cat("                        school_name = 'Məktəb №1')\n\n")
cat("  # Bütün nəticələrə bax\n")
cat("  show_all_results()\n\n")