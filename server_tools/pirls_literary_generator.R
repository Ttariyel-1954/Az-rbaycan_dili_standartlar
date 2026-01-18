# PIRLS ƏDƏBİ MƏTN GENERATORU
# IV sinif - Hekayələr, Personaj, Sujet, Emosional anlam

library(httr)
library(jsonlite)
library(tidyverse)
library(DBI)
library(RPostgreSQL)

ANTHROPIC_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")
CLAUDE_MODEL <- "claude-sonnet-4-20250514"

# PostgreSQL
get_db <- function() {
  dbConnect(PostgreSQL(), 
            dbname = "azerbaijan_language_standards",
            host = "localhost", port = 5432, 
            user = "royatalibova")
}

# PIRLS ƏDƏBİ MƏTN YARATMAQ
generate_pirls_literary_text <- function(theme, word_count = 350) {
  
  prompt <- sprintf('
Azərbaycan dili IV sinif üçün PIRLS formatında ədəbi mətn yarat.

**MÖVZU:** %s
**SÖZ SAYI:** ~%d söz
**YAŞ:** 9-10 yaş

**PIRLS ƏDƏBİ MƏTN TƏLƏBLƏRİ:**

1. **PERSONAJ İNKİŞAFI:**
   - Əsas personaj dərin, dəyişən
   - Daxili konflikt və ya qərar
   - Emosional inkişaf yolu

2. **SUJET STRUKTURU:**
   - Aydın başlanğıc, inkişaf, kulminasiya, həll
   - Gərginlik və maraq
   - Hadisələr ardıcıllığı

3. **EMOSİONAL VƏ ESTETİK ANLAM:**
   - Hisslərin təsviri (qorxu, sevinc, kədər, təəccüb)
   - Metafora və ya bənzətmə (sadə)
   - Dərs və ya dəyər

4. **DİL:**
   - Azərbaycan dili, sadə və aydın
   - Yaşa uyğun lüğət
   - Təsviri və canlı dil

5. **MƏDƏNI KONTEKST:**
   - Azərbaycan reallığı
   - Tanış situasiya və personajlar
   - Universal dəyərlər

**ÇIXIŞ FORMATI (JSON):**
```json
{
  "title": "Hekayənin başlığı",
  "word_count": 350,
  "text": "Tam hekayə mətni...",
  "main_character": "Personajın adı və qısa xarakteristika",
  "plot_summary": "Sujet xülasəsi (2-3 cümlə)",
  "emotional_arc": "Emosional inkişaf (başlanğıc → son)",
  "theme": "Əsas tema/dərs",
  "literary_devices": ["metafora 1", "bənzətmə 1"],
  "cultural_elements": ["Azərbaycan elementi 1", "element 2"]
}
```

Yalnız JSON formatında cavab ver, başqa heç nə yazma.
', theme, word_count)
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = ANTHROPIC_API_KEY,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(list(
      model = CLAUDE_MODEL,
      max_tokens = 4000,
      temperature = 0.8,
      messages = list(
        list(role = "user", content = prompt)
      )
    ), auto_unbox = TRUE),
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    content_data <- content(response, "parsed")
    json_text <- content_data$content[[1]]$text
    
    # Clean JSON
    json_text <- gsub("```json\\s*", "", json_text)
    json_text <- gsub("```\\s*$", "", json_text)
    json_text <- trimws(json_text)
    
    text_data <- fromJSON(json_text)
    
    cat(sprintf("✅ YARADILDI: %s (%d söz)\n", 
                text_data$title, text_data$word_count))
    
    return(text_data)
  } else {
    cat(sprintf("❌ Xəta: %s\n", content(response, "text")))
    return(NULL)
  }
}

# PIRLS SUALLAR YARATMAQ (ədəbi mətn üçün)
generate_pirls_literary_questions <- function(text_data) {
  
  prompt <- sprintf('
PIRLS formatında ədəbi mətn üçün 10 sual yarat.

**MƏTN:**
Başlıq: %s
%s

**PIRLS ƏDƏBİ MƏTN SUALLARININ FOKUSLAR:**

**1. RETRIEVE & FOCUS (3 sual - 1 bal):**
   - Hadisələri xatırlamaq
   - Personaj əməlləri
   - Vaxt və yer
   - Açıq faktlar

**2. INTERPRET & INTEGRATE (4 sual: 2 MC, 2 Short):**
   - Səbəb-nəticə əlaqəsi
   - Personajın motivasiyası
   - Hadisələrin əlaqəsi
   - Emosional vəziyyət
   - Nəticə çıxarmaq

**3. EVALUATE & CRITIQUE (3 sual: 1 MC, 1 Short, 1 Extended):**
   - Personaj qərarlarını qiymətləndirmək
   - Alternativ həllər
   - Mətndən dərs
   - Öz təcrübə ilə əlaqələndirmək
   - Əsaslandırılmış fikir

**SUAL TİPLƏRİ:**
- 5 Multiple Choice (1 bal)
- 3 Short Response (0-2 bal)
- 2 Extended Response (0-3 bal)

**JSON FORMAT:**
```json
{
  "text_id": null,
  "total_questions": 10,
  "max_score": 17,
  "questions": [
    {
      "question_number": 1,
      "question_text": "...",
      "question_type": "multiple_choice",
      "cognitive_level": "retrieve",
      "max_score": 1,
      "options": [
        {"option": "A", "text": "..."},
        {"option": "B", "text": "..."},
        {"option": "C", "text": "..."},
        {"option": "D", "text": "..."}
      ],
      "correct_answer": "A",
      "explanation": "..."
    },
    {
      "question_number": 6,
      "question_text": "Əsas personaj niyə bu qərarı verdi? İzah edin.",
      "question_type": "short_response",
      "cognitive_level": "interpret",
      "max_score": 2,
      "sample_answer": "...",
      "scoring_rubric": {
        "0": "Cavab yoxdur və ya tamamilə səhvdir",
        "1": "Qismən düzgün, mətn əsasında izah yoxdur",
        "2": "Tam düzgün, mətnə əsaslanır"
      }
    },
    {
      "question_number": 9,
      "question_text": "Personajın bu hekayədəki dəyişimini təsvir edin. Bu dəyişim nə öyrədir?",
      "question_type": "extended_response",
      "cognitive_level": "evaluate",
      "max_score": 3,
      "sample_answer": "...",
      "scoring_rubric": {
        "0": "Cavab yoxdur və ya məntiqsizdir",
        "1": "Çox qısa, dəyişimi göstərmir",
        "2": "Yaxşı, dəyişimi təsvir edir, lakin dərs aydın deyil",
        "3": "Əla - dəyişimi tam təsvir edir və dərsi əsaslandırır"
      }
    }
  ]
}
```

Yalnız JSON cavab ver.
', text_data$title, text_data$text)
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = ANTHROPIC_API_KEY,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(list(
      model = CLAUDE_MODEL,
      max_tokens = 6000,
      temperature = 0.7,
      messages = list(
        list(role = "user", content = prompt)
      )
    ), auto_unbox = TRUE),
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    content_data <- content(response, "parsed")
    json_text <- content_data$content[[1]]$text
    
    json_text <- gsub("```json\\s*", "", json_text)
    json_text <- gsub("```\\s*$", "", json_text)
    json_text <- trimws(json_text)
    
    questions_data <- fromJSON(json_text)
    
    cat(sprintf("✅ SUALLAR: 10 sual yaradıldı (max %d bal)\n", 
                questions_data$max_score))
    
    return(questions_data)
  } else {
    cat(sprintf("❌ Xəta: %s\n", content(response, "text")))
    return(NULL)
  }
}

# 12 ƏDƏBİ MƏTN YARATMAQ
generate_pirls_literary_batch <- function() {
  
  readRenviron("~/Desktop/Azərbaycan_dili_standartlar/.env")
  
  # PIRLS spesifik mövzular
  themes <- c(
    "Qorxunu məğlub etmək - uşaq ilk dəfə tək bir işi görür",
    "Dostluğun dəyəri - iki dost arasında anlaşılmazlıq və barışıq",
    "Vicdanlı qərar - uşaq düzgün və yanlış arasında seçim edir",
    "Ailə dəstəyi - çətin vaxtda ailəni kəşf etmək",
    "Xarici görünüş aldadır - kimsə gözlənilmədən köməkçi olur",
    "Səbr və əzmkarlıq - məqsədə çatmaq üçün çətinlikləri aşmaq",
    "Bağışlamaq öyrənmək - kiməsə haqsız davranışdan sonra bağışlamaq",
    "Fərqlilikləri qəbul etmək - yeni dostun fərqli adətləri",
    "Qürur və təvazökarlıq - təkəbbürdən dərs almaq",
    "Empatiya inkişafı - başqasının yerində olmağı anlamaq",
    "Məsuliyyət götürmək - xətanı etiraf etmək və düzəltmək",
    "Dəyişikliyə uyğunlaşmaq - yeni yer və ya vəziyyətə alışmaq"
  )
  
  all_texts <- list()
  
  for (i in 1:length(themes)) {
    cat(sprintf("\n[%d/%d] ", i, length(themes)))
    
    # Mətn yarat
    text_data <- generate_pirls_literary_text(themes[i], word_count = 350)
    
    if (!is.null(text_data)) {
      all_texts[[i]] <- text_data
    }
    
    Sys.sleep(3)  # Rate limit
  }
  
  # JSON-a saxla
  output_file <- sprintf("pirls_literary_texts_grade4_%s.json", 
                         format(Sys.Date(), "%Y%m%d"))
  
  write_json(all_texts, output_file, pretty = TRUE, auto_unbox = TRUE)
  
  cat(sprintf("\n\n✅ TAMAMLANDI: 12 ədəbi mətn\n"))
  cat(sprintf("📁 Fayl: %s\n", output_file))
  
  return(all_texts)
}

# MƏTN VƏ SUALLARI BAZAYA YÜKLƏMƏK
load_literary_texts_to_db <- function(json_file) {
  
  texts <- read_json(json_file)
  
  con <- get_db()
  
  # Text type ID - Nəqli mətn (Narration)
  text_type_id <- 2
  grade_id <- 4
  
  for (i in 1:length(texts)) {
    text <- texts[[i]]
    
    cat(sprintf("[%d/%d] %s\n", i, length(texts), text$title))
    
    # Mətni yüklə
    sample_id <- dbGetQuery(con, sprintf("
      INSERT INTO reading_literacy.text_samples
        (grade_id, text_type_id, title_az, content_az, word_count, 
         difficulty_level, source, created_by)
      VALUES (%d, %d, '%s', '%s', %d, 'intermediate', 'PIRLS Generator', 'Claude AI')
      RETURNING sample_id
    ", 
                                         grade_id, text_type_id,
                                         gsub("'", "''", text$title),
                                         gsub("'", "''", text$text),
                                         text$word_count
    ))$sample_id
    
    cat(sprintf("  ✓ Mətn ID: %d\n", sample_id))
  }
  
  dbDisconnect(con)
  
  cat("\n✅ Bütün mətnlər yükləndi!\n")
}

cat("✅ PIRLS ƏDƏBİ MƏTN GENERATOR yükləndi\n\n")
cat("İSTİFADƏ:\n")
cat("  1. texts <- generate_pirls_literary_batch()\n")
cat("  2. load_literary_texts_to_db('pirls_literary_texts_grade4_20260117.json')\n\n")