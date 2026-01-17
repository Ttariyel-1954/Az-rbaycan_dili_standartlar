# PIRLS Format Sual Generatoru
# 10 sual: 5 MC + 3 Short + 2 Extended
# 4 Cognitive Level: Retrieve, Infer, Interpret, Evaluate

library(tidyverse)
library(RPostgreSQL)
library(DBI)
library(httr)
library(jsonlite)

ANTHROPIC_API_KEY <- Sys.getenv("ANTHROPIC_API_KEY")
CLAUDE_MODEL <- "claude-sonnet-4-20250514"

clean_json_response <- function(text) {
  text <- gsub("```json\\s*", "", text)
  text <- gsub("```\\s*$", "", text)
  text <- trimws(text)
  return(text)
}

# PIRLS formatında sual yaratmaq
generate_pirls_questions <- function(text_data) {
  
  prompt <- sprintf('
Azərbaycan dili %s sinif üçün mətn verilir. PIRLS (Progress in International Reading Literacy Study) formatında 10 sual yarat.

**MƏTN:**
Başlıq: %s
Mətn: %s

**PIRLS FORMAT TƏLƏBLƏRİ:**

Dəqiq 10 sual yarat:
1. **5 Multiple Choice** (4 variant, 1 düzgün) - hər biri 1 bal
2. **3 Short Response** (1-2 cümlə cavab) - hər biri 0-2 bal
3. **2 Extended Response** (3-5 cümlə cavab) - hər biri 0-3 bal

**COGNITIVE LEVELS:**
- **Retrieve** (4 sual): Mətnin açıq məlumatını tapmaq
- **Infer** (3 sual): Məntiq yürütmək, nəticə çıxarmaq
- **Interpret** (2 sual): Şərh etmək, mənaları birləşdirmək
- **Evaluate** (1 sual): Qiymətləndirmək, tənqidi düşünmək

**SCORING RUBRIC (Short və Extended üçün):**

Short Response (2 bal):
- 0: Cavab yoxdur və ya tamamilə səhvdir
- 1: Qismən düzgün, lakin natamam
- 2: Tam və düzgün cavab

Extended Response (3 bal):
- 0: Cavab yoxdur və ya məntiqsizdir
- 1: Çox qısa, əsaslandırma yoxdur
- 2: Yaxşı, lakin daha ətraflı ola bilərdi
- 3: Əla, tam əsaslandırılmış cavab

**JSON FORMAT:**
```json
{
  "text_id": %d,
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
      "question_text": "...",
      "question_type": "short_response",
      "cognitive_level": "infer",
      "max_score": 2,
      "sample_answer": "...",
      "scoring_rubric": {
        "0": "...",
        "1": "...",
        "2": "..."
      }
    },
    {
      "question_number": 9,
      "question_text": "...",
      "question_type": "extended_response",
      "cognitive_level": "evaluate",
      "max_score": 3,
      "sample_answer": "...",
      "scoring_rubric": {
        "0": "...",
        "1": "...",
        "2": "...",
        "3": "..."
      }
    }
  ]
}
```

**ÖNƏMLİ:**
- Suallar yaşa uyğun olsun (%s sinif)
- Azərbaycan dilində aydın, sadə dillə
- Hər sual mətnə əsaslanmalıdır
- Variantlar realist və çaşdırıcı olmalıdır

Yalnız JSON formatında cavab ver, başqa heç nə yazma.
',
                    text_data$grade_name_az,
                    text_data$title_az,
                    text_data$content_az,
                    text_data$sample_id,
                    text_data$grade_name_az
  )
  
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
    
    json_text <- clean_json_response(json_text)
    
    questions_data <- fromJSON(json_text)
    
    cat(sprintf("✅ PIRLS: %s - 10 sual yaradıldı (max %d bal)\n", 
                text_data$title_az, questions_data$max_score))
    
    return(questions_data)
  } else {
    cat(sprintf("❌ Xəta: %s\n", content(response, "text")))
    return(NULL)
  }
}

# Toplu sual yaratmaq
generate_questions_batch <- function(grade_level, num_texts = 15) {
  
  readRenviron("~/Desktop/Azərbaycan_dili_standartlar/.env")
  
  con <- dbConnect(PostgreSQL(), 
                   dbname = "azerbaijan_language_standards",
                   host = "localhost", 
                   port = 5432, 
                   user = "royatalibova")
  
  # Mətnləri seç
  texts <- dbGetQuery(con, sprintf("
    SELECT ts.sample_id, ts.title_az, ts.content_az, ts.word_count,
           g.grade_level, g.grade_name_az
    FROM reading_literacy.text_samples ts
    JOIN reading_literacy.grades g ON ts.grade_id = g.grade_id
    WHERE g.grade_level = %d
    ORDER BY ts.sample_id
    LIMIT %d
  ", grade_level, num_texts))
  
  dbDisconnect(con)
  
  cat(sprintf("\n📚 %s üçün %d mətn seçildi\n\n", 
              texts$grade_name_az[1], nrow(texts)))
  
  all_questions <- list()
  
  for (i in 1:nrow(texts)) {
    cat(sprintf("[%d/%d] ", i, nrow(texts)))
    
    questions <- generate_pirls_questions(texts[i,])
    
    if (!is.null(questions)) {
      all_questions[[i]] <- questions
    }
    
    Sys.sleep(2)  # Rate limit
  }
  
  # JSON-a saxla
  output_file <- sprintf("pirls_questions_grade_%d.json", grade_level)
  write_json(all_questions, output_file, pretty = TRUE, auto_unbox = TRUE)
  
  cat(sprintf("\n\n✅ Tamamlandı! %d mətn, ~%d sual\n", 
              length(all_questions), length(all_questions) * 10))
  cat(sprintf("📁 Fayl: %s\n", output_file))
  
  return(all_questions)
}

# Bazaya yükləmək
load_pirls_questions_to_db <- function(json_file) {
  
  questions_data <- read_json(json_file)
  
  con <- dbConnect(PostgreSQL(), 
                   dbname = "azerbaijan_language_standards",
                   host = "localhost", 
                   port = 5432, 
                   user = "royatalibova")
  
  # Cədvəl strukturu yenilə (max_score əlavə et)
  dbExecute(con, "
    ALTER TABLE assessment.questions 
    ADD COLUMN IF NOT EXISTS max_score INTEGER DEFAULT 1
  ")
  
  dbExecute(con, "
    ALTER TABLE assessment.questions 
    ADD COLUMN IF NOT EXISTS sample_answer TEXT
  ")
  
  dbExecute(con, "
    ALTER TABLE assessment.questions 
    ADD COLUMN IF NOT EXISTS scoring_rubric JSONB
  ")
  
  # Sualları daxil et
  for (text_q in questions_data) {
    text_id <- text_q$text_id
    
    for (q in text_q$questions) {
      
      options_json <- ifelse(
        !is.null(q$options),
        toJSON(q$options, auto_unbox = TRUE),
        "null"
      )
      
      rubric_json <- ifelse(
        !is.null(q$scoring_rubric),
        gsub("'", "''", toJSON(q$scoring_rubric, auto_unbox = TRUE)),
        "null"
      )
      
      query <- sprintf("
        INSERT INTO assessment.questions (
          text_sample_id, question_number, question_text,
          question_type, cognitive_level, max_score,
          options, correct_answer, sample_answer, 
          scoring_rubric, explanation
        ) VALUES (
          %d, %d, '%s', '%s', '%s', %d,
          '%s'::jsonb, '%s', '%s', '%s'::jsonb, '%s'
        )
      ",
                       text_id,
                       q$question_number,
                       gsub("'", "''", q$question_text),
                       q$question_type,
                       q$cognitive_level,
                       ifelse(is.null(q$max_score), 1, q$max_score),
                       options_json,
                       ifelse(is.null(q$correct_answer), "", q$correct_answer),
                       ifelse(is.null(q$sample_answer), "", gsub("'", "''", q$sample_answer)),
                       rubric_json,
                       ifelse(is.null(q$explanation), "", gsub("'", "''", q$explanation))
      )
      
      dbExecute(con, query)
    }
    
    cat(sprintf("✅ Mətn ID %d yükləndi\n", text_id))
  }
  
  dbDisconnect(con)
  
  cat("\n✅ Bütün suallar bazaya yükləndi!\n")
}

cat("✅ PIRLS Question Generator yükləndi\n")
cat("\nİSTİFADƏ:\n")
cat("  1. generate_questions_batch(grade_level = 2, num_texts = 15)\n")
cat("  2. load_pirls_questions_to_db('pirls_questions_grade_2.json')\n")