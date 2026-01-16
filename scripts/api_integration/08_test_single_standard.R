# Test - 1 standart üçün 5 mətn
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
    model = "claude-sonnet-4-20250514",  # Ən son Sonnet 4
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

# I sinif, ilk Oxu standartı
standard <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.content_area, 
          cs.standard_text_az, g.grade_level, g.age_range
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE cs.content_area = 'Oxu' AND g.grade_level = 1
   ORDER BY cs.standard_code
   LIMIT 1")

cat("📊 Test Standartı:\n")
print(standard)
cat("\n")

# Mətn növləri
text_types <- dbGetQuery(con, 
  "SELECT text_type_id, type_name_az FROM reading_literacy.text_types")

# Best practices
best_practices <- list(
  singapore = "CPA (Concrete-Pictorial-Abstract) - konkret təcrübədən abstrakt anlayışa",
  finland = "Oyun əsaslı öyrənmə və intrinsic motivasiya",
  japan = "Lesson Study - dərin anlama və kollektiv təhlil",
  estonia = "Digital literacy və texnologiya inteqrasiyası",
  new_zealand = "Culturally responsive - mədəni həssaslıq və inklüzivlik"
)

system_prompt <- sprintf("Sən Azərbaycan dili təhsili eksperti və beynəlxalq pedaqoji best practices mütəxəssisisən.

Claude Sonnet 4 (yanvar 2025) - Ən son AI model

BEYNƏLxALQ BEST PRACTICES:
- Singapore: %s
- Finland: %s  
- Japan: %s
- Estonia: %s
- New Zealand: %s

PISA/PIRLS PRİNSİPLƏRİ:
- Mətnlər real həyat kontekstində
- Tənqidi düşüncəni inkişaf etdirir
- Müxtəlif mətn növləri
- Yaşa uyğun inkişaf

HƏR MƏTN:
✓ Azərbaycan mədəniyyəti və dəyərləri
✓ Konkret pedaqoji məqsəd
✓ Beynəlxalq standartlara uyğun
✓ Uşaqların marağı

Cavab JSON:
{
  \"title\": \"Mətn başlığı\",
  \"content\": \"Tam mətn (50-120 söz)\",
  \"word_count\": 85,
  \"themes\": [\"tema1\", \"tema2\", \"tema3\"],
  \"cultural_context\": \"Azərbaycan konteksti\",
  \"pedagogical_purpose\": \"Pedaqoji məqsəd\",
  \"best_practice_applied\": \"Tətbiq olunan best practice\",
  \"skill_focus\": \"İnkişaf edən bacarıq\"
}",
  best_practices$singapore, best_practices$finland, 
  best_practices$japan, best_practices$estonia, best_practices$new_zealand)

cat("📝 5 fərqli mətn generasiya edilir...\n\n")

for(j in 1:5) {
  cat(sprintf("=== MƏTN %d/5 ===\n", j))
  
  text_type_idx <- j
  text_type_name <- text_types$type_name_az[text_type_idx]
  text_type_id <- text_types$text_type_id[text_type_idx]
  
  bp_names <- names(best_practices)
  bp_country <- bp_names[j]
  
  cat("Mətn növü:", text_type_name, "\n")
  cat("Best practice:", bp_country, "\n\n")
  
  prompt <- sprintf(
"Standart: %s
Sinif: %d (%s)
Mətn növü: %s
Best practice: %s (%s)

Bu I sinif şagirdləri (6-7 yaş) üçün Azərbaycan mədəniyyətini əks etdirən, 
pedaqoji cəhətdən dəyərli mətn yarat.

JSON formatında cavab ver:",
    standard$standard_text_az,
    standard$grade_level,
    standard$age_range,
    text_type_name,
    bp_country,
    best_practices[[bp_country]]
  )
  
  tryCatch({
    response <- call_claude_api(prompt, system_prompt)
    clean_response <- clean_json(response)
    text_data <- fromJSON(clean_response)
    
    cat("✅ MƏTN GENERASİYA OLUNDU:\n")
    cat("Başlıq:", text_data$title, "\n")
    cat("Söz sayı:", text_data$word_count, "\n")
    cat("Temalar:", paste(text_data$themes, collapse = ", "), "\n")
    cat("\nMƏTN:\n")
    cat(text_data$content, "\n")
    cat("\nPedaqoji məqsəd:", text_data$pedagogical_purpose, "\n")
    cat("Tətbiq olunan:", text_data$best_practice_applied, "\n")
    cat("Bacarıq:", text_data$skill_focus, "\n")
    cat("\n" , strrep("-", 70), "\n\n")
    
    Sys.sleep(2)
    
  }, error = function(e) {
    cat("⚠️  Xəta:", e$message, "\n\n")
  })
}

dbDisconnect(con)
cat("✅ Test tamamlandı!\n")
