# Qalan bütün "Oxu" standartlarını map etmək
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

# Map edilməmiş standartları tapırıq
unmapped <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.standard_text_az
   FROM reading_literacy.curriculum_standards cs
   WHERE cs.content_area = 'Oxu'
   AND cs.standard_id NOT IN (
     SELECT standard_id FROM reading_literacy.standard_framework_mapping
   )
   ORDER BY cs.standard_code")

cat("📊 Map edilməli standart:", nrow(unmapped), "\n\n")

if(nrow(unmapped) == 0) {
  cat("✅ Bütün standartlar artıq map edilib!\n")
  dbDisconnect(con)
  quit()
}

system_prompt <- "Sən Azərbaycan dili təhsili və PISA/PIRLS qiymətləndirmə ekspertisən.

PISA aspektləri:
- PISA_LOC: Məlumatı tapmaq və çıxarmaq
- PISA_UND: Mətnə anlamaq və başa düşmək  
- PISA_EVL: Qiymətləndirmək və mühakimə yürütmək
- PISA_REF: Refleksiya və tətbiq

PIRLS aspektləri:
- PIRLS_RET: Açıq verilmiş məlumatı tapmaq
- PIRLS_INF: Sadə nəticələr çıxarmaq
- PIRLS_INT: Fikirləri birləşdirmək
- PIRLS_EXM: Məzmunu təhlil etmək

Cavab YALNIZ JSON:
{
  \"primary_aspects\": [\"kod1\", \"kod2\"],
  \"alignment_strength\": \"high/medium/low\",
  \"reasoning\": \"Azərbaycan dilində qısa izah\"
}"

success_count <- 0
error_count <- 0

cat("🤖 Mapping başlayır...\n\n")

for(i in 1:nrow(unmapped)) {
  std <- unmapped[i,]
  
  cat(sprintf("[%d/%d] %s\n", i, nrow(unmapped), std$standard_code))
  
  prompt <- sprintf(
    "Standart: %s
Mətn: %s

JSON formatında uyğunlaşdır:",
    std$standard_code, std$standard_text_az
  )
  
  tryCatch({
    response <- call_claude_api(prompt, system_prompt)
    clean_response <- clean_json(response)
    mapping <- fromJSON(clean_response)
    
    for(aspect_code in mapping$primary_aspects) {
      aspect_info <- dbGetQuery(con, sprintf(
        "SELECT aspect_id FROM reading_literacy.reading_aspects 
         WHERE aspect_code = '%s' LIMIT 1", aspect_code
      ))
      
      if(nrow(aspect_info) > 0) {
        insert_query <- sprintf(
          "INSERT INTO reading_literacy.standard_framework_mapping 
           (standard_id, aspect_id, alignment_strength, mapping_notes, mapped_by) 
           VALUES (%d, %d, '%s', '%s', 'Claude API')",
          std$standard_id,
          aspect_info$aspect_id,
          mapping$alignment_strength,
          gsub("'", "''", mapping$reasoning)
        )
        dbExecute(con, insert_query)
      }
    }
    
    cat("   ✅", paste(mapping$primary_aspects, collapse = ", "), "\n")
    success_count <- success_count + 1
    Sys.sleep(1.5)
    
  }, error = function(e) {
    cat("   ⚠️  Xəta:", e$message, "\n")
    error_count <- error_count + 1
  })
}

cat("\n=== NƏTİCƏ ===\n")
cat("✅ Uğurlu:", success_count, "\n")
cat("⚠️  Xətalı:", error_count, "\n")

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
