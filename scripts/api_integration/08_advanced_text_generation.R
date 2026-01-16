# Genişləndirilmiş mətn generasiyası - beynəlxalq best practices
library(httr)
library(jsonlite)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(dotenv)

setwd("~/Desktop/Azərbaycan_dili_standartlar")
load_dot_env()

# API funksiyaları
get_api_key <- function() {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if(api_key == "") stop("⚠️  ANTHROPIC_API_KEY tapılmadı!")
  return(api_key)
}

call_claude_api <- function(prompt, system_prompt = NULL) {
  api_key <- get_api_key()
  messages <- list(list(role = "user", content = prompt))
  
  body <- list(
    model = "claude-sonnet-4-20250514",  # Düzgün model adı
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

# I və II sinif Oxu standartlarını götürürük
standards <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.content_area, 
          cs.standard_text_az, g.grade_level, g.age_range
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE cs.content_area = 'Oxu' AND g.grade_level IN (1, 2)
   ORDER BY g.grade_level, cs.standard_code")

# PISA mapping-i götürürük
mappings <- dbGetQuery(con,
  "SELECT sfm.standard_id, ra.aspect_code, ra.aspect_name_az
   FROM reading_literacy.standard_framework_mapping sfm
   JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id")

cat("📊 Standart sayı:", nrow(standards), "\n")
cat("📊 Hər standart üçün 5 mətn generasiya ediləcək\n")
cat("📊 Ümumi mətn sayı:", nrow(standards) * 5, "\n\n")

# Mətn növləri
text_types <- dbGetQuery(con, 
  "SELECT text_type_id, type_name_az FROM reading_literacy.text_types")

# Beynəlxalq best practices
best_practices <- list(
  singapore = "Singapore Mathematics metodologiyası - Concrete-Pictorial-Abstract (CPA) yanaşması",
  finland = "Finlandiya təhsil sistemi - oyun əsaslı öyrənmə, tənqidi düşüncə",
  japan = "Yaponiya lesson study - dərin anlama, problem həlli",
  estonia = "Estoniya digital literacy - texnologiya inteqrasiyası",
  new_zealand = "Yeni Zelandiya kulturally responsive - mədəni uyğunluq"
)

system_prompt <- sprintf("Sən Azərbaycan dili təhsili eksperti və beynəlxalq pedaqoji best practices mütəxəssisisən.

BEYNƏLxALQ BEST PRACTICES:
- Singapore: %s
- Finland: %s  
- Japan: %s
- Estonia: %s
- New Zealand: %s

PISA/PIRLS PRİNSİPLƏRİ:
- Mətnlər real həyat kontekstində olmalıdır
- Tənqidi düşüncəni inkişaf etdirməlidir
- Müxtəlif mətn növlərini əhatə etməlidir
- Yaşa və inkişaf səviyyəsinə uyğun olmalıdır

HƏR MƏTN:
- Azərbaycan mədəniyyəti və dəyərlərini əks etdirməlidir
- Konkret pedaqoji məqsəd daşımalıdır
- Beynəlxalq standartlara uyğun olmalıdır
- Uşaqların marağına cavab verməlidir

Cavab JSON formatında:
{
  \"title\": \"Mətn başlığı\",
  \"content\": \"Mətnin tam mətni (50-120 söz)\",
  \"word_count\": 85,
  \"themes\": [\"tema1\", \"tema2\"],
  \"cultural_context\": \"Mədəni kontekst\",
  \"pedagogical_purpose\": \"Bu mətnin pedaqoji məqsədi\",
  \"best_practice_applied\": \"Hansı beynəlxalq best practice tətbiq olunub\",
  \"skill_focus\": \"Hansı bacarıq inkişaf etdirilir\"
}",
  best_practices$singapore, best_practices$finland, 
  best_practices$japan, best_practices$estonia, best_practices$new_zealand)

success_count <- 0
total_expected <- nrow(standards) * 5

cat("📝 Mətn generasiyası başlayır...\n\n")

for(i in 1:nrow(standards)) {
  std <- standards[i,]
  
  # Bu standartın PISA mapping-i
  std_mappings <- mappings %>% filter(standard_id == std$standard_id)
  pisa_aspects <- paste(std_mappings$aspect_name_az, collapse = ", ")
  
  cat(sprintf("=== STANDART %d/%d: %s ===\n", 
              i, nrow(standards), std$standard_code))
  cat("Sinif:", std$grade_level, "-", std$age_range, "\n")
  cat("Mətn:", std$standard_text_az, "\n")
  if(nrow(std_mappings) > 0) {
    cat("PISA aspektləri:", pisa_aspects, "\n")
  }
  cat("\n")
  
  # Hər standart üçün 5 fərqli mətn
  for(j in 1:5) {
    cat(sprintf("  [%d/5] Generasiya olunur...\n", j))
    
    # Mətn növünü seçirik
    text_type_idx <- ((i-1)*5 + j) %% nrow(text_types) + 1
    text_type_name <- text_types$type_name_az[text_type_idx]
    text_type_id <- text_types$text_type_id[text_type_idx]
    
    # Best practice seçirik
    bp_names <- names(best_practices)
    bp_idx <- ((i-1)*5 + j) %% length(bp_names) + 1
    bp_country <- bp_names[bp_idx]
    
    prompt <- sprintf(
"Aşağıdakı standart üçün mətn yarat:

Standart: %s
Sinif: %d (%s)
PISA aspektləri: %s
Mətn növü: %s
Tətbiq ediləcək best practice: %s (%s)

Mətn milli konteksti qorumalı, uşaqlar üçün maraqlı və pedaqoji cəhətdən dəyərli olmalıdır.

JSON formatında cavab ver (heç bir əlavə mətn olmadan):",
      std$standard_text_az,
      std$grade_level,
      std$age_range,
      ifelse(nrow(std_mappings) > 0, pisa_aspects, "Ümumi oxu bacarıqları"),
      text_type_name,
      bp_country,
      best_practices[[bp_country]]
    )
    
    tryCatch({
      response <- call_claude_api(prompt, system_prompt)
      clean_response <- clean_json(response)
      text_data <- fromJSON(clean_response)
      
      # Bazaya yazırıq
      insert_query <- sprintf(
        "INSERT INTO reading_literacy.text_samples 
         (grade_id, text_type_id, title_az, content_az, word_count, 
          complexity_level, source, themes, cultural_context)
         VALUES (
           (SELECT grade_id FROM reading_literacy.grades WHERE grade_level = %d),
           %d, '%s', '%s', %d, 
           '%s', 
           'Claude Sonnet 4 - %s - %s', 
           ARRAY[%s], 
           '%s - Pedaqoji məqsəd: %s - Best practice: %s - Bacarıq: %s'
         )
         RETURNING sample_id",
        std$grade_level,
        text_type_id,
        gsub("'", "''", text_data$title),
        gsub("'", "''", text_data$content),
        text_data$word_count,
        ifelse(std$grade_level == 1, "A1", "A1-A2"),
        std$standard_code,
        text_type_name,
        paste0("'", paste(text_data$themes, collapse = "','"), "'"),
        gsub("'", "''", text_data$cultural_context),
        gsub("'", "''", text_data$pedagogical_purpose),
        gsub("'", "''", text_data$best_practice_applied),
        gsub("'", "''", text_data$skill_focus)
      )
      
      sample_id <- dbGetQuery(con, insert_query)$sample_id
      
      cat(sprintf("      ✅ '%s' (%d söz) - ID: %d\n", 
                  text_data$title, text_data$word_count, sample_id))
      
      success_count <- success_count + 1
      Sys.sleep(2)
      
    }, error = function(e) {
      cat("      ⚠️  Xəta:", e$message, "\n")
    })
  }
  cat("\n")
}

cat("\n=== YEKUN ===\n")
cat("✅ Generasiya olunmuş mətn sayı:", success_count, "\n")
cat("📊 Gözlənilən:", total_expected, "\n")

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
