# II sinif üçün təkmilləşdirilmiş mətn generasiyası
# Claude Sonnet 4.5 + Beynəlxalq təcrübə
library(httr)
library(jsonlite)
library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(dotenv)

setwd("~/Desktop/Azərbaycan_dili_standartlar")
load_dot_env()

# API funksiyası - Sonnet 4.5
call_claude_api <- function(prompt, system_prompt = NULL) {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if(api_key == "") stop("⚠️  ANTHROPIC_API_KEY tapılmadı!")
  
  messages <- list(list(role = "user", content = prompt))
  
  body <- list(
    model = "claude-sonnet-4.5-20250514",  # Sonnet 4.5
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

# II sinif Oxu standartlarını götürürük
standards <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.standard_text_az
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE g.grade_level = 2 AND cs.content_area = 'Oxu'
   ORDER BY cs.standard_code")

cat("📊 II sinif Oxu standartları:", nrow(standards), "\n\n")

# Mətn növlərini götürürük
text_types <- dbGetQuery(con, 
  "SELECT text_type_id, type_name_az, category FROM reading_literacy.text_types")

grade_2_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 2")$grade_id

# Təkmilləşdirilmiş system prompt - beynəlxalq təcrübə
system_prompt <- "Sən Azərbaycan dili təhsili üzrə ekspert və peşəkar uşaq ədəbiyyatı yazarısan.

II sinif şagirdləri (7-8 yaş) üçün mətnlər yaradırsan. Beynəlxalq təcrübədən istifadə edirsən:

**Finlandiya təcrübəsi:**
- Həyata yaxın, praktiki situasiyalar
- Problem həllinə yönəlmə
- Sosial-emosional inkişaf

**Sinqapur təcrübəsi:**
- Strukturlaşdırılmış, mərhələli mətnlər
- Vizual dəstək və təsvir
- Konkret-Mücərrəd keçid

**Estoniya təcrübəsi:**
- Texnologiya və təbiət inteqrasiyası
- İstifadəçi marağına əsaslanan mövzular
- Yaradıcı düşüncənin stimullaşdırılması

**Yaponiya təcrübəsi:**
- Dəqiqlik və incəlik
- Mədəni dəyərlər və ədəb qaydaları
- Kollektiv məsuliyyət

**Mətn tələbləri:**
- 100-150 söz arası (I sinifdən artıq)
- Cümlələr 8-12 söz (mürəkkəbləşir)
- Azərbaycan mədəniyyəti və milli dəyərlər
- Yaşa uyğun lüğət (CEFR A1-A2 arası)
- Tərbiyəvi və inkişafedici məzmun

Cavab JSON formatında:
{
  \"title\": \"Mətn başlığı\",
  \"content\": \"Mətnin özü\",
  \"word_count\": 120,
  \"themes\": [\"tema1\", \"tema2\", \"tema3\"],
  \"cultural_context\": \"Azərbaycan konteksti\",
  \"international_approach\": \"Hansı ölkə təcrübəsi\",
  \"pedagogical_goal\": \"Pedaqoji məqsəd\"
}"

cat("📝 Hər standart üçün 5 mətn generasiya olunur...\n\n")

texts_per_standard <- 5
total_generated <- 0

for(std_idx in 1:nrow(standards)) {
  std <- standards[std_idx,]
  
  cat(sprintf("=== STANDART %d/%d: %s ===\n", std_idx, nrow(standards), std$standard_code))
  cat("Mətn:", substr(std$standard_text_az, 1, 60), "...\n\n")
  
  for(text_num in 1:texts_per_standard) {
    cat(sprintf("  [%d/%d] Generasiya olunur...\n", text_num, texts_per_standard))
    
    # Mətn növünü seçirik (müxtəlif)
    text_type_idx <- ((text_num - 1) %% 3) + 1  # Dövr edir: 1,2,3,1,2,3...
    text_type <- text_types[text_type_idx,]
    
    prompt <- sprintf(
"II sinif şagirdləri üçün bu standartı əks etdirən mətn yaz:

Standart: %s
Mətn növü: %s

Beynəlxalq təcrübədən istifadə et (Finlandiya, Sinqapur, Estoniya, Yaponiya).
Mövzu №%d üçün fərqli mövzu seç.

YALNIZ JSON formatında cavab ver.",
      std$standard_text_az,
      text_type$type_name_az,
      text_num
    )
    
    tryCatch({
      response <- call_claude_api(prompt, system_prompt)
      clean_response <- clean_json(response)
      text_data <- fromJSON(clean_response)
      
      # Bazaya əlavə edirik
      insert_query <- sprintf(
        "INSERT INTO reading_literacy.text_samples 
         (grade_id, text_type_id, title_az, content_az, word_count, 
          complexity_level, source, themes, cultural_context)
         VALUES (%d, %d, '%s', '%s', %d, 'A1-A2', 'Claude Sonnet 4.5 - %s', 
                 ARRAY[%s], '%s || Pedaqoji məqsəd: %s')
         RETURNING sample_id",
        grade_2_id,
        text_type$text_type_id,
        gsub("'", "''", text_data$title),
        gsub("'", "''", text_data$content),
        text_data$word_count,
        text_data$international_approach,
        paste0("'", paste(text_data$themes, collapse = "','"), "'"),
        gsub("'", "''", text_data$cultural_context),
        gsub("'", "''", text_data$pedagogical_goal)
      )
      
      sample_id <- dbGetQuery(con, insert_query)$sample_id
      
      cat("      ✅ ID:", sample_id, "| Başlıq:", text_data$title, "\n")
      cat("         Söz:", text_data$word_count, "| Yanaşma:", text_data$international_approach, "\n")
      
      total_generated <- total_generated + 1
      Sys.sleep(2)  # Rate limiting
      
    }, error = function(e) {
      cat("      ⚠️  Xəta:", e$message, "\n")
    })
  }
  
  cat("\n")
}

cat("=== YEKUN ===\n")
cat("✅ Generasiya olunmuş mətn sayı:", total_generated, "\n")
cat("📊 Gözlənilən:", nrow(standards) * texts_per_standard, "\n")

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
