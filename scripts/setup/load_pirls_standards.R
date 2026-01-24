# ═══════════════════════════════════════════════════════════
# PIRLS 2026 STANDARTLARINI BAZAYA YÜKLƏMƏk
# Load PIRLS 2026 Standards into Database
# ═══════════════════════════════════════════════════════════

library(DBI)
library(RPostgreSQL)

# ═══════════════════════════════════════════════════════════
# DATABASE CONNECTION
# ═══════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════╗\n")
cat("║  PIRLS 2026 Standartları Bazaya Yükləmə               ║\n")
cat("╚════════════════════════════════════════════════════════╝\n")
cat("\n")

get_db_connection <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

# ═══════════════════════════════════════════════════════════
# SQL FAYLını OXUMAQ VƏ İCRA ETMƏK
# ═══════════════════════════════════════════════════════════

load_sql_file <- function(filepath) {
  cat(sprintf("📄 SQL faylı oxunur: %s\n", filepath))
  
  if (!file.exists(filepath)) {
    stop(sprintf("❌ Fayl tapılmadı: %s", filepath))
  }
  
  sql_content <- readLines(filepath, warn = FALSE, encoding = "UTF-8")
  sql_content <- paste(sql_content, collapse = "\n")
  
  cat(sprintf("✅ SQL fayl oxundu (%d simvol)\n\n", nchar(sql_content)))
  
  return(sql_content)
}

execute_sql_statements <- function(con, sql_content) {
  # SQL komandalarını ayırmaq
  # Sadə ayırma - hər -- comment-dən sonra və ; -dən sonra
  
  cat("🔄 SQL komandaları icra edilir...\n\n")
  
  tryCatch({
    # Bütün SQL-i bir kərədə icra edək
    dbExecute(con, sql_content)
    
    cat("✅ SQL komandaları uğurla icra edildi!\n\n")
    return(TRUE)
    
  }, error = function(e) {
    cat(sprintf("❌ Xəta: %s\n", e$message))
    return(FALSE)
  })
}

# ═══════════════════════════════════════════════════════════
# VERİFİKASİYA
# ═══════════════════════════════════════════════════════════

verify_data <- function(con) {
  cat("═══════════════════════════════════════════════════════\n")
  cat("📊 VERİFİKASİYA - Yüklənmiş məlumat\n")
  cat("═══════════════════════════════════════════════════════\n\n")
  
  # 1. Documentation cədvəli
  doc_count <- dbGetQuery(con, "
    SELECT COUNT(*) as cnt 
    FROM reading_literacy.pirls_documentation
  ")$cnt
  
  cat(sprintf("📚 PIRLS Documentation: %d yazı\n", doc_count))
  
  # Kateqoriya üzrə
  categories <- dbGetQuery(con, "
    SELECT category, COUNT(*) as cnt
    FROM reading_literacy.pirls_documentation
    GROUP BY category
    ORDER BY category
  ")
  
  for (i in 1:nrow(categories)) {
    cat(sprintf("   • %s: %d\n", categories$category[i], categories$cnt[i]))
  }
  
  cat("\n")
  
  # 2. Reading Processes cədvəli
  process_count <- dbGetQuery(con, "
    SELECT COUNT(*) as cnt 
    FROM reading_literacy.pirls_reading_processes
  ")$cnt
  
  cat(sprintf("🧠 Oxu Prosesləri: %d proses\n", process_count))
  
  processes <- dbGetQuery(con, "
    SELECT name_az, difficulty_level
    FROM reading_literacy.pirls_reading_processes
    ORDER BY sort_order
  ")
  
  for (i in 1:nrow(processes)) {
    cat(sprintf("   %d. %s (Çətinlik: %d)\n", 
                i, 
                processes$name_az[i], 
                processes$difficulty_level[i]))
  }
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════\n\n")
}

# ═══════════════════════════════════════════════════════════
# DETALLAR GÖSTƏRMƏK
# ═══════════════════════════════════════════════════════════

show_details <- function(con) {
  cat("═══════════════════════════════════════════════════════\n")
  cat("📖 DETALLAR\n")
  cat("═══════════════════════════════════════════════════════\n\n")
  
  # Mətn növləri
  cat("1️⃣ MƏTN NÖVLƏRİ:\n")
  cat("───────────────────────────────────────────────────────\n")
  
  text_types <- dbGetQuery(con, "
    SELECT title_az, content_az
    FROM reading_literacy.pirls_documentation
    WHERE category = 'text_types'
    ORDER BY sort_order
  ")
  
  for (i in 1:nrow(text_types)) {
    cat(sprintf("\n%s\n", text_types$title_az[i]))
    cat(sprintf("%s\n", strrep("─", 50)))
    
    # İlk 200 simvol
    content_preview <- substr(text_types$content_az[i], 1, 200)
    cat(sprintf("%s...\n", content_preview))
  }
  
  cat("\n")
  
  # Sual tipləri
  cat("2️⃣ SUAL TİPLƏRİ:\n")
  cat("───────────────────────────────────────────────────────\n")
  
  question_types <- dbGetQuery(con, "
    SELECT title_az, content_az
    FROM reading_literacy.pirls_documentation
    WHERE category = 'question_types'
    ORDER BY sort_order
  ")
  
  for (i in 1:nrow(question_types)) {
    cat(sprintf("\n%s\n", question_types$title_az[i]))
    cat(sprintf("%s\n", strrep("─", 50)))
    
    content_preview <- substr(question_types$content_az[i], 1, 200)
    cat(sprintf("%s...\n", content_preview))
  }
  
  cat("\n")
  
  # Oxu prosesləri
  cat("3️⃣ OXU PROSESLƏRİ:\n")
  cat("───────────────────────────────────────────────────────\n")
  
  processes <- dbGetQuery(con, "
    SELECT name_az, description_az, difficulty_level
    FROM reading_literacy.pirls_reading_processes
    ORDER BY sort_order
  ")
  
  for (i in 1:nrow(processes)) {
    cat(sprintf("\n%s (Çətinlik: %d/4)\n", 
                processes$name_az[i], 
                processes$difficulty_level[i]))
    cat(sprintf("%s\n", strrep("─", 50)))
    
    desc_preview <- substr(processes$description_az[i], 1, 200)
    cat(sprintf("%s...\n", desc_preview))
  }
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════\n\n")
}

# ═══════════════════════════════════════════════════════════
# ƏSAS FUNKSİYA
# ═══════════════════════════════════════════════════════════

main <- function() {
  sql_file <- "pirls_standards_database.sql"
  
  # SQL faylı yoxla
  if (!file.exists(sql_file)) {
    cat(sprintf("❌ SQL fayl tapılmadı: %s\n", sql_file))
    cat("💡 Fayl eyni qovluqda olmalıdır.\n")
    return(invisible(NULL))
  }
  
  # SQL oxu
  sql_content <- load_sql_file(sql_file)
  
  # Database bağlantı
  cat("🔌 PostgreSQL-ə qoşulur...\n")
  con <- tryCatch({
    get_db_connection()
  }, error = function(e) {
    cat(sprintf("❌ Bağlantı xətası: %s\n", e$message))
    cat("\n💡 PostgreSQL işləyir?\n")
    cat("💡 Bağlantı məlumatları düzgün?\n")
    return(NULL)
  })
  
  if (is.null(con)) {
    return(invisible(NULL))
  }
  
  cat("✅ Bağlantı uğurlu!\n\n")
  
  on.exit(dbDisconnect(con))
  
  # SQL icra et
  success <- execute_sql_statements(con, sql_content)
  
  if (!success) {
    cat("\n❌ Yükləmə uğursuz oldu.\n")
    return(invisible(NULL))
  }
  
  # Verifikasiya
  verify_data(con)
  
  # Detallar
  show_details(con)
  
  # Uğurlu mesaj
  cat("╔════════════════════════════════════════════════════════╗\n")
  cat("║                                                        ║\n")
  cat("║  ✅ PIRLS 2026 STANDARTLARI UĞURLA YÜKLƏNDİ!         ║\n")
  cat("║                                                        ║\n")
  cat("║  Bazada olan məlumat:                                 ║\n")
  cat("║  • Mətn növləri (Ədəbi, İnformasiya)                 ║\n")
  cat("║  • Sual tipləri (MC, Constructed Response)           ║\n")
  cat("║  • Oxu prosesləri (4 səviyyə)                        ║\n")
  cat("║  • Test strukturu                                     ║\n")
  cat("║  • Kognitiv paylanma                                  ║\n")
  cat("║                                                        ║\n")
  cat("╚════════════════════════════════════════════════════════╝\n")
  cat("\n")
}

# ═══════════════════════════════════════════════════════════
# İCRA
# ═══════════════════════════════════════════════════════════

main()

