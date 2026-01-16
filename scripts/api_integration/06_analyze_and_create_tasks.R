# Mətnləri təhlil edib tapşırıqlar generasiya etmək
source('01_setup_claude_api.R')
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

cat("🔌 Bazaya qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Generasiya olunmuş mətnləri götürürük
texts <- dbGetQuery(con,
  "SELECT sample_id, title_az, content_az, word_count
   FROM reading_literacy.text_samples
   WHERE source = 'Claude API - Generated'
   ORDER BY created_at DESC")

cat("📊 Təhlil ediləcək mətn:", nrow(texts), "\n\n")

system_prompt_analysis <- "Sən I sinif şagirdləri üçün mətnləri təhlil edən ekspertisən.
Mətnin oxunabilirlik səviyyəsini, leksik müxtəlifliyini və PISA/PIRLS aspektlərə 
uyğunluğunu qiymətləndir.

Cavab JSON formatında:
{
  \"readability_score\": 85.5,
  \"lexical_diversity\": 0.75,
  \"sentence_complexity\": {\"avg_words_per_sentence\": 8, \"complex_sentences\": 2},
  \"key_vocabulary\": [\"söz1\", \"söz2\", \"söz3\"],
  \"pisa_alignment\": {\"PISA_LOC\": \"high\", \"PISA_UND\": \"medium\"},
  \"pirls_alignment\": {\"PIRLS_RET\": \"high\"},
  \"analysis_notes\": \"Təhlil qeydi\"
}"

system_prompt_tasks <- "Sən I sinif şagirdləri üçün oxu tapşırıqları yaradan ekspertisən.
Verilən mətn üçün PISA/PIRLS aspektlərinə uyğun suallar və tapşırıqlar hazırla.

Cavab JSON array formatında (3 tapşırıq):
[
  {
    \"task_text\": \"Sual mətni\",
    \"task_type\": \"multiple_choice/open_ended/matching\",
    \"aspect_code\": \"PISA_LOC\",
    \"expected_response\": \"Gözlənilən cavab\",
    \"difficulty_level\": \"easy/medium/hard\"
  }
]"

cat("📝 Mətnlər təhlil edilir və tapşırıqlar yaradılır...\n\n")

for(i in 1:min(3, nrow(texts))) {  # İlk 3 mətn
  text <- texts[i,]
  
  cat(sprintf("[%d/%d] %s\n", i, nrow(texts), text$title_az))
  
  # 1. Mətn təhlili
  cat("   🔍 Təhlil edilir...\n")
  
  analysis_prompt <- sprintf(
    "Bu I sinif mətnini təhlil et:
    
Başlıq: %s
Mətn: %s
Söz sayı: %d

JSON formatında cavab ver.",
    text$title_az, text$content_az, text$word_count
  )
  
  tryCatch({
    analysis_response <- call_claude_api(analysis_prompt, system_prompt_analysis)
    clean_analysis <- gsub("```json\\s*", "", analysis_response)
    clean_analysis <- gsub("```\\s*", "", clean_analysis)
    analysis_data <- fromJSON(str_trim(clean_analysis))
    
    # Təhlili bazaya yazırıq
    insert_analysis <- sprintf(
      "INSERT INTO reading_literacy.text_analysis
       (sample_id, readability_score, lexical_diversity, 
        sentence_complexity, key_vocabulary, pisa_alignment, pirls_alignment, ai_analysis)
       VALUES (%d, %.2f, %.3f, '%s', '%s', '%s', '%s', '%s')",
      text$sample_id,
      analysis_data$readability_score,
      analysis_data$lexical_diversity,
      toJSON(analysis_data$sentence_complexity, auto_unbox = TRUE),
      toJSON(analysis_data$key_vocabulary, auto_unbox = TRUE),
      toJSON(analysis_data$pisa_alignment, auto_unbox = TRUE),
      toJSON(analysis_data$pirls_alignment, auto_unbox = TRUE),
      gsub("'", "''", analysis_data$analysis_notes)
    )
    
    dbExecute(con, insert_analysis)
    cat("      ✅ Təhlil saxlanıldı (Readability:", analysis_data$readability_score, ")\n")
    
    Sys.sleep(2)
    
  }, error = function(e) {
    cat("      ⚠️  Təhlil xətası:", e$message, "\n")
  })
  
  # 2. Tapşırıqlar generasiyası
  cat("   📋 Tapşırıqlar yaradılır...\n")
  
  tasks_prompt <- sprintf(
    "Bu mətn üçün 3 tapşırıq yarat:
    
Başlıq: %s
Mətn: %s

JSON array formatında ver.",
    text$title_az, text$content_az
  )
  
  tryCatch({
    tasks_response <- call_claude_api(tasks_prompt, system_prompt_tasks)
    clean_tasks <- gsub("```json\\s*", "", tasks_response)
    clean_tasks <- gsub("```\\s*", "", clean_tasks)
    tasks_data <- fromJSON(str_trim(clean_tasks))
    
    # Hər tapşırığı bazaya yazırıq
    for(j in 1:nrow(tasks_data)) {
      task <- tasks_data[j,]
      
      # Aspect ID tapırıq
      aspect_info <- dbGetQuery(con, sprintf(
        "SELECT aspect_id FROM reading_literacy.reading_aspects 
         WHERE aspect_code = '%s' LIMIT 1", task$aspect_code
      ))
      
      if(nrow(aspect_info) > 0) {
        insert_task <- sprintf(
          "INSERT INTO reading_literacy.assessment_tasks
           (sample_id, aspect_id, task_text_az, task_type, 
            expected_response, difficulty_level)
           VALUES (%d, %d, '%s', '%s', '%s', '%s')",
          text$sample_id,
          aspect_info$aspect_id,
          gsub("'", "''", task$task_text),
          task$task_type,
          gsub("'", "''", task$expected_response),
          task$difficulty_level
        )
        
        dbExecute(con, insert_task)
      }
    }
    
    cat("      ✅", nrow(tasks_data), "tapşırıq yaradıldı\n")
    
    Sys.sleep(2)
    
  }, error = function(e) {
    cat("      ⚠️  Tapşırıq xətası:", e$message, "\n")
  })
  
  cat("\n")
}

cat("=== NƏTİCƏ CƏDVƏLİ ===\n")
summary <- dbGetQuery(con,
  "SELECT 
     ts.title_az,
     ta.readability_score,
     ta.lexical_diversity,
     COUNT(at.task_id) as task_count
   FROM reading_literacy.text_samples ts
   LEFT JOIN reading_literacy.text_analysis ta ON ts.sample_id = ta.sample_id
   LEFT JOIN reading_literacy.assessment_tasks at ON ts.sample_id = at.sample_id
   WHERE ts.source = 'Claude API - Generated'
   GROUP BY ts.title_az, ta.readability_score, ta.lexical_diversity
   ORDER BY ts.created_at DESC")

print(summary)

dbDisconnect(con)
cat("\n✅ Təhlil və tapşırıq generasiyası tamamlandı!\n")
