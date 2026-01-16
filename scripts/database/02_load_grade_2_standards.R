# II sinif standartlarını PostgreSQL-ə yükləmək
library(tidyverse)
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# Standartları oxuyuruq
standards <- read_csv("data/processed/grade_2_standards.csv", 
                      show_col_types = FALSE)

cat("📊 Yüklənəcək II sinif standartları:", nrow(standards), "\n\n")

cat("=== MƏZMUN SAHƏLƏRİNƏ GÖRƏ ===\n")
standards %>% count(area_az) %>% print()

# PostgreSQL-ə qoşuluruq
cat("\n🔌 PostgreSQL-ə qoşulur...\n")
con <- dbConnect(
  PostgreSQL(),
  dbname = "azerbaijan_language_standards",
  host = "localhost",
  port = 5432,
  user = Sys.getenv("USER")
)
cat("✅ Qoşuldu!\n\n")

# II sinif grade_id-ni tapırıq
grade_2_id <- dbGetQuery(con, 
  "SELECT grade_id FROM reading_literacy.grades WHERE grade_level = 2 LIMIT 1")$grade_id

cat("II sinif ID:", grade_2_id, "\n\n")

# Standartları yükləyirik
cat("📥 Standartlar bazaya yüklənir...\n")

for(i in 1:nrow(standards)) {
  std <- standards[i, ]
  
  query <- sprintf(
    "INSERT INTO reading_literacy.curriculum_standards 
     (grade_id, standard_code, content_area, standard_text_az) 
     VALUES (%d, '%s', '%s', '%s')",
    grade_2_id,
    std$standard_code,
    std$area_az,
    gsub("'", "''", std$standard_text)
  )
  
  dbExecute(con, query)
}

cat("✅ Bütün standartlar yükləndi!\n\n")

# Yoxlama
result <- dbGetQuery(con, 
  "SELECT cs.standard_code, cs.content_area, cs.standard_text_az
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE g.grade_level = 2
   ORDER BY cs.standard_code")

cat("=== BAZADA OLAN II SİNİF STANDARTLARI ===\n")
print(result)

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
