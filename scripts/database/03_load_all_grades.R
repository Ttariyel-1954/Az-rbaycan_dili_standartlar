# I və II sinif standartlarını yükləmək
library(tidyverse)
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

cat("🔌 PostgreSQL-ə qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Köhnə standartları təmizləyirik
cat("🧹 Köhnə standartlar silinir...\n")
dbExecute(con, "DELETE FROM reading_literacy.standard_framework_mapping")
dbExecute(con, "DELETE FROM reading_literacy.curriculum_standards")
cat("✅ Təmizləndi!\n\n")

# I sinif
cat("=== I SİNİF ===\n")
grade_1_standards <- read_csv("data/processed/extracted_standards.csv", show_col_types = FALSE)
content_mapping <- tibble(
  code = c(1, 2, 3, 4),
  area_az = c("Dinləmə və Danışma", "Oxu", "Yazı", "Dil vahidləri")
)
grade_1_standards <- grade_1_standards %>%
  left_join(content_mapping, by = c("content_area_code" = "code"))

grade_1_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 1")$grade_id

for(i in 1:nrow(grade_1_standards)) {
  std <- grade_1_standards[i,]
  dbExecute(con, sprintf(
    "INSERT INTO reading_literacy.curriculum_standards 
     (grade_id, standard_code, content_area, standard_text_az) 
     VALUES (%d, '%s', '%s', '%s')",
    grade_1_id, std$standard_code, std$area_az, gsub("'", "''", std$standard_text)
  ))
}
cat("✅ I sinif:", nrow(grade_1_standards), "standart yükləndi\n\n")

# II sinif
cat("=== II SİNİF ===\n")
grade_2_standards <- read_csv("data/processed/grade_2_standards.csv", show_col_types = FALSE)

grade_2_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 2")$grade_id

for(i in 1:nrow(grade_2_standards)) {
  std <- grade_2_standards[i,]
  dbExecute(con, sprintf(
    "INSERT INTO reading_literacy.curriculum_standards 
     (grade_id, standard_code, content_area, standard_text_az) 
     VALUES (%d, '%s', '%s', '%s')",
    grade_2_id, std$standard_code, std$area_az, gsub("'", "''", std$standard_text)
  ))
}
cat("✅ II sinif:", nrow(grade_2_standards), "standart yükləndi\n\n")

# Yoxlama
result <- dbGetQuery(con,
  "SELECT g.grade_level, cs.content_area, COUNT(*) as count
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE g.grade_level IN (1, 2)
   GROUP BY g.grade_level, cs.content_area
   ORDER BY g.grade_level, cs.content_area")

cat("=== BAZADA OLAN STANDARTLAR ===\n")
print(result)

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
