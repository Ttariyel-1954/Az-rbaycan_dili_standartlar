# Azərbaycan Dili Standartları - PISA/PIRLS Uyğunlaşdırma

## Layihə haqqında

Bu layihə Azərbaycan dili milli kurikulumunu beynəlxalq oxu savadı qiymətləndirmə çərçivələrinə (PISA, PIRLS, CEFR, EGRA) uyğunlaşdırır.

### Məqsəd
- **PISA** - əsas strateji hədəf
- **PIRLS** - fundamentin ölçülməsi  
- **CEFR və EGRA** - tamamlayıcı alətlər

## Texnologiyalar

- **R/RStudio** - Əsas proqramlaşdırma dili
- **PostgreSQL** - Məlumat bazası
- **Shiny** - İnteraktiv dashboard
- **Claude API (Sonnet 4)** - AI-powered mapping və mətn generasiyası

## Layihə strukturu
```
Azərbaycan_dili_standartlar/
├── data/
│   ├── raw/                  # Orijinal kurrikulum PDF
│   └── processed/            # Emal olunmuş məlumatlar
├── scripts/
│   ├── pdf_processing/       # PDF oxuma və parse
│   ├── database/             # PostgreSQL skriptlər
│   ├── api_integration/      # Claude API inteqrasiyası
│   └── analysis/             # Təhlil skriptləri
├── sql/
│   ├── schema/               # Baza strukturu
│   └── queries/              # SQL sorğular
├── shiny_app/                # İnteraktiv dashboard
├── reports/                  # Hesabatlar
└── docs/                     # Sənədlər
```

## Quraşdırma

### 1. Tələblər
```bash
# PostgreSQL
brew install postgresql@16
brew services start postgresql@16

# R paketləri
install.packages(c("pdftools", "RPostgreSQL", "DBI", "shiny", 
                   "shinydashboard", "tidyverse", "jsonlite", 
                   "httr", "stringr", "DT", "plotly", "dotenv"))
```

### 2. Bazanı yaratmaq
```bash
createdb azerbaijan_language_standards
psql azerbaijan_language_standards -f sql/schema/01_create_schema.sql
psql azerbaijan_language_standards -f sql/schema/02_insert_initial_data.sql
```

### 3. .env faylını yaratmaq
```bash
echo "ANTHROPIC_API_KEY=your-api-key-here" > .env
```

### 4. Tam prosesi işə salmaq
```bash
./run_full_pipeline.sh
```

## İstifadə

### Dashboard işə salmaq
```bash
Rscript -e "shiny::runApp('shiny_app', port = 3838)"
```
Brauzer: http://localhost:3838

### Əl ilə addımlar

1. **PDF-dən standartları çıxarmaq**
```bash
Rscript scripts/pdf_processing/01_extract_pdf.R
```

2. **Standartları bazaya yükləmək**
```bash
Rscript scripts/database/01_load_standards.R
```

3. **PISA/PIRLS mapping**
```bash
Rscript scripts/api_integration/03_full_mapping_system.R
Rscript scripts/api_integration/04_map_all_standards.R
```

4. **Mətn generasiyası**
```bash
Rscript scripts/api_integration/05_generate_text_samples.R
```

5. **Təhlil və tapşırıqlar**
```bash
Rscript scripts/api_integration/06_analyze_and_create_tasks.R
```

## Baza strukturu

### Əsas cədvəllər
- `grades` - Sinif məlumatları (1-9)
- `frameworks` - PISA, PIRLS, CEFR, EGRA
- `reading_aspects` - Oxu savadı aspektləri
- `curriculum_standards` - Milli kurrikulum standartları
- `standard_framework_mapping` - Standartların framework-ə uyğunlaşdırılması
- `text_types` - Mətn növləri
- `text_samples` - Mətn nümunələri
- `text_analysis` - AI təhlili
- `assessment_tasks` - Qiymətləndirmə tapşırıqları

## Nəticələr

### Statistika
- 137 kurrikulum standartı
- 92 framework mapping
- 4 mətn nümunəsi  
- 3 mətn təhlili
- 6 qiymətləndirmə tapşırığı

### Framework Coverage
- **PISA aspektləri**: LOC, UND, EVL, REF
- **PIRLS aspektləri**: RET, INF, INT, EXM

## Müəllif

**Talıbov Tariyel İsmayıl oğlu**  
Deputy Director, ARTI (Azerbaijan Republic Education Institute)  
Email: ttariyel.tech  
GitHub: Ttariyel-1954

## Lisenziya

© 2026 ARTI - Azerbaijan Republic Education Institute

