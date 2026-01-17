# ARTI - Azərbaycan Dili Oxu Savadlılığı Sistemi

**Azerbaijan Republic Education Institute**  
PIRLS formatında oxu savadlılığı qiymətləndirmə platforması

## 📚 Sistem Komponentləri

### 1. Server Tools (ARTI-də)
- `server_tools/test_package_creator.R` - Test paketləri yaratmaq
- `dashboard_main.R` - Ana monitoring dashboard
- `test_builder_dashboard.R` - Test tərtib etmə interfeysi

### 2. Client App (Məktəblərdə)
- `client_app/school_test_app.R` - Offline test platforması
- RSQLite ilə lokal məlumat saxlama

### 3. Sync Tools
- `sync_tools/results_sync.R` - Nəticələri PostgreSQL-ə yükləmək

### 4. Test Packages
- `test_packages/` - Məktəblərə göndərilən test paketləri (.db)

## 🎯 Xüsusiyyətlər

✅ PIRLS formatında suallar (10 sual/mətn)
✅ 4 Cognitive Level (Retrieve, Infer, Interpret, Evaluate)  
✅ 3 Sual tipi (Multiple Choice, Short, Extended)
✅ Offline işləyir (məktəblərdə internet lazım deyil)
✅ PostgreSQL (server) + SQLite (client)
✅ 1-4 siniflər üçün mətnlər və suallar

## 📊 Statistika

- **197 mətn** (I-IV siniflər)
- **348+ PIRLS sual**
- **4 sinif** (I-IV)

## 🚀 Quraşdırma
```r
# Server-də
source("server_tools/test_package_creator.R")
create_test_package("test_school_1", grade_level = 2, num_texts = 3)

# Dashboard
shiny::runApp("dashboard_main.R")

# Test Builder
shiny::runApp("test_builder_dashboard.R")
```

## 📖 Sənədlər

- `docs/SETUP.md` - Quraşdırma təlimatı
- `docs/ROADMAP.md` - İnkişaf planı
- `docs/QUICK_START.md` - Sürətli başlanğıc

## 👥 Müəllif

**Talıbov Tariyel İsmayıl oğlu**  
ARTI - Deputy Director of Assessment, Analysis and Monitoring

---
*2025 - Azerbaijan Republic Education Institute*
