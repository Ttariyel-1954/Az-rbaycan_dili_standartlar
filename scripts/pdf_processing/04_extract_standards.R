# Standartları çıxarıb bazaya yükləmək
library(tidyverse)
library(stringr)
library(RPostgreSQL)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# Tam mətni oxuyuruq
full_text <- readLines("data/processed/kurrikulum_full_text.txt") %>% 
  paste(collapse = "\n")

cat("📖 Standartlar çıxarılır...\n\n")

# Standart pattern-i: "Standart X-Y.Z."
standard_pattern <- "Standart\\s+(\\d+)-(\\d+)\\.(\\d+)\\.\\s+([^\n]+)\n([^\n]+)"

# Standartları tapırıq
matches <- str_match_all(full_text, standard_pattern)[[1]]

if(nrow(matches) > 0) {
  cat("✅ Tapılan standart sayı:", nrow(matches), "\n\n")
  
  # Data frame yaradırıq
  standards_df <- tibble(
    grade_level = as.integer(matches[,2]),
    content_area_code = as.integer(matches[,3]),
    standard_num = as.integer(matches[,4]),
    standard_code = paste0(matches[,2], "-", matches[,3], ".", matches[,4]),
    standard_title = str_trim(matches[,5]),
    standard_text = str_trim(matches[,6])
  )
  
  # İlk 10 standartı göstəririk
  cat("=== İLK 10 STANDART ===\n")
  print(head(standards_df, 10))
  
  # CSV-yə saxlayırıq
  write_csv(standards_df, "data/processed/extracted_standards.csv")
  cat("\n✅ Standartlar saxlanıldı: data/processed/extracted_standards.csv\n")
  
} else {
  cat("⚠️  Standart tapılmadı. Pattern-i dəyişdirmək lazımdır.\n")
  
  # Alternativ axtarış
  cat("\n🔍 Alternativ pattern-lər sınaqdan keçirilir...\n")
  alt_pattern <- "Standart\\s+\\d+-\\d+\\.\\d+"
  alt_matches <- str_extract_all(full_text, alt_pattern)[[1]]
  cat("   Tapılan 'Standart' sözləri:", length(alt_matches), "\n")
  cat("   İlk 5 nümunə:\n")
  print(head(alt_matches, 5))
}

cat("\n✅ Çıxarma prosesi tamamlandı!\n")
