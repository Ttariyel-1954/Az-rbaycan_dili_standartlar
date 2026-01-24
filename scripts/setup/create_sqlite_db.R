# ═══════════════════════════════════════════════════════════
# SQLite LOKAL BAZA YARATMAQ
# ═══════════════════════════════════════════════════════════

library(DBI)
library(RSQLite)

# Baza yolu
db_path <- "~/Desktop/Azərbaycan_dili_standartlar/data/pirls_local.db"

# Qovluq yarat (əgər yoxdursa)
dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)

# Köhnə bazanı sil (əgər varsa)
if (file.exists(db_path)) {
  cat("⚠️  Köhnə baza silinir...\n")
  file.remove(db_path)
}

# Yeni baza yarat
cat("🔧 Yeni SQLite baza yaradılır...\n")
con <- dbConnect(RSQLite::SQLite(), db_path)

# SQL schema oxu
schema_file <- "~/Desktop/Azərbaycan_dili_standartlar/sql/sqlite_local_schema.sql"

if (file.exists(schema_file)) {
  cat("📄 Schema yüklənir...\n")
  schema <- paste(readLines(schema_file), collapse = "\n")
  
  # Hər əmri ayrı-ayrı icra et
  commands <- strsplit(schema, ";")[[1]]
  
  for (cmd in commands) {
    cmd <- trimws(cmd)
    if (nchar(cmd) > 0 && !grepl("^--", cmd)) {
      tryCatch({
        dbExecute(con, cmd)
      }, error = function(e) {
        if (!grepl("DROP TABLE", cmd)) {
          cat(sprintf("⚠️  Xəta: %s\n", e$message))
        }
      })
    }
  }
  
  cat("✅ Schema yükləndi\n\n")
} else {
  cat("❌ Schema fayl tapılmadı:", schema_file, "\n")
}

# Yoxla
tables <- dbListTables(con)
cat("📊 Yaradılan cədvəllər:\n")
for (tbl in tables) {
  count <- dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
  cat(sprintf("  • %s (%d sətir)\n", tbl, count))
}

dbDisconnect(con)

cat("\n✅ SQLite baza hazırdır!\n")
cat(sprintf("📁 Yer: %s\n", db_path))
cat(sprintf("📦 Ölçü: %.2f KB\n\n", file.size(db_path)/1024))
