# 🎓 PIRLS 2026 TEST SİSTEMİ - TAM QURULUM
## AI ilə Açıq Cavab Qiymətləndirmə

---

## 📋 SİSTEM XÜLASƏSİ

**Şagird test verir → AI qiymətləndirir → Nəticə göstərilir → Bazaya yazılır**

```
┌─────────────┐
│   ŞAGİRD    │ 
│ Test verir  │
└──────┬──────┘
       ↓
┌──────────────────┐
│  SHINY TƏTBİQİ  │
│  • Mətn göstərir │
│  • Sualları verir│
└────────┬─────────┘
         ↓
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼────┐
│QAŞALI│  │ AÇIQ  │
│A/B/C │  │  AI   │
└───┬──┘  └──┬────┘
    │        │
    └────┬───┘
         ↓
   ┌─────▼──────┐
   │ POSTGRESQL │
   │   BAZA     │
   └─────┬──────┘
         ↓
   ┌─────▼──────┐
   │  NƏTİCƏ    │
   │ EKRANI     │
   └────────────┘
```

---

## 🚀 QURULUM - ADDIM-ADDIM

### **ADDIM 1: Tələblər**

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DBI",
  "RPostgreSQL",
  "httr",
  "jsonlite",
  "dotenv",
  "DT",
  "markdown"
))
```

---

### **ADDIM 2: API Key**

`.env` faylı yaradın:

```bash
cd ~/Desktop/Azərbaycan_dili_standartlar
nano .env
```

Məzmun:

```
# OpenAI API Key
OPENAI_API_KEY=sk-proj-SIZIN-REAL-KEY

# Anthropic (əgər istəsəniz)
ANTHROPIC_API_KEY=sk-ant-SIZIN-KEY
```

> **API key haradan:** https://platform.openai.com/api-keys

---

### **ADDIM 3: Bazanı Hazırlayın**

```bash
cd ~/Desktop/Azərbaycan_dili_standartlar

# Baza strukturunu yarat
psql -U royatalibova -d azerbaijan_language_standards -f reset_test_schema.sql

# Mətn və sualları yüklə (əgər hələ yüklənməyibsə)
psql -U royatalibova -d azerbaijan_language_standards -f enerji_metni.sql
```

---

### **ADDIM 4: Tətbiqi İşə Salın**

```r
setwd("~/Desktop/Azərbaycan_dili_standartlar")

# Tətbiqi aç
library(shiny)
runApp("student_test_app_final.R")
```

Browser-da açılacaq: `http://127.0.0.1:XXXX`

---

## 📖 İSTİFADƏ - ŞAGİRD PERSPEKTİVİ

### **1. Giriş**

- Şagird kodu: `S2024-001`
- Ad: `Ayşən`
- Soyad: `Məmmədova`
- **"Testə Başla"** düyməsi

### **2. Mətn Oxuma**

"Azərbaycanda Enerji Mənbələri" mətni göstərilir:
- 780 söz
- Cədvəl və qrafiklər
- Scroll edilə bilən

### **3. Sualları Cavablandırma**

**18 sual:**
- 10 qapalı (A/B/C/D) - 1 bal
- 8 açıq (yazılı cavab) - 2-3 bal

**Nümunə qapalı sual:**
> Azərbaycanda ildə ortalama neçə saat günəş işığı olur?
> - A) 1800-2200
> - B) 2000-2400
> - C) 2400-2800 ✓
> - D) 3000-3500

**Nümunə açıq sual:**
> Bərpa olunan və bərpa olunmayan enerji mənbələri arasında əsas fərq nədir? İki nümunə göstər.

*Şagird yazır...*

### **4. Təsdiq**

**"Testi Təsdiq Edib Göndər"** düyməsi

⏳ Modal açılır: "AI cavablarınızı yoxlayır..."

### **5. Qiymətləndirmə (30-60 saniyə)**

```
✅ Qapalı suallar yoxlanır... (dərhal)
🤖 Açıq suallar AI ilə qiymətləndirilir...
   Sual 11... ✅ 2/2
   Sual 12... ✅ 2/2
   Sual 13... ✅ 3/3
   ...
📊 Ümumi bal hesablanır...
💾 Bazaya yazılır...
```

### **6. Nəticə Ekranı**

```
╔════════════════════════════════════════╗
║      🎓 Ayşən Məmmədova                ║
║                                        ║
║         32.0 / 36                      ║
║        88.9% - Yaxşı (B)               ║
║                                        ║
║  📝 Qapalı: 10/10   ✍️ Açıq: 22/26    ║
╚════════════════════════════════════════╝
```

**Detallı cədvəl:**

| Sual | Tip | Cavab | Bal | AI Rəyi |
|------|-----|-------|-----|---------|
| 1 | Qapalı | B | 1/1 | - |
| 11 | Açıq | Bərpa olunmayan... | 2/2 | Əla! Fərq aydın... |

---

## 💾 NƏTİCƏLƏR BAZADA

### **5 cədvəl:**

1. **students** - Şagird məlumatı
2. **test_sessions** - Test sessiyaları
3. **student_test_results** - Ümumi nəticələr
4. **student_answers** - Hər sual cavabı
5. **ai_grading_log** - AI qiymətləndirmə loqu

### **Sorğu nümunəsi:**

```sql
-- Şagird nəticələrini gör
SELECT * FROM assessment.vw_test_results_summary;

-- Detallı cavablar
SELECT 
    s.student_code,
    q.question_number,
    sa.student_answer,
    sa.score_received,
    sa.ai_feedback
FROM assessment.student_answers sa
JOIN assessment.questions q ON sa.question_id = q.question_id
JOIN assessment.student_test_results str ON sa.result_id = str.result_id
JOIN assessment.students s ON str.student_id = s.student_id
WHERE s.student_code = 'S2024-001';
```

---

## 📤 SERVERƏ KÖÇÜRMƏ

### **Variant 1: JSON Export**

```r
source("export_to_server.R")

# JSON fayl yarat
export_results_to_json(session_id = 1, output_file = "test_results.json")
```

Fayl yaradılacaq: `test_results.json` (bütün məlumatlar)

### **Variant 2: CSV Export**

```r
# CSV fayllar yarat
export_results_to_csv(session_id = 1, output_dir = "exports")
```

2 fayl yaradılacaq:
- `exports/test_results_summary.csv` - Xülasə
- `exports/test_answers_detailed.csv` - Detallı

### **Variant 3: Birbaşa Server Bazaya**

Əvvəlcə `export_to_server.R`-də düzəliş edin:

```r
get_server_db <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "192.168.1.100",  # Server IP
            port = 5432,
            user = "server_user",
            password = "server_password")
}
```

Sonra çalışdırın:

```r
export_results_to_server(session_id = 1)
```

---

## 📊 STATİSTİKA VƏ ANALİZ

### **Sinif üzrə orta**

```r
con <- get_db_connection()

stats <- dbGetQuery(con, "
  SELECT 
    AVG(percentage) as orta_faiz,
    AVG(mc_score) as orta_qapalı,
    AVG(open_score) as orta_açıq,
    COUNT(*) as şagird_sayı
  FROM assessment.student_test_results
  WHERE session_id = 1 AND is_completed = TRUE
")

print(stats)

dbDisconnect(con)
```

### **Ən çətin suallar**

```r
difficult <- dbGetQuery(con, "
  SELECT 
    q.question_number,
    q.question_text,
    AVG(sa.score_received) as orta_bal,
    q.max_score,
    ROUND(100.0 * AVG(sa.score_received) / q.max_score, 1) as faiz
  FROM assessment.student_answers sa
  JOIN assessment.questions q ON sa.question_id = q.question_id
  WHERE q.question_type = 'open_response'
  GROUP BY q.question_id, q.question_number, q.question_text, q.max_score
  ORDER BY faiz ASC
")

print(difficult)
```

### **AI qiymətləndirmə keyfiyyəti**

```r
ai_quality <- dbGetQuery(con, "
  SELECT 
    AVG(confidence_score) as orta_əminlik,
    COUNT(*) as toplam_qiymətləndirmə,
    SUM(prompt_tokens) as toplam_prompt_tokens,
    SUM(response_tokens) as toplam_response_tokens
  FROM assessment.ai_grading_log
")

print(ai_quality)
```

---

## 💰 XƏRCİ

**OpenAI GPT-4o-mini:**
- ~$0.001 per açıq cavab
- 8 açıq cavab = ~$0.008 per test
- 100 şagird = ~$0.80

**Anthropic Claude Sonnet 4:**
- ~$0.03 per açıq cavab
- 8 açıq cavab = ~$0.24 per test
- 100 şagird = ~$24

💡 **Tövsiyə:** OpenAI daha ucuzdur və keyfiyyətli!

---

## 🔧 TROUBLESHOOTİNG

### **Problem: API xəta**

```
Həll: .env faylında OPENAI_API_KEY yoxla
```

### **Problem: Baza bağlanmır**

```bash
# PostgreSQL işləyir?
ps aux | grep postgres

# Port açıq?
lsof -i :5432
```

### **Problem: AI çox yavaş**

```
Həll: Anthropic əvəzinə OpenAI istifadə et (30x sürətli)
```

### **Problem: Nəticə göstərilmir**

```sql
-- result_id var?
SELECT * FROM assessment.student_test_results WHERE student_id = 1;

-- Cavablar var?
SELECT COUNT(*) FROM assessment.student_answers WHERE result_id = X;
```

---

## ✅ YEKUİN ÇEKLST

- [ ] R paketləri quraşdırılıb
- [ ] .env faylı yaradılıb və API key əlavə edilib
- [ ] Baza strukturu yaradılıb
- [ ] Mətn və suallar yüklənib
- [ ] Tətbiq işə düşür
- [ ] Test cavab verilir
- [ ] AI qiymətləndirmə işləyir
- [ ] Nəticə göstərilir
- [ ] Bazada məlumat saxlanılır
- [ ] Export funksiyaları işləyir

---

## 🎯 GƏLƏCƏKDƏ GENİŞLƏNDİRMƏ

1. **Çoxlu mətn:** Random mətn seçimi
2. **Adaptive testing:** IRT əsaslı sual seçimi
3. **Real-time dashboard:** Müəllim panelinə
4. **Offline rejim:** İnternet olmadan test
5. **Mobile app:** iOS/Android versiya
6. **Rubrik editor:** Müəllim rubrik yarada bilsin
7. **Peer review:** Şagirdlər bir-birini qiymətləndirsin

---

## 📞 DƏSTƏK

**Sualınız var?**
- GitHub: ttariyel-1954
- Web: ttariyel.tech

**Uğurlar!** 🚀
