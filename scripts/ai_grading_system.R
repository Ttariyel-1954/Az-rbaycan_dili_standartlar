# ═══════════════════════════════════════════════════════════
# AI AÇIQ CAVAB QİYMƏTLƏNDİRMƏ SİSTEMİ
# Claude API istifadə edərək rubrik əsaslı qiymətləndirmə
# ═══════════════════════════════════════════════════════════

library(httr)
library(jsonlite)
library(DBI)
library(RPostgreSQL)

# ═══════════════════════════════════════════════════════════
# BAZA BAĞLANTISI
# ═══════════════════════════════════════════════════════════

get_db_connection <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

# ═══════════════════════════════════════════════════════════
# AI QİYMƏTLƏNDİRMƏ FUNKSİYASI
# ═══════════════════════════════════════════════════════════

grade_open_response_with_ai <- function(
    question_text,
    student_answer,
    rubric_criteria,
    max_score,
    text_content = NULL  # Mətnin özü (kontekst)
) {
  
  # Prompt hazırlama
  prompt <- sprintf('
Sən PIRLS 2026 mütəxəssisi və təcrübəli müəllimsən. 4-cü sinif şagirdinin açıq cavab sualına verdiyi cavabı qiymətləndirməlisən.

**SUAL:**
%s

**ŞAGİRDİN CAVAŞI:**
%s

**RUBRİK (Maksimum bal: %d):**
%s

%s

**TAPŞıRIQ:**
1. Şagirdin cavabını diqqətlə oxu
2. Rubrik meyarlarına əsasən qiymətləndir
3. Dəqiq bal ver (0-%d arası)
4. Qısa əsaslandırma yaz (2-3 cümlə)

**CAVAB FORMATI (JSON):**
```json
{
  "score": 2,
  "max_score": %d,
  "rubric_level": "good",
  "feedback": "Şagird əsas fikri düzgün başa düşüb və bir nümunə verib. İkinci nümunə və ya daha dərin izah olsa daha yaxşı olardı.",
  "confidence": 0.85
}
```

**RUBRIC_LEVEL seçimləri:**
- "excellent" - Tam və mükəmməl cavab
- "good" - Yaxşı, kiçik çatışmazlıqlar
- "partial" - Qismən düzgün
- "poor" - Çox zəif və ya yanlış

Yalnız JSON cavab ver, başqa heç nə yazma!
',
    question_text,
    student_answer,
    max_score,
    rubric_criteria,
    if (!is.null(text_content)) sprintf("**MƏTN KONTEKSTİ:**\n%s\n", substr(text_content, 1, 1000)) else "",
    max_score,
    max_score
  )
  
  # Claude API çağırışı
  tryCatch({
    response <- POST(
      url = "https://api.anthropic.com/v1/messages",
      add_headers(
        "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),  # API key environment variable-dan
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      ),
      body = toJSON(list(
        model = "claude-sonnet-4-20250514",
        max_tokens = 1000,
        messages = list(
          list(
            role = "user",
            content = prompt
          )
        )
      ), auto_unbox = TRUE),
      encode = "json"
    )
    
    # Cavabı parse et
    result <- content(response, "parsed")
    
    if (response$status_code != 200) {
      stop(sprintf("API Error: %s", result$error$message))
    }
    
    # JSON cavabı çıxart
    ai_text <- result$content[[1]]$text
    
    # JSON parse et
    ai_json <- fromJSON(ai_text)
    
    # Nəticə
    list(
      score = as.numeric(ai_json$score),
      max_score = as.numeric(ai_json$max_score),
      rubric_level = ai_json$rubric_level,
      feedback = ai_json$feedback,
      confidence = as.numeric(ai_json$confidence),
      prompt_tokens = result$usage$input_tokens,
      response_tokens = result$usage$output_tokens,
      success = TRUE,
      error = NULL
    )
    
  }, error = function(e) {
    list(
      score = 0,
      max_score = max_score,
      rubric_level = "error",
      feedback = sprintf("AI qiymətləndirmə xətası: %s", e$message),
      confidence = 0,
      prompt_tokens = 0,
      response_tokens = 0,
      success = FALSE,
      error = e$message
    )
  })
}

# ═══════════════════════════════════════════════════════════
# ÇOXLU CAVABI QİYMƏTLƏNDİRMƏ
# ═══════════════════════════════════════════════════════════

grade_multiple_open_responses <- function(answers_df) {
  # answers_df struktur:
  # - answer_id, question_id, question_text, student_answer, 
  #   rubric_criteria, max_score, text_content
  
  results <- list()
  
  for (i in 1:nrow(answers_df)) {
    cat(sprintf("\n[%d/%d] Qiymətləndiriliir...\n", i, nrow(answers_df)))
    
    result <- grade_open_response_with_ai(
      question_text = answers_df$question_text[i],
      student_answer = answers_df$student_answer[i],
      rubric_criteria = answers_df$rubric_criteria[i],
      max_score = answers_df$max_score[i],
      text_content = answers_df$text_content[i]
    )
    
    result$answer_id <- answers_df$answer_id[i]
    results[[i]] <- result
    
    # API rate limit (1 saniyə pauza)
    Sys.sleep(1)
  }
  
  do.call(rbind, lapply(results, as.data.frame))
}

# ═══════════════════════════════════════════════════════════
# BAZAYA YAZMA
# ═══════════════════════════════════════════════════════════

save_ai_grading_to_db <- function(con, answer_id, ai_result) {
  
  # 1. student_answers cədvəlinə bal yaz
  dbExecute(con, sprintf("
    UPDATE assessment.student_answers
    SET 
      score_received = %f,
      ai_feedback = '%s',
      rubric_level = '%s'
    WHERE answer_id = %d
  ", 
    ai_result$score,
    gsub("'", "''", ai_result$feedback),  # SQL injection防止
    ai_result$rubric_level,
    answer_id
  ))
  
  # 2. ai_grading_log-a yaz
  dbExecute(con, sprintf("
    INSERT INTO assessment.ai_grading_log 
    (answer_id, ai_model, prompt_tokens, response_tokens, 
     ai_score, ai_reasoning, confidence_score)
    VALUES (%d, 'claude-sonnet-4', %d, %d, %f, '%s', %f)
  ",
    answer_id,
    ai_result$prompt_tokens,
    ai_result$response_tokens,
    ai_result$score,
    gsub("'", "''", ai_result$feedback),
    ai_result$confidence
  ))
}

# ═══════════════════════════════════════════════════════════
# ÜMUMİ BAL HESABLAMA VƏ YENİLƏMƏ
# ═══════════════════════════════════════════════════════════

calculate_total_score <- function(con, result_id) {
  
  # Bütün cavabları çək
  answers <- dbGetQuery(con, sprintf("
    SELECT 
      question_type,
      score_received,
      max_score
    FROM assessment.student_answers sa
    JOIN assessment.questions q ON sa.question_id = q.question_id
    WHERE sa.result_id = %d
  ", result_id))
  
  # Qapalı suallar (multiple_choice)
  mc_answers <- answers[answers$question_type == 'multiple_choice', ]
  mc_score <- sum(mc_answers$score_received, na.rm = TRUE)
  mc_total <- sum(mc_answers$max_score, na.rm = TRUE)
  
  # Açıq suallar (open_response)
  open_answers <- answers[answers$question_type == 'open_response', ]
  open_score <- sum(open_answers$score_received, na.rm = TRUE)
  open_total <- sum(open_answers$max_score, na.rm = TRUE)
  
  # Ümumi
  total_score <- mc_score + open_score
  total_possible <- mc_total + open_total
  percentage <- round(100 * total_score / total_possible, 2)
  
  # Bazaya yenilə
  dbExecute(con, sprintf("
    UPDATE assessment.student_test_results
    SET 
      mc_score = %d,
      mc_total = %d,
      open_score = %f,
      open_total = %d,
      total_score = %f,
      total_possible = %d,
      percentage = %f,
      is_completed = TRUE,
      end_time = CURRENT_TIMESTAMP,
      duration_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time))/60
    WHERE result_id = %d
  ",
    mc_score, mc_total,
    open_score, open_total,
    total_score, total_possible,
    percentage,
    result_id
  ))
  
  list(
    mc_score = mc_score,
    mc_total = mc_total,
    open_score = open_score,
    open_total = open_total,
    total_score = total_score,
    total_possible = total_possible,
    percentage = percentage
  )
}

# ═══════════════════════════════════════════════════════════
# İSTİFADƏ NÜMUNƏSİ
# ═══════════════════════════════════════════════════════════

demo_ai_grading <- function() {
  
  cat("════════════════════════════════════════\n")
  cat("AI QİYMƏTLƏNDİRMƏ DEMO\n")
  cat("════════════════════════════════════════\n\n")
  
  # Nümunə sual və cavab
  question <- "Mətnə əsasən, bərpa olunan və bərpa olunmayan enerji mənbələri arasında əsas fərq nədir? İki nümunə göstər."
  
  student_answer <- "Bərpa olunmayan mənbələr bir dəfə istifadə olunduqdan sonra yenidən yaranmır və tükənir. Məsələn, neft və qaz. Bərpa olunan mənbələr isə təbiətdə daim yenilənir və heç vaxt bitmir. Məsələn, günəş və külək enerjisi."
  
  rubric <- "
2 bal: Fərqi aydın izah edir + HƏR iki qrupdan düzgün nümunə
1 bal: Fərqi qeyd edir amma izah zəif, və ya yalnız 1 nümunə
0 bal: Fərq yoxdur və ya tamamilə yanlış"
  
  # AI qiymətləndirmə
  result <- grade_open_response_with_ai(
    question_text = question,
    student_answer = student_answer,
    rubric_criteria = rubric,
    max_score = 2
  )
  
  # Nəticəni göstər
  cat("📊 QİYMƏTLƏNDİRMƏ NƏTİCƏSİ:\n")
  cat(sprintf("   Bal: %d/%d\n", result$score, result$max_score))
  cat(sprintf("   Səviyyə: %s\n", result$rubric_level))
  cat(sprintf("   Əminlik: %.0f%%\n", result$confidence * 100))
  cat(sprintf("\n💬 FEEDBACK:\n   %s\n\n", result$feedback))
  
  invisible(result)
}

# Test et:
# demo_ai_grading()
