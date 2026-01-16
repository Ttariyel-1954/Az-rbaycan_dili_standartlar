# PDF Oxuma və Təhlil
library(pdftools)
library(tidyverse)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# PDF oxuyuruq
cat("📄 PDF oxunur...\n")
pdf_content <- pdftools::pdf_text("data/raw/Təkmilləsdirilmis-Azərbaycan-dili-fənn-kurikulumu.pdf")
pdf_info_data <- pdftools::pdf_info("data/raw/Təkmilləsdirilmis-Azərbaycan-dili-fənn-kurikulumu.pdf")

cat("✅ PDF oxundu!\n")
cat("   Səhifə sayı:", length(pdf_content), "\n\n")

# İlk səhifədən nümunə
cat("=== İLK 500 SİMVOL ===\n")
cat(substr(pdf_content[1], 1, 500), "...\n\n")

# Tam mətni birləşdiririk
full_document <- paste(pdf_content, collapse = "\n")

# Saxlayırıq
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
writeLines(full_document, "data/processed/kurrikulum_full_text.txt")
cat("✅ Tam mətn saxlanıldı\n")

# Hər səhifəni ayrıca
for(i in seq_along(pdf_content)) {
  writeLines(pdf_content[i], sprintf("data/processed/page_%03d.txt", i))
}
cat("✅", length(pdf_content), "səhifə saxlanıldı\n\n")

# Analiz
cat("🔍 Struktur analizi:\n")
grade_refs <- stringr::str_extract_all(full_document, "(I|II|III|IV|V|VI|VII|VIII|IX)\\s+sinif")[[1]]
cat("   Sinif qeydləri:", length(grade_refs), "\n")

areas <- c("Dinləmə", "Danışma", "Oxu", "Yazı")
for(area in areas) {
  cnt <- stringr::str_count(full_document, area)
  cat("   ", area, ":", cnt, "\n")
}

cat("\n✅ Tamamlandı!\n")
