# I və II sinif standartlarını yükləmək
library(tidyverse)
library(RPostgreSQL)
library(DBI)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

cat("🔌 PostgreSQL-ə qoşulur...\n")
con <- dbConnect(PostgreSQL(), dbname = "azerbaijan_language_standards",
                 host = "localhost", port = 5432, user = Sys.getenv("USER"))

# Təmizləmə
cat("🧹 Köhnə standartlar silinir...\n")
dbExecute(con, "DELETE FROM reading_literacy.standard_framework_mapping")
dbExecute(con, "DELETE FROM reading_literacy.curriculum_standards")
cat("✅ Təmizləndi!\n\n")

# Bütün standartları oxuyuruq
all_standards <- read_csv("data/processed/extracted_standards.csv", show_col_types = FALSE)

# Məzmun sahələri
content_mapping <- tibble(
  code = c(1, 2, 3, 4),
  area_az = c("Dinləmə və Danışma", "Oxu", "Yazı", "Dil vahidləri")
)

all_standards <- all_standards %>%
  left_join(content_mapping, by = c("content_area_code" = "code"))

# Yalnız I və II sinfi filtrləyirik
grade_1_2_standards <- all_standards %>%
  filter(grade_level %in% c(1, 2))

cat("📊 Yüklənəcək standartlar:\n")
grade_1_2_standards %>% count(grade_level) %>% print()

# Grade ID-ləri
grade_ids <- dbGetQuery(con, 
  "SELECT grade_id, grade_level FROM reading_literacy.grades 
   WHERE grade_level IN (1, 2)")

cat("\n📥 Standartlar yüklənir...\n")

for(i in 1:nrow(grade_1_2_standards)) {
  std <- grade_1_2_standards[i,]
  
  # Grade ID tapırıq
  grade_id <- grade_ids %>% 
    filter(grade_level == std$grade_level) %>% 
    pull(grade_id)
  
  dbExecute(con, sprintf(
    "INSERT INTO reading_literacy.curriculum_standards 
     (grade_id, standard_code, content_area, standard_text_az) 
     VALUES (%d, '%s', '%s', '%s')",
    grade_id, std$standard_code, std$area_az, 
    gsub("'", "''", std$standard_text)
  ))
  
  if(i %% 10 == 0) cat("   ", i, "standart yükləndi...\n")
}

cat("✅ Bütün standartlar yükləndi!\n\n")

# Yoxlama
result <- dbGetQuery(con,
  "SELECT g.grade_level, g.grade_name_az, cs.content_area, COUNT(*) as count
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   GROUP BY g.grade_level, g.grade_name_az, cs.content_area
   ORDER BY g.grade_level, cs.content_area")

cat("=== BAZADA OLAN STANDARTLAR ===\n")
print(result)

# Oxu standartları
oxu_count <- dbGetQuery(con,
  "SELECT g.grade_level, COUNT(*) as oxu_standartlari
   FROM reading_literacy.curriculum_standards cs
   JOIN reading_literacy.grades g ON cs.grade_id = g.grade_id
   WHERE cs.content_area = 'Oxu'
   GROUP BY g.grade_level
   ORDER BY g.grade_level")

cat("\n=== OXU STANDARTLARI ===\n")
print(oxu_count)

dbDisconnect(con)
cat("\n✅ Proses tamamlandı!\n")
