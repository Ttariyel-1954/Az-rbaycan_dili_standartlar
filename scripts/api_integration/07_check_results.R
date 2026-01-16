# Nəticələri yoxlayaq
library(RPostgreSQL)
library(DBI)
library(tidyverse)

con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

cat("=== MƏTN NÜMUNƏLƏRİ ===\n")
texts <- dbGetQuery(con,
  "SELECT sample_id, title_az, word_count, created_at
   FROM reading_literacy.text_samples
   WHERE source = 'Claude API - Generated'
   ORDER BY sample_id")
print(texts)

cat("\n=== MƏTN TƏHLİLLƏRİ ===\n")
analyses <- dbGetQuery(con,
  "SELECT 
     ts.title_az,
     ta.readability_score,
     ta.lexical_diversity,
     ta.ai_analysis
   FROM reading_literacy.text_analysis ta
   JOIN reading_literacy.text_samples ts ON ta.sample_id = ts.sample_id")
print(analyses)

cat("\n=== TAPŞIRIQLAR ===\n")
tasks <- dbGetQuery(con,
  "SELECT 
     ts.title_az as metn,
     ra.aspect_code,
     at.task_text_az,
     at.task_type,
     at.difficulty_level
   FROM reading_literacy.assessment_tasks at
   JOIN reading_literacy.text_samples ts ON at.sample_id = ts.sample_id
   JOIN reading_literacy.reading_aspects ra ON at.aspect_id = ra.aspect_id
   ORDER BY ts.title_az, at.task_id")
print(tasks)

cat("\n=== ÜMUMİ STATİSTİKA ===\n")
stats <- list(
  metn_sayi = dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.text_samples")[[1]],
  tehlil_sayi = dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.text_analysis")[[1]],
  tapshiriq_sayi = dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.assessment_tasks")[[1]],
  standart_sayi = dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.curriculum_standards")[[1]],
  mapping_sayi = dbGetQuery(con, "SELECT COUNT(*) FROM reading_literacy.standard_framework_mapping")[[1]]
)

cat("Mətn nümunələri:", stats$metn_sayi, "\n")
cat("Mətn təhlilləri:", stats$tehlil_sayi, "\n")
cat("Tapşırıqlar:", stats$tapshiriq_sayi, "\n")
cat("Standartlar:", stats$standart_sayi, "\n")
cat("Framework mappings:", stats$mapping_sayi, "\n")

dbDisconnect(con)
cat("\n✅ Yoxlama tamamlandı!\n")
