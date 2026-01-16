# Tam mapping sistemi - bütün standartlar üçün
source('01_setup_claude_api.R')
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# JSON təmizləmə funksiyası
clean_json <- function(text) {
  # Markdown code block təmizləyirik
  text <- gsub("```json\\s*", "", text)
  text <- gsub("```\\s*", "", text)
  text <- str_trim(text)
  return(text)
}

# PostgreSQL qoşulma
cat("🔌 Bazaya qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Yalnız "Oxu" standartlarını götürürük
standards <- dbGetQuery(con, 
  "SELECT standard_id, standard_code, content_area, standard_text_az 
   FROM reading_literacy.curriculum_standards 
   WHERE content_area = 'Oxu'
   ORDER BY standard_code")

cat("📊 Oxu standartları:", nrow(standards), "\n\n")

# System prompt
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

Cavab YALNIZ JSON formatında, heç bir əlavə mətn olmadan:
{
  \"primary_aspects\": [\"kod1\", \"kod2\"],
  \"alignment_strength\": \"high/medium/low\",
  \"reasoning\": \"Azərbaycan dilində qısa izah\"
}"

# Mapping məlumatlarını saxlayacağıq
mappings_df <- tibble()

cat("🤖 Standartlar uyğunlaşdırılır...\n\n")

for(i in 1:min(10, nrow(standards))) {  # İlk 10 standart
  std <- standards[i,]
  
  cat(sprintf("[%d/%d] %s - %s\n", i, nrow(standards), 
              std$standard_code, substr(std$standard_text_az, 1, 50)))
  
  prompt <- sprintf(
    "Standart: %s
Mətn: %s

JSON formatında uyğunlaşdır (heç bir əlavə mətn olmadan):",
    std$standard_code, std$standard_text_az
  )
  
  tryCatch({
    response <- call_claude_api(prompt, system_prompt)
    
    # JSON təmizləyirik
    clean_response <- clean_json(response)
    
    # Parse edirik
    mapping <- fromJSON(clean_response)
    
    # Hər aspekt üçün ayrıca sətir
    for(aspect_code in mapping$primary_aspects) {
      # Aspect ID tapırıq
      aspect_info <- dbGetQuery(con, sprintf(
        "SELECT aspect_id FROM reading_literacy.reading_aspects 
         WHERE aspect_code = '%s' LIMIT 1", aspect_code
      ))
      
      if(nrow(aspect_info) > 0) {
        # Bazaya yazırıq
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
    
    cat("   ✅", paste(mapping$primary_aspects, collapse = ", "), 
        "-", mapping$alignment_strength, "\n")
    
    Sys.sleep(1)  # Rate limiting
    
  }, error = function(e) {
    cat("   ⚠️  Xəta:", e$message, "\n")
  })
}

# Nəticələri yoxlayırıq
cat("\n\n=== MAPPING NƏTİCƏLƏRİ ===\n")
results <- dbGetQuery(con, 
  "SELECT 
     cs.standard_code,
     cs.standard_text_az,
     ra.aspect_code,
     ra.aspect_name_az,
     sfm.alignment_strength
   FROM reading_literacy.standard_framework_mapping sfm
   JOIN reading_literacy.curriculum_standards cs ON sfm.standard_id = cs.standard_id
   JOIN reading_literacy.reading_aspects ra ON sfm.aspect_id = ra.aspect_id
   ORDER BY cs.standard_code, ra.aspect_code")

print(results)

# CSV-yə saxlayırıq
write_csv(results, "data/processed/standard_framework_mappings.csv")
cat("\n✅ Mappings saxlanıldı: data/processed/standard_framework_mappings.csv\n")

dbDisconnect(con)
cat("✅ Proses tamamlandı!\n")
