# Standartlar üçün mətn nümunələri generasiya etmək
source('01_setup_claude_api.R')
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

cat("🔌 Bazaya qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# I sinif üçün bir neçə standart götürək
standards <- dbGetQuery(con,
  "SELECT cs.standard_id, cs.standard_code, cs.standard_text_az,
          ra.aspect_name_az, ra.aspect_type
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.standard_framework_mapping sfm ON cs.standard_id = sfm.standard_id
   JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id
   WHERE cs.content_area = 'Oxu'
   AND ra.framework_id = 1  -- PISA
   ORDER BY cs.standard_code
   LIMIT 5")  # İlk 5 standart üçün test

cat("📊 Mətn generasiya ediləcək standart:", nrow(standards), "\n\n")

# Mətn növlərini götürürük
text_types <- dbGetQuery(con, 
  "SELECT text_type_id, type_name_az FROM reading_literacy.text_types")

grade_1_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 1")$grade_id

system_prompt <- "Sən Azərbaycan dili təhsili üzrə ekspert və uşaq ədəbiyyatı yazarısan.
I sinif şagirdləri (6-7 yaş) üçün yaşa uyğun, milli konteksti əks etdirən, tərbiyəvi dəyərləri 
özündə cəmləşdirən mətnlər yazırsan.

Mətn tələbləri:
- 50-100 söz arası
- Sadə, aydın cümlələr
- Azərbaycan mədəniyyəti və həyat tərzini əks etdirən
- Uşaqlar üçün maraqlı və anlaşılan
- Düzgün Azərbaycan dili normalarına uyğun

Cavabını JSON formatında ver:
{
  \"title\": \"Mətn başlığı\",
  \"content\": \"Mətnin özü\",
  \"word_count\": 75,
  \"themes\": [\"tema1\", \"tema2\"],
  \"cultural_context\": \"Milli kontekst haqqında qısa qeyd\"
}"

cat("📝 Mətn nümunələri generasiya olunur...\n\n")

for(i in 1:nrow(standards)) {
  std <- standards[i,]
  
  cat(sprintf("[%d/%d] %s - %s\n", i, nrow(standards), 
              std$standard_code, std$aspect_name_az))
  
  # Mətn növünü seçirik (ilk üçü continuous mətnlər)
  text_type <- sample(1:3, 1)  # Təsviri, Nəqli, İzahlı
  
  prompt <- sprintf(
"I sinif şagirdləri üçün bu standartı əks etdirən mətn yaz:

Standart: %s
Oxu aspekti: %s (%s)

Mətn növü: %s

JSON formatında ver.",
    std$standard_text_az,
    std$aspect_name_az,
    std$aspect_type,
    text_types$type_name_az[text_type]
  )
  
  tryCatch({
    response <- call_claude_api(prompt, system_prompt)
    
    # JSON təmizləyib parse edirik
    clean_response <- gsub("```json\\s*", "", response)
    clean_response <- gsub("```\\s*", "", clean_response)
    clean_response <- str_trim(clean_response)
    
    text_data <- fromJSON(clean_response)
    
    # Bazaya əlavə edirik
    insert_query <- sprintf(
      "INSERT INTO reading_literacy.text_samples 
       (grade_id, text_type_id, title_az, content_az, word_count, 
        complexity_level, source, themes, cultural_context)
       VALUES (%d, %d, '%s', '%s', %d, 'A1', 'Claude API - Generated', 
               ARRAY[%s], '%s')
       RETURNING sample_id",
      grade_1_id,
      text_type,
      gsub("'", "''", text_data$title),
      gsub("'", "''", text_data$content),
      text_data$word_count,
      paste0("'", paste(text_data$themes, collapse = "','"), "'"),
      gsub("'", "''", text_data$cultural_context)
    )
    
    sample_id <- dbGetQuery(con, insert_query)$sample_id
    
    cat("   ✅ Mətn generasiya olundu (ID:", sample_id, ")\n")
    cat("      Başlıq:", text_data$title, "\n")
    cat("      Söz sayı:", text_data$word_count, "\n\n")
    
    Sys.sleep(2)
    
  }, error = function(e) {
    cat("   ⚠️  Xəta:", e$message, "\n\n")
  })
}

# Generasiya olunmuş mətnləri göstəririk
cat("=== GENERASİYA OLUNMUŞ MƏTNLƏRİ ===\n")
texts <- dbGetQuery(con,
  "SELECT title_az, word_count, themes, cultural_context
   FROM reading_literacy.text_samples
   ORDER BY created_at DESC
   LIMIT 5")

print(texts)

dbDisconnect(con)
cat("\n✅ Mətn generasiyası tamamlandı!\n")
