# ═══════════════════════════════════════════════════════════
# BATCH QİYMƏTLƏNDİRMƏ - OpenAI GPT-4o-mini
# ═══════════════════════════════════════════════════════════

library(DBI)
library(RPostgreSQL)
library(httr)
library(jsonlite)
library(dotenv)

load_dot_env()

get_db_connection <- function() {
  dbConnect(PostgreSQL(),
            dbname = "azerbaijan_language_standards",
            host = "localhost",
            port = 5432,
            user = "royatalibova")
}

grade_with_openai <- function(question_text, student_answer, rubric_criteria, max_score) {
  
  prompt <- sprintf('Sən PIRLS 2026 mütəxəssisi və təcrübəli müəllimsən. 4-cü sinif şagirdinin cavabını qiymətləndir.

SUAL: %s

ŞAGİRDİN CAVAŞI: %s

RUBRİK (Maksimum: %d bal):
%s

JSON formatda cavab ver:
{
  "score": 2,
  "max_score": %d,
  "rubric_level": "good",
  "feedback": "Qısa izah...",
  "confidence": 0.85
}', question_text, student_answer, max_score, rubric_criteria, max_score)
  
  tryCatch({
    response <- POST(
      url = "https://api.openai.com/v1/chat/completions",
      add_headers(
        "Authorization" = paste("Bearer", Sys.getenv("OPENAI_API_KEY")),
        "Content-Type" = "application/json"
      ),
      body = toJSON(list(
        model = "gpt-4o-mini",
        messages = list(list(role = "user", content = prompt)),
        temperature = 0.3,
        response_format = list(type = "json_object")
      ), auto_unbox = TRUE),
      encode = "json"
    )
    
    result <- content(response, "parsed")
    
    if (response$status_code != 200) {
      stop(sprintf("API Error: %s", result$error$message))
    }
    
    ai_json <- fromJSON(result$choices[[1]]$message$content)
    
    list(
      score = as.numeric(ai_json$score),
      rubric_level = ai_json$rubric_level,
      feedback = ai_json$feedback,
      confidence = as.numeric(ai_json$confidence),
      prompt_tokens = result$usage$prompt_tokens,
      response_tokens = result$usage$completion_tokens,
      success = TRUE
    )
  }, error = function(e) {
    list(score = 0, feedback = sprintf("Xəta: %s", e$message), success = FALSE)
  })
}

save_ai_grading_to_db <- function(con, answer_id, ai_result) {
  dbExecute(con, sprintf("
    UPDATE assessment.student_answers
    SET score_received = %f, ai_feedback = '%s', rubric_level = '%s'
    WHERE answer_id = %d
  ", ai_result$score, gsub("'", "''", ai_result$feedback), ai_result$rubric_level, answer_id))
  
  dbExecute(con, sprintf("
    INSERT INTO assessment.ai_grading_log 
    (answer_id, ai_model, prompt_tokens, response_tokens, ai_score, ai_reasoning, confidence_score)
    VALUES (%d, 'gpt-4o-mini', %d, %d, %f, '%s', %f)
  ", answer_id, ai_result$prompt_tokens, ai_result$response_tokens, ai_result$score, 
                         gsub("'", "''", ai_result$feedback), ai_result$confidence))
}

calculate_total_score <- function(con, result_id) {
  answers <- dbGetQuery(con, sprintf("
    SELECT q.question_type, sa.score_received, q.max_score
    FROM assessment.student_answers sa
    JOIN assessment.questions q ON sa.question_id = q.question_id
    WHERE sa.result_id = %d
  ", result_id))
  
  mc <- answers[answers$question_type == 'multiple_choice', ]
  open <- answers[answers$question_type == 'open_response', ]
  
  mc_score <- sum(mc$score_received, na.rm = TRUE)
  open_score <- sum(open$score_received, na.rm = TRUE)
  total_score <- mc_score + open_score
  total_possible <- sum(mc$max_score, na.rm = TRUE) + sum(open$max_score, na.rm = TRUE)
  percentage <- round(100 * total_score / total_possible, 2)
  
  dbExecute(con, sprintf("
    UPDATE assessment.student_test_results
    SET mc_score = %d, open_score = %f, total_score = %f, percentage = %f, 
        is_completed = TRUE, end_time = CURRENT_TIMESTAMP
    WHERE result_id = %d
  ", mc_score, open_score, total_score, percentage, result_id))
  
  list(mc_score = mc_score, open_score = open_score, total_score = total_score, percentage = percentage)
}

grade_test_openai <- function() {
  
  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("  OpenAI GPT-4o-mini İLƏ TEST QİYMƏTLƏNDİRMƏ\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  con <- get_db_connection()
  on.exit(dbDisconnect(con))
  
  cat("🎯 Test hazırlanır...\n")
  
  # Mövcud result_id-ni tap və ya yeni yarat
  result_id <- dbGetQuery(con, "
    SELECT result_id FROM assessment.student_test_results 
    WHERE student_id = 1 AND session_id = 1
  ")
  
  if (nrow(result_id) > 0) {
    result_id <- result_id$result_id[1]
    cat(sprintf("♻️ Mövcud test istifadə edilir: %d\n", result_id))
    
    # Köhnə cavabları sil
    dbExecute(con, sprintf("DELETE FROM assessment.student_answers WHERE result_id = %d", result_id))
    
    # Test parametrlərini yenilə
    dbExecute(con, sprintf("
      UPDATE assessment.student_test_results 
      SET start_time = CURRENT_TIMESTAMP - INTERVAL '15 minutes',
          is_completed = FALSE,
          mc_score = 0, open_score = 0, total_score = NULL
      WHERE result_id = %d
    ", result_id))
  } else {
    result_id <- dbGetQuery(con, "
      INSERT INTO assessment.student_test_results
      (student_id, session_id, start_time, mc_total, open_total, total_possible)
      SELECT 1, 1, CURRENT_TIMESTAMP - INTERVAL '15 minutes',
             SUM(CASE WHEN question_type = 'multiple_choice' THEN max_score ELSE 0 END),
             SUM(CASE WHEN question_type = 'open_response' THEN max_score ELSE 0 END),
             SUM(max_score)
      FROM assessment.questions WHERE text_sample_id = 228
      RETURNING result_id
    ")$result_id[1]
    cat(sprintf("🆕 Yeni test yaradıldı: %d\n", result_id))
  }
  
  cat(sprintf("✅ Result ID: %d\n\n", result_id))
  
  # QAŞALI
  cat("═══════════════════════════════════════════════════════════\n")
  cat("QAŞALI SUALLAR\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  mc_answers <- list(
    list(1, "A"), list(2, "C"), list(3, "B"), list(4, "C"), list(5, "B"),
    list(6, "C"), list(7, "D"), list(8, "B"), list(9, "C"), list(10, "B")
  )
  
  mc_score <- 0
  for (ans in mc_answers) {
    q <- dbGetQuery(con, sprintf("
      SELECT question_id, correct_answer, max_score
      FROM assessment.questions
      WHERE text_sample_id = 228 AND question_type = 'multiple_choice' AND question_number = %d
    ", ans[[1]]))
    
    is_correct <- (ans[[2]] == q$correct_answer)
    score <- if (is_correct) q$max_score else 0
    mc_score <- mc_score + score
    
    dbExecute(con, sprintf("
      INSERT INTO assessment.student_answers
      (result_id, question_id, student_answer, correct_answer, is_correct, score_received, max_score)
      VALUES (%d, %d, '%s', '%s', %s, %d, %d)
    ", result_id, q$question_id, ans[[2]], q$correct_answer, is_correct, score, q$max_score))
    
    cat(sprintf("  Sual %2d: %s (%d/1)\n", ans[[1]], if (is_correct) "✅" else "❌", score))
  }
  
  cat(sprintf("\n💯 Qapalı: %d/10\n\n", mc_score))
  
  # AÇIQ
  cat("═══════════════════════════════════════════════════════════\n")
  cat("AÇIQ SUALLAR - AI QİYMƏTLƏNDİRMƏ\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  open_answers <- list(
    list(11, 2, "Bərpa olunmayan enerji mənbələri bir dəfə istifadə edildikdən sonra yenidən yaranmır və tükənir, məsələn neft və qaz. Bərpa olunan enerji mənbələri isə təbiətdə daim yenilənir və heç vaxt tükənmir, məsələn günəş və külək enerjisi."),
    list(12, 2, "Azərbaycan 'Odlar Yurdu' adlanır, çünki ərazisində qədim zamanlardan neft və qaz çoxdur. Yeraltı qaz çıxışları alovlanaraq əbədi alovlar yaradırdı. Bu, neft və qaz enerji mənbəyi ilə əlaqədardır və tarixən Azərbaycanın neft zənginliyini göstərir."),
    list(13, 3, "Günəş enerjisi az istifadə olunur, çünki bir neçə səbəb var. Birincisi, günəş panelləri yeni texnologiyadır və quraşdırılması çox baha başa gəlir. İkincisi, Azərbaycan uzun illər neft və qaz ölkəsi olub və artıq neft infrastrukturu mövcuddur, ona görə neftə asılılıq davam edir. Üçüncüsü, su elektrik stansiyaları 50+ ildir işləyir və sınaqdan keçib, amma günəş enerjisi hələ yenidir və daha çox investisiya tələb edir."),
    list(14, 2, "Əgər 2030 planı həyata keçsə, bərpa olunan enerji 30%-ə çatacaq. İndi günəş və külək cəmi 3%, su 12%, yəni cəmi 15% bərpa olunandır. 2030-da bu 30% olacaq, yəni 2 dəfə artacaq. Neft və qazın payı 85%-dən azalıb təxminən 70% ola bilər."),
    list(15, 3, "Mənə ən asan görünən məsləhət 'otaqdan çıxanda işığı söndürmək'dir. Çünki bu, heç bir texnologiya və ya pul tələb etmir, sadəcə vərdiş məsələsidir. Hər kəs bunu edə bilər və dərhal təsir göstərir. Digər məsləhətlər, məsələn enerjiyə qənaət edən lampa almaq, pul tələb edir və ya kondisioner temperaturunu tənzimləmək daha mürəkkəbdir. Amma işığı söndürmək bir saniyəlik iş və böyük təsirlidir."),
    list(16, 3, "Bu, mətn Xəzər dənizi haqqında deyil, enerji haqqındadır. Mən düşünürəm ki, burada xəta var və ya müəllif demək istəyir ki, 'təbiəti və enerji mənbələrini qorumaq hamımızın borcudur.' Çünki mətn Azərbaycanda enerji haqqındadır və neft hasilatı Xəzərdə aparılır, ona görə Xəzəri qorumaq da vacibdir. Amma bu cümlə mətnin əsas mövzusu deyil."),
    list(17, 3, "Mən düşünürəm ki, tarazlı yanaşma olmalıdır. Tam imtina etmək nə üçün pis: Neft və qaz Azərbaycanın iqtisadiyyatının əsasıdır, milyonlarla iş yeri və dövlət gəliri buradan gəlir. Əgər birdən-birə dayandırılsa, iqtisadiyyat çökər və insanlar işsiz qalar. Amma digər tərəfdən, neft tükənən mənbəydir və ətraf mühitə zərər verir, ona görə yavaş-yavaş bərpa olunan enerjiyə keçid etməliyik. 2030 planı (30% bərpa olunan) məhz bu tarazlı yanaşmadır - nə tam imtina, nə də davam etdirmək, əvəzinə tədricən dəyişmək."),
    list(18, 3, "Bəli, rəqəmlər mətnin inandırıcılığını artırır, çünki dəqiq məlumat verir və əzbər danışıq deyil, faktlara əsaslanır. Məsələn, '85% neft və qaz' deyəndə anlaşılır ki, bu əsas mənbəydir. Amma bir problem var: mətn mənbə qeyd etmir. Bu rəqəmlər haradan gəlir? Dövlət statistikası? Hansı il? 2020 və 2024 fərqli ola bilər. Ona görə rəqəmlər yaxşıdır, amma mənbə və tarix olmadan tam etibarlı deyil. Daha yaxşı olardı ki, 'Dövlət Statistika Komitəsi 2023' və ya belə bir şey yazılaydı.")
  )
  
  open_score <- 0
  for (ans in open_answers) {
    q <- dbGetQuery(con, sprintf("
      SELECT question_id, question_text
      FROM assessment.questions
      WHERE text_sample_id = 228 AND question_type = 'open_response' AND question_number = %d
    ", ans[[1]]))
    
    cat(sprintf("🤖 Sual %d... ", ans[[1]]))
    
    rubric <- sprintf("%d bal: Tam | 1 bal: Qismən | 0 bal: Yox", ans[[2]])
    
    ai_result <- grade_with_openai(q$question_text, ans[[3]], rubric, ans[[2]])
    
    if (!ai_result$success) {
      cat(sprintf("❌ %s\n", ai_result$feedback))
      next
    }
    
    answer_id <- dbGetQuery(con, sprintf("
      INSERT INTO assessment.student_answers
      (result_id, question_id, student_answer, max_score, score_received)
      VALUES (%d, %d, '%s', %d, %f)
      RETURNING answer_id
    ", result_id, q$question_id, gsub("'", "''", ans[[3]]), ans[[2]], ai_result$score))$answer_id[1]
    
    save_ai_grading_to_db(con, answer_id, ai_result)
    
    open_score <- open_score + ai_result$score
    cat(sprintf("✅ %.1f/%d\n", ai_result$score, ans[[2]]))
    
    Sys.sleep(0.5)
  }
  
  cat(sprintf("\n💯 Açıq: %.1f/26\n\n", open_score))
  
  # YEKUN
  total <- calculate_total_score(con, result_id)
  
  cat("═══════════════════════════════════════════════════════════\n")
  cat(sprintf("🎯 ÜMUMİ: %.1f/36 (%.1f%%)\n", total$total_score, total$percentage))
  
  grade <- if (total$percentage >= 90) "Əla (A)"
  else if (total$percentage >= 80) "Yaxşı (B)"
  else if (total$percentage >= 70) "Kafi (C)"
  else if (total$percentage >= 60) "Qənaətbəxş (D)"
  else "Zəif (F)"
  
  cat(sprintf("📊 QİYMƏT: %s\n", grade))
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  invisible(total)
}