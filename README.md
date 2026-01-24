# 📚 Azərbaycan Dili Standartları - PIRLS 2026

PIRLS 2026 standartlarına uyğun Azərbaycan dili oxu bacarıqlarının qiymətləndirilməsi sistemi.

## 🎯 Layihə Haqqında

Bu layihə IV sinif şagirdlərinin oxu bacarıqlarını PIRLS 2026 beynəlxalq standartlarına uyğun qiymətləndirmək üçün PostgreSQL əsaslı tam funksional sistemdir.

### Əsas Komponentlər:
- 📊 **PostgreSQL Database** - 26 mətn, 468 sual
- 📈 **R Shiny Dashboard** - İnteraktiv analiz sistemi
- 📝 **Test Builder** - Avtomatik test yaratma
- 🎓 **Student App** - Tələbə test interfeysi

## 📁 Struktur
```
Azərbaycan_dili_standartlar/
├── database/              # PostgreSQL baza
│   ├── schema/           # SQL fayllar və struktur
│   ├── migrations/       # Baza dəyişiklikləri
│   └── backups/          # Backup faylları
├── texts/                # Mətn korpusu
│   └── grade_4/         # IV sinif mətnləri (26 mətn)
├── dashboards/           # Analiz dashboardları
│   ├── shiny/           # R Shiny dashboard
│   ├── html/            # HTML dashboard
│   └── exports/         # Export faylları
├── scripts/              # R skriptləri
│   ├── admin/           # Admin alətləri
│   ├── analysis/        # Analiz skriptləri
│   ├── export/          # Export skriptləri
│   └── setup/           # Setup skriptləri
├── docs/                 # Sənədlər
│   ├── guides/          # İstifadə təlimatları
│   ├── api/             # API sənədləri
│   └── changelog/       # Dəyişikliklər
├── tests/                # Test faylları
├── output/               # Çıxış faylları
│   ├── reports/         # Hesabatlar
│   ├── data/            # Data eksport
│   └── logs/            # Log faylları
└── archive_old/          # Köhnə versiyalar
```

## 🚀 Başlanğıc

### 1. Sistem Tələbləri

- PostgreSQL 14+
- R 4.0+
- RStudio (tövsiyə olunur)

### 2. R Paketləri
```r
install.packages(c(
  "shiny", "shinydashboard", "DT", "ggplot2", "plotly",
  "RPostgreSQL", "dplyr", "tidyr", "jsonlite"
))
```

### 3. Database Setup
```bash
# PostgreSQL-ə qoşul
psql -U royatalibova

# Database yarat
CREATE DATABASE azerbaijan_language_standards;

# Schema yüklə
psql -U royatalibova -d azerbaijan_language_standards -f database/schema/pirls_standards_database.sql
```

### 4. Mətnləri Yüklə
```bash
# Bütün mətn SQL fayllarını yüklə
for file in database/schema/*.sql; do
  psql -U royatalibova -d azerbaijan_language_standards -f "$file"
done
```

## 📊 Dashboard İstifadəsi

### R Shiny Dashboard
```r
library(shiny)
runApp("dashboards/shiny/baza_analiz_dashboard.R")
```

Dashboard 7 əsas bölmədən ibarətdir:
- 🏠 Ümumi Məlumat
- 📚 Mətn Siyahısı
- ❓ Sual Təhlili
- 📖 Mətn Oxuyucu
- 📊 Statistika
- 🔍 Axtarış
- ⚙️ Baza Strukturu

## 📈 Mövcud Data

### Mətnlər (26 ədd)
- Bədii mətnlər: 8
- Məlumatverici mətnlər: 18
- Orta söz sayı: 750 söz

### Suallar (468 ədd)
- Qapalı suallar: 260 (10 sual/mətn)
- Açıq suallar: 208 (8 sual/mətn)
- Ümumi bal: ~1,500 bal

### PIRLS 2026 Bacarıqları
✅ Məlumat əldə etmə
✅ İnterpretasiya
✅ İnteqrasiya və qiymətləndirmə
✅ Tənqidi düşüncə

## 🛠️ Əsas Alətlər

### 1. Test Builder
```r
source("scripts/admin/pirls_2026_test_builder.R")
```

### 2. Mətn Redaktoru
```r
source("scripts/admin/pirls_text_editor.R")
```

### 3. Tələbə Test App
```r
source("scripts/admin/student_test_app_final.R")
```

## 📚 Sənədlər

- [Dashboard Təlimatı](docs/guides/README_DASHBOARD.md)
- [Redaktor Təlimatı](docs/guides/TAM_REDAKTOR_GUIDE.md)
- [Format Yeniləməsi](docs/guides/FORMAT_UPGRADE.md)

## 🔧 Konfiqurasiya

`.env` faylında database məlumatlarını təyin edin:
```env
DB_NAME=azerbaijan_language_standards
DB_HOST=localhost
DB_PORT=5432
DB_USER=royatalibova
DB_PASS=
```

## 📊 Performans

- 26 mətn, 468 sual
- Orta sorğu vaxtı: <100ms
- Dashboard yükləmə: ~2 saniyə
- Test yaratma: ~5 saniyə

## 🤝 Töhfə

Bu layihə ARTI (Azerbaijan Republic Education Institute) tərəfindən inkişaf etdirilir.

## 📞 Əlaqə

**ARTI - Assessment, Analysis and Monitoring Department**
- Web: ttariyel.tech
- GitHub: Ttariyel-1954

## 📝 Lisenziya

© 2025 ARTI - Bütün hüquqlar qorunur

## 🎯 Gələcək Planlar

- [ ] Avtomatik hesabat sistemi
- [ ] Excel export
- [ ] PDF test yaratma
- [ ] Multi-user sistem
- [ ] Web-əsaslı test platforması

---

**Son Yeniləmə:** 24 Yanvar 2025
**Versiya:** 2.0
