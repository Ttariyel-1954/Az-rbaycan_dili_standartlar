# ⚡ QURAŞDIRMA TƏLİMATI

## 📦 Paket İçindəkilər

Bu paketi indirdiyinizdən sonra aşağıdakı struktur olacaq:

```
azerbaijan_language_standards/
│
├── shiny_apps/                      # Bütün Shiny tətbiqləri
│   ├── 01_text_explorer/
│   │   └── app.R                    ✅ Mətn Kəşfiyyatçısı
│   ├── 02_text_editor/
│   │   └── app.R                    ✅ Mətn Redaktoru
│   ├── 03_test_platform/
│   │   └── app.R                    ✅ Test Platforması
│   └── shared/
│       ├── question_generator.R     ✅ Sual yaratma
│       └── ai_grading_system.R      ✅ AI qiymətləndirmə
│
├── docs/                            # Sənədlər
│   ├── README.md
│   ├── ROADMAP.md                   # 6 mərhələli plan
│   ├── QUICK_START.md
│   └── FILE_STRUCTURE.md
│
├── config/
│   └── .Renviron.sample             # API konfiqurasiya nümunəsi
│
└── database/                        # (boş - siz SQL faylları əlavə edəcəksiniz)
```

---

## 🚀 3 ADDIMDA QURAŞDIRMA

### ADDIM 1: Paketi Desktop-a Köçürün

**Mac/Linux:**
```bash
# Paket çıxarıldıqdan sonra
mv azerbaijan_language_standards ~/Desktop/

# və ya mövcud layihənizə birləşdirin
cp -r azerbaijan_language_standards/* ~/Desktop/Azərbaycan_dili_standartlar/
```

**Windows:**
```powershell
# Desktop-a köçürün
Move-Item azerbaijan_language_standards $HOME\Desktop\
```

---

### ADDIM 2: Claude API Konfiqurasiya (5 dəqiqə)

**2.1. API Key Alın**
- https://console.anthropic.com saytına gedin
- Sign up / Log in
- API Keys → Create Key
- Key-i kopyalayın (sk-ant-... ilə başlayır)

**2.2. .Renviron faylı yaradın**

```bash
cd ~/Desktop/azerbaijan_language_standards/config
cp .Renviron.sample .Renviron

# .Renviron faylını redaktə edin
nano .Renviron  # və ya TextEdit/Notepad
```

**.Renviron faylının içində:**
```
ANTHROPIC_API_KEY=sk-ant-api03-SIZIN-REAL-KEY-BURAYA
USER=your_postgres_username
```

**2.3. R-də Yüklə**
```r
readRenviron("~/Desktop/azerbaijan_language_standards/config/.Renviron")

# Yoxla
Sys.getenv("ANTHROPIC_API_KEY")  # Açarı göstərməlidir
```

---

### ADDIM 3: İlk Tətbiqi İşə Salın (2 dəqiqə)

**Mətn Kəşfiyyatçısı:**
```r
setwd("~/Desktop/azerbaijan_language_standards/shiny_apps/01_text_explorer")
shiny::runApp()
```

Browser açılacaq və mətnləri görəcəksiniz! ✅

---

## 📂 Hər Faylın Yerləşdiyi Yer

| Fayl | Yeri | Nə işə gedir |
|------|------|-------------|
| **app.R** | 01_text_explorer/ | Mətnləri görmək |
| **app.R** | 02_text_editor/ | Mətnləri redaktə |
| **app.R** | 03_test_platform/ | Şagird testi |
| **question_generator.R** | shared/ | Sual yaratmaq |
| **ai_grading_system.R** | shared/ | Qiymətləndirmə |
| **ROADMAP.md** | docs/ | 6 ay planı |
| **QUICK_START.md** | docs/ | Qısa təlimat |
| **.Renviron** | config/ | API açarları |

---

## 🎯 Növbəti İşlər

### Bu həftə:
1. ✅ Paketi quraşdırdınız
2. ⏳ Claude API key konfiqurasiya edin
3. ⏳ İlk tətbiqi test edin

### Növbəti həftə:
1. ROADMAP.md-i oxuyun (ətraflı plan)
2. 5-10 mətn üçün sual yaradın
3. Ekspert review təşkil edin

---

## ❓ Problem Həlli

### "API key tapılmır" xətası
```r
# .Renviron yenidən yükləyin
readRenviron("~/Desktop/azerbaijan_language_standards/config/.Renviron")
```

### "Database connection error"
```r
# PostgreSQL işləyir?
system("pg_isready")

# Database yaradılıb?
# Əgər yoxdursa, psql-də:
CREATE DATABASE azerbaijan_language_standards;
```

### "Paket tapılmır" xətası
```r
# Lazım olan paketləri quraşdırın
install.packages(c(
  "shiny", "shinydashboard", "tidyverse",
  "RPostgreSQL", "DBI", "DT", "shinyjs",
  "httr", "jsonlite"
))
```

---

## 📞 Dəstək

Problemləriniz varsa:

1. **docs/README.md** - Texniki detallar
2. **docs/ROADMAP.md** - Implementasiya planı
3. **docs/FILE_STRUCTURE.md** - Fayl strukturu

---

## ✅ Hazırsınız!

İndi 3 əsas komponent əldə etdiniz:

1. 📚 **Mətn Sistemi** (görüntülə, redaktə)
2. 🤖 **AI Sistemləri** (sual yarat, qiymətləndir)
3. 📊 **Test Platforması** (şagird interfeysi)

**Uğurlar!** 🎉

*Tariyel Talıbov - ARTI*