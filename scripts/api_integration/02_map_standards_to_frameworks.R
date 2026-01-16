# Standartları PISA/PIRLS framework-ə uyğunlaşdırma
source('01_setup_claude_api.R')
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# PostgreSQL-ə qoşuluruq
cat("🔌 Bazaya qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Standartları və aspektləri yükləyirik
standards <- dbGetQuery(con, 
  "SELECT standard_id, standard_code, content_area, standard_text_az 
   FROM reading_literacy.curriculum_standards 
   WHERE content_area = 'Oxu'
   LIMIT 5")  # İlk 5 standartla test edirik

aspects <- dbGetQuery(con,
  "SELECT aspect_id, aspect_code, aspect_name_az, aspect_type, framework_id
   FROM reading_literacy.reading_aspects")

cat("📊 Standart sayı:", nrow(standards), "\n")
cat("📊 Aspekt sayı:", nrow(aspects), "\n\n")

# System prompt
system_prompt <- "Sən Azərbaycan dili təhsili və PISA/PIRLS qiymətləndirmə üzrə ekspertsan.
Sənin vəzifən milli kurrikulum standartlarını PISA və PIRLS oxu savadı aspektlərinə uyğunlaşdırmaqdır.

PISA aspektləri:
- PISA_LOC: Məlumatı tapmaq və çıxarmaq
- PISA_UND: Mətnə anlamaq və başa düşmək
- PISA_EVL: Qiymətləndirmək və mühakimə yürütmək
- PISA_REF: Refleksiya və tətbiq

PIRLS aspektləri:
- PIRLS_RET: Açıq-aydın verilmiş məlumatı tapmaq
- PIRLS_INF: Sadə nəticələr çıxarmaq
- PIRLS_INT: Fikirləri və məlumatları birləşdirmək
- PIRLS_EXM: Məzmunu təhlil və qiymətləndirmək

Cavabını JSON formatında ver:
{
  \"primary_aspects\": [\"aspect_code1\", \"aspect_code2\"],
  \"alignment_strength\": \"high/medium/low\",
  \"reasoning\": \"qısa izah\"
}"

# İlk standartı test edirik
cat("=== TEST: İLK STANDART ===\n")
test_std <- standards[1,]
cat("Standart:", test_std$standard_code, "\n")
cat("Mətn:", test_std$standard_text_az, "\n\n")

prompt <- sprintf(
  "Bu standartı PISA/PIRLS aspektlərinə uyğunlaşdır:
  
Standart kodu: %s
Məzmun sahəsi: %s
Standart mətni: %s

JSON formatında cavab ver.",
  test_std$standard_code,
  test_std$content_area,
  test_std$standard_text_az
)

cat("🤖 Claude API-yə sorğu göndərilir...\n")
response <- call_claude_api(prompt, system_prompt)

cat("\n📝 Claude cavabı:\n")
cat(response, "\n\n")

# JSON parse edək
tryCatch({
  mapping <- fromJSON(response)
  cat("✅ JSON parse olundu:\n")
  print(mapping)
}, error = function(e) {
  cat("⚠️  JSON parse xətası:", e$message, "\n")
})

dbDisconnect(con)
cat("\n✅ Test tamamlandı!\n")
