# Daha ətraflı struktur analizi
library(tidyverse)
library(stringr)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

pages <- list.files("data/processed", pattern = "^page_\\d+\\.txt$", full.names = TRUE)

cat("=== SƏHIFƏ 6-15 STRUKTURU ===\n")
for(i in 6:min(15, length(pages))) {
  page_content <- readLines(pages[i]) %>% paste(collapse = "\n")
  
  cat("\n--- Səhifə", i, "---\n")
  cat(substr(page_content, 1, 400), "...\n")
  
  # Siniflər
  if(str_detect(page_content, "(I|II|III|IV|V|VI|VII|VIII|IX)\\s+sinif")) {
    grades <- str_extract_all(page_content, "(I|II|III|IV|V|VI|VII|VIII|IX)\\s+sinif")[[1]]
    cat("   ✓ Siniflər:", paste(unique(grades), collapse = ", "), "\n")
  }
  
  # Standart kodları var mı?
  if(str_detect(page_content, "\\d+\\.\\d+\\.\\d+")) {
    cat("   ✓ Standart kodları tapıldı\n")
  }
  
  # Alt bölmələr
  if(str_detect(page_content, "\\d+\\.\\d+\\.")) {
    sections <- str_extract_all(page_content, "\\d+\\.\\d+\\.[^\\n]{0,50}")[[1]]
    if(length(sections) > 0) {
      cat("   ✓ Alt bölmələr:\n")
      for(s in head(sections, 3)) {
        cat("      -", s, "\n")
      }
    }
  }
}

cat("\n✅ Analiz tamamlandı!\n")
