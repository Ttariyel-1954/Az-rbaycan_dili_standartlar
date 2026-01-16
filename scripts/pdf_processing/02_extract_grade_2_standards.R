# II sinif standartlarını çıxarmaq
library(tidyverse)
library(stringr)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# Tam mətni oxuyuruq
full_text <- readLines("data/processed/kurrikulum_full_text.txt") %>% 
  paste(collapse = "\n")

cat("📖 II sinif standartları çıxarılır...\n\n")

# II sinif standartları üçün pattern
# Format: "Standart 2-X.Y." 
standard_pattern <- "Standart\\s+(2)-(\\d+)\\.(\\d+)\\.\\s+([^\n]+)\n([^\n]+)"

matches <- str_match_all(full_text, standard_pattern)[[1]]

if(nrow(matches) > 0) {
  cat("✅ Tapılan II sinif standartları:", nrow(matches), "\n\n")
  
  standards_df <- tibble(
    grade_level = as.integer(matches[,2]),
    content_area_code = as.integer(matches[,3]),
    standard_num = as.integer(matches[,4]),
    standard_code = paste0(matches[,2], "-", matches[,3], ".", matches[,4]),
    standard_title = str_trim(matches[,5]),
    standard_text = str_trim(matches[,6])
  )
  
  # Məzmun sahələrini əlavə edirik
  content_area_mapping <- tibble(
    code = c(1, 2, 3, 4),
    area_az = c("Dinləmə və Danışma", "Oxu", "Yazı", "Dil vahidləri")
  )
  
  standards_df <- standards_df %>%
    left_join(content_area_mapping, by = c("content_area_code" = "code"))
  
  cat("=== II SİNİF STANDARTLARI ===\n")
  print(standards_df %>% select(standard_code, area_az, standard_title))
  
  # CSV-yə saxlayırıq
  write_csv(standards_df, "data/processed/grade_2_standards.csv")
  cat("\n✅ Saxlanıldı: data/processed/grade_2_standards.csv\n")
  
  # Məzmun sahələrinə görə statistika
  cat("\n=== MƏZMUN SAHƏLƏRİNƏ GÖRƏ ===\n")
  standards_df %>% count(area_az) %>% print()
  
} else {
  cat("⚠️  II sinif standartları tapılmadı.\n")
  cat("Manuel olaraq yoxlamaq lazımdır.\n")
}

cat("\n✅ Çıxarma prosesi tamamlandı!\n")
