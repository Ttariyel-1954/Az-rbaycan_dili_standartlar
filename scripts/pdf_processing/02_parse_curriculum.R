# Kurrikulum Standartlarını Strukturlaşdırma
library(tidyverse)
library(stringr)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

cat("📖 Kurrikulum mətnini oxuyuruq...\n")
full_text <- readLines("data/processed/kurrikulum_full_text.txt") %>% 
  paste(collapse = "\n")

cat("✅ Mətn yükləndi (", nchar(full_text), "simvol)\n\n")

# Siniflərə görə bölmək üçün pattern
cat("🔍 Sinif bölmələrini axtarırıq...\n")

# Hər səhifəni ayrıca oxuyub analiz edirik
pages <- list.files("data/processed", pattern = "^page_\\d+\\.txt$", full.names = TRUE)
cat("   Tapılan səhifə faylları:", length(pages), "\n")

# İlk 10 səhifəyə baxaq nə strukturu var
cat("\n=== İLK 5 SƏHİFƏNİN STRUKTURU ===\n")
for(i in 1:min(5, length(pages))) {
  page_content <- readLines(pages[i]) %>% paste(collapse = "\n")
  
  cat("\n--- Səhifə", i, "---\n")
  # İlk 300 simvol
  cat(substr(page_content, 1, 300), "...\n")
  
  # Bu səhifədə sinif var?
  if(str_detect(page_content, "(I|II|III|IV|V|VI|VII|VIII|IX)\\s+sinif")) {
    grades_found <- str_extract_all(page_content, "(I|II|III|IV|V|VI|VII|VIII|IX)\\s+sinif")[[1]]
    cat("   → Siniflər tapıldı:", paste(unique(grades_found), collapse = ", "), "\n")
  }
  
  # Məzmun sahələri
  for(area in c("Dinləmə", "Danışma", "Oxu", "Yazı")) {
    if(str_detect(page_content, area)) {
      cat("   → Məzmun sahəsi:", area, "\n")
    }
  }
}

cat("\n✅ İlkin analiz tamamlandı!\n")
cat("📋 Növbəti addım: Standartları çıxarmaq və strukturlaşdırmaq\n")
