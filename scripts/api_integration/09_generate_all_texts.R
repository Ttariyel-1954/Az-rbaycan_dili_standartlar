# Bütün I və II sinif Oxu standartları üçün 5 mətn
library(httr)
library(jsonlite)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(dotenv)

setwd("~/Desktop/Azərbaycan_dili_standartlar")
load_dot_env()

get_api_key <- function() {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if(api_key == "") stop("⚠️  ANTHROPIC_API_KEY tapılmadı!")
  return(api_key)
}

call_claude_api <- function(prompt, system_prompt = NULL) {
  api_key <- get_api_key()
  messages <- list(list(role = "user", content = prompt))
  
  body <- list(
    model = "claude-sonnet-4-20250514",
    max_tokens = 4000,
    messages = messages
  )
  
  if(!is.null(system_prompt)) body$system <- system_prompt
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = api_key,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  
  if(status_code(response) != 200) {
    stop("API xətası: ", content(response, "text"))
  }
  
  result <- content(response, "parsed")
  return(result$content[[1]]$text)
}

clean_json <- function(text) {
  text <- gsub("```json\\s*", "", text)
  text <- gsub("```\\s*", "", text)
  return(str_trim(text))
}

cat("🔌 Bazaya qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Köhnə test mətnləri təmizləyək
cat("🧹 Köhnə mətnlər silinir...\n")
dbExecute(con, "DELETE FROM reading_literacy.assessment_tasks")
dbExecute(con, "DELETE FROM reading_literacy.text_analysis")
dbExecute(con, "DELETE FROM reading_literacy.text_samples")
cat("✅ Təmizləndi\n\n")

# I və II sinif Oxu standartları
standards <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.content_area, 
          cs.standard_text_az, g.grade_id, g.grade_level, g.age_range
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE cs.content_area = 'Oxu' AND g.grade_level IN (1, 2)
   ORDER BY g.grade_level, cs.standard_code")

cat("📊 Standart sayı:", nrow(standards), "\n")
cat("📊 Hər standart üçün 5 mətn = Ümumi", nrow(standards) * 5, "mətn\n\n")

text_types <- dbGetQuery(con, 
  "SELECT text_type_id, type_name_az FROM reading_literacy.text_types")

best_practices <- list(
  singapore = "CPA (Concrete-Pictorial-Abstract) - konkret təcrübədən abstrakt anlayışa",
  finland = "Oyun əsaslı öyrənmə və intrinsic motivasiya",
  japan = "Lesson Study - dərin anlama və kollektiv təhlil",
  estonia = "Digital literacy və texnologiya inteqrasiyası",
  new_zealand = "Culturally responsive - mədəni həssaslıq və inklüzivlik"
)

system_prompt <- sprintf("Sən Azərbaycan dili təhsili eksperti və beynəlxalq pedaqoji best practices mütəxəssisisən.

Claude Sonnet 4 - Ən güclü AI model

BEYNƏLxALQ BEST PRACTICES:
- Singapore: %s
- Finland: %s  
- Japan: %s
- Estonia: %s
- New Zealand: %s

PISA/PIRLS PRİNSİPLƏRİ:
- Real həyat konteksti
- Tənqidi düşüncə
- Müxtəlif mətn növləri
- Yaşa uyğun inkişaf

Cavab JSON:
{
  \"title\": \"Mətn başlığı\",
  \"content\": \"Tam mətn (50-120 söz)\",
  \"word_count\": 85,
  \"themes\": [\"tema1\", \"tema2\"],
  \"cultural_context\": \"Kontekst\",
  \"pedagogical_purpose\": \"Məqsəd\",
  \"best_practice_applied\": \"Best practice\",
  \"skill_focus\": \"Bacarıq\"
}",
  best_practices$singapore, best_practices$finland, 
  best_practices$japan, best_practices$estonia, best_practices$new_zealand)

success <- 0
total <- nrow(standards) * 5

cat("📝 MƏTN GENERASİYASI BAŞLAYIR\n")
cat(strrep("=", 70), "\n\n")

for(i in 1:nrow(standards)) {
  std <- standards[i,]
  
  cat(sprintf("STANDART %d/%d: %s (Sinif %d)\n", 
              i, nrow(standards), std$standard_code, std$grade_level))
  cat("Mətn:", std$standard_text_az, "\n\n")
  
  for(j in 1:5) {
    text_type_idx <- ((i-1)*5 + j - 1) %% nrow(text_types) + 1
    text_type_name <- text_types$type_name_az[text_type_idx]
    text_type_id <- text_types$text_type_id[text_type_idx]
    
    bp_names <- names(best_practices)
    bp_idx <- ((i-1)*5 + j - 1) %% length(bp_names) + 1
    bp_country <- bp_names[bp_idx]
    
    cat(sprintf("  [%d/5] %s + %s...", j, text_type_name, bp_country))
    
    prompt <- sprintf(
"Standart: %s
Sinif: %d (%s)
Mətn növü: %s
Best practice: %s

Azərbaycan mədəniyyəti, pedaqoji dəyər, uşaq marağı.
JSON:",
      std$standard_text_az, std$grade_level, std$age_range,
      text_type_name, best_practices[[bp_country]]
    )
    
    tryCatch({
      response <- call_claude_api(prompt, system_prompt)
      text_data <- fromJSON(clean_json(response))
      
      insert_query <- sprintf(
        "INSERT INTO reading_literacy.text_samples 
         (grade_id, text_type_id, title_az, content_az, word_count, 
          complexity_level, source, themes, cultural_context)
         VALUES (%d, %d, '%s', '%s', %d, '%s', 
                 'Claude Sonnet 4 - %s - %s', 
                 ARRAY[%s], 
                 'Məqsəd: %s | BP: %s | Bacarıq: %s | Kontekst: %s')
         RETURNING sample_id",
        std$grade_id, text_type_id,
        gsub("'", "''", text_data$title),
        gsub("'", "''", text_data$content),
        text_data$word_count,
        ifelse(std$grade_level == 1, "A1", "A1-A2"),
        std$standard_code, text_type_name,
        paste0("'", paste(text_data$themes, collapse = "','"), "'"),
        gsub("'", "''", text_data$pedagogical_purpose),
        gsub("'", "''", text_data$best_practice_applied),
        gsub("'", "''", text_data$skill_focus),
        gsub("'", "''", text_data$cultural_context)
      )
      
      sample_id <- dbGetQuery(con, insert_query)$sample_id
      cat(sprintf(" ✅ ID:%d '%s'\n", sample_id, text_data$title))
      success <- success + 1
      Sys.sleep(2)
      
    }, error = function(e) {
      cat(sprintf(" ❌ %s\n", e$message))
    })
  }
  cat("\n")
}

cat(strrep("=", 70), "\n")
cat(sprintf("✅ TAMAMLANDI: %d/%d mətn\n", success, total))

# Statistika
stats <- dbGetQuery(con,
  "SELECT g.grade_level, tt.type_name_az, COUNT(*) as count
   FROM reading_literacy.text_samples ts
   JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
   JOIN reading_literacy.text_types tt ON ts.text_type_id = tt.text_type_id
   GROUP BY g.grade_level, tt.type_name_az
   ORDER BY g.grade_level, tt.type_name_az")

cat("\n=== STATİSTİKA ===\n")
print(stats)

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
