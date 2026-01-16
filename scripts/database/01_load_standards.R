# Standartları PostgreSQL-ə yükləmək
library(tidyverse)
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

standards <- read_csv("data/processed/extracted_standards.csv", 
                      show_col_types = FALSE)

cat("📊 Yüklənəcək standartlar:", nrow(standards), "\n\n")

content_area_mapping <- tibble(
  code = c(1, 2, 3, 4),
  area_az = c("Dinləmə və Danışma", "Oxu", "Yazı", "Dil vahidləri")
)

standards <- standards %>%
  left_join(content_area_mapping, by = c("content_area_code" = "code"))

cat("=== MƏZMUN SAHƏLƏRİNƏ GÖRƏ BÖLGÜ ===\n")
standards %>% count(content_area_code, area_az) %>% print()

cat("\n🔌 PostgreSQL-ə qoşulur...\n")
con <- dbConnect(
  PostgreSQL(),
  dbname = "azerbaijan_language_standards",
  host = "localhost",
  port = 5432,
  user = Sys.getenv("USER")
)
cat("✅ Qoşuldu!\n\n")

# DÜZGÜN SİLMƏ - əvvəl mapping, sonra standartlar
cat("🧹 Köhnə məlumatlar təmizlənir...\n")
dbExecute(con, "DELETE FROM reading_literacy.standard_framework_mapping")
dbExecute(con, "DELETE FROM reading_literacy.curriculum_standards")
cat("✅ Təmizləndi!\n\n")

grade_1_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 1 LIMIT 1")$grade_id

cat("I sinif ID:", grade_1_id, "\n\n")
cat("📥 Standartlar bazaya yüklənir...\n")

for(i in 1:nrow(standards)) {
  std <- standards[i, ]
  
  query <- sprintf(
    "INSERT INTO reading_literacy.curriculum_standards 
     (grade_id, standard_code, content_area, standard_text_az) 
     VALUES (%d, '%s', '%s', '%s')",
    grade_1_id,
    std$standard_code,
    std$area_az,
    gsub("'", "''", std$standard_text)
  )
  
  dbExecute(con, query)
  
  if(i %% 20 == 0) cat("   ", i, "standart yükləndi...\n")
}

cat("✅ Bütün standartlar yükləndi!\n\n")

result <- dbGetQuery(con, 
  "SELECT content_area, COUNT(*) as count 
   FROM reading_literacy.curriculum_standards 
   GROUP BY content_area")

cat("=== BAZADA OLAN STANDARTLAR ===\n")
print(result)

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
