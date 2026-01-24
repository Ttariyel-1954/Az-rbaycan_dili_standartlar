-- ═══════════════════════════════════════════════════════════
-- POSTGRESQL BAZA ANALİZ SORĞULARI
-- Birbaşa psql və ya pgAdmin-də istifadə üçün
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- 1. ÜMUMİ STATİSTİKA
-- ═══════════════════════════════════════════════════════════

-- Mətn sayı
SELECT COUNT(*) as total_texts 
FROM reading_literacy.text_samples 
WHERE grade_id = 4;

-- Sual sayı
SELECT COUNT(*) as total_questions
FROM assessment.questions q
JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
WHERE ts.grade_id = 4;

-- Ümumi söz sayı
SELECT SUM(word_count) as total_words
FROM reading_literacy.text_samples
WHERE grade_id = 4;

-- Orta sual/mətn
SELECT ROUND(AVG(q_count), 2) as avg_questions_per_text
FROM (
    SELECT COUNT(q.question_id) as q_count
    FROM reading_literacy.text_samples ts
    LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
    WHERE ts.grade_id = 4
    GROUP BY ts.sample_id
) sub;

-- ═══════════════════════════════════════════════════════════
-- 2. MƏTN NÖVÜNƏ GÖRƏ BÖLGÜ
-- ═══════════════════════════════════════════════════════════

SELECT 
    CASE text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM reading_literacy.text_samples
WHERE grade_id = 4
GROUP BY text_type_id
ORDER BY count DESC;

-- ═══════════════════════════════════════════════════════════
-- 3. SUAL TİPİNƏ GÖRƏ BÖLGÜ
-- ═══════════════════════════════════════════════════════════

SELECT 
    q.question_type,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage,
    SUM(q.max_score) as total_points
FROM assessment.questions q
JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
WHERE ts.grade_id = 4
GROUP BY q.question_type
ORDER BY count DESC;

-- ═══════════════════════════════════════════════════════════
-- 4. ƏTRAFLӦ MƏTN SİYAHISI
-- ═══════════════════════════════════════════════════════════

SELECT 
    ts.sample_id,
    ts.title_az,
    ts.word_count,
    CASE ts.text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type,
    ts.created_at::date as created_date,
    COUNT(q.question_id) as question_count,
    SUM(CASE WHEN q.question_type = 'multiple_choice' THEN 1 ELSE 0 END) as mc_count,
    SUM(CASE WHEN q.question_type = 'open_response' THEN 1 ELSE 0 END) as open_count,
    COALESCE(SUM(q.max_score), 0) as total_points
FROM reading_literacy.text_samples ts
LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
WHERE ts.grade_id = 4
GROUP BY ts.sample_id, ts.title_az, ts.word_count, ts.text_type_id, ts.created_at
ORDER BY ts.sample_id DESC;

-- ═══════════════════════════════════════════════════════════
-- 5. SÖZ SAYI STATİSTİKASI
-- ═══════════════════════════════════════════════════════════

SELECT 
    MIN(word_count) as min_words,
    MAX(word_count) as max_words,
    ROUND(AVG(word_count), 0) as avg_words,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY word_count) as median_words
FROM reading_literacy.text_samples
WHERE grade_id = 4;

-- Mətn növünə görə orta söz sayı
SELECT 
    CASE ts.text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type,
    ROUND(AVG(ts.word_count), 0) as avg_words,
    MIN(ts.word_count) as min_words,
    MAX(ts.word_count) as max_words
FROM reading_literacy.text_samples ts
WHERE ts.grade_id = 4
GROUP BY ts.text_type_id
ORDER BY avg_words DESC;

-- ═══════════════════════════════════════════════════════════
-- 6. SUAL BÖLGÜSÜ - MƏTNLƏRƏ GÖRƏ
-- ═══════════════════════════════════════════════════════════

SELECT 
    ts.sample_id,
    ts.title_az,
    COUNT(q.question_id) as total_questions,
    SUM(CASE WHEN q.question_type = 'multiple_choice' THEN 1 ELSE 0 END) as mc_questions,
    SUM(CASE WHEN q.question_type = 'open_response' THEN 1 ELSE 0 END) as open_questions,
    SUM(q.max_score) as total_points,
    SUM(CASE WHEN q.question_type = 'multiple_choice' THEN q.max_score ELSE 0 END) as mc_points,
    SUM(CASE WHEN q.question_type = 'open_response' THEN q.max_score ELSE 0 END) as open_points
FROM reading_literacy.text_samples ts
LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
WHERE ts.grade_id = 4
GROUP BY ts.sample_id, ts.title_az
ORDER BY total_questions DESC;

-- ═══════════════════════════════════════════════════════════
-- 7. BAL BÖLGÜSÜ - AÇIQ SUALLARDA
-- ═══════════════════════════════════════════════════════════

SELECT 
    max_score,
    COUNT(*) as question_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM assessment.questions q
JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
WHERE ts.grade_id = 4 
  AND q.question_type = 'open_response'
GROUP BY max_score
ORDER BY max_score;

-- ═══════════════════════════════════════════════════════════
-- 8. PIRLS UYĞUNLUĞU
-- ═══════════════════════════════════════════════════════════

SELECT 
    CASE 
        WHEN pirls_2026_compliant THEN 'PIRLS Uyğun'
        ELSE 'PIRLS Uyğun Deyil'
    END as compliance,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM reading_literacy.text_samples
WHERE grade_id = 4
GROUP BY pirls_2026_compliant;

-- ═══════════════════════════════════════════════════════════
-- 9. TARİXƏ GÖRƏ MƏTN ƏLAVƏSI
-- ═══════════════════════════════════════════════════════════

SELECT 
    created_at::date as date,
    COUNT(*) as texts_added,
    SUM(COUNT(*)) OVER (ORDER BY created_at::date) as cumulative_total
FROM reading_literacy.text_samples
WHERE grade_id = 4
GROUP BY created_at::date
ORDER BY created_at::date;

-- ═══════════════════════════════════════════════════════════
-- 10. ƏN UZUN VƏ ƏN QISA MƏTNLƏR
-- ═══════════════════════════════════════════════════════════

-- Ən uzun 10 mətn
SELECT 
    sample_id,
    title_az,
    word_count,
    CASE text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type
FROM reading_literacy.text_samples
WHERE grade_id = 4
ORDER BY word_count DESC
LIMIT 10;

-- Ən qısa 10 mətn
SELECT 
    sample_id,
    title_az,
    word_count,
    CASE text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type
FROM reading_literacy.text_samples
WHERE grade_id = 4
ORDER BY word_count ASC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════
-- 11. ƏN ÇOX VƏ ƏN AZ SUALLI MƏTNLƏR
-- ═══════════════════════════════════════════════════════════

WITH question_counts AS (
    SELECT 
        ts.sample_id,
        ts.title_az,
        COUNT(q.question_id) as question_count
    FROM reading_literacy.text_samples ts
    LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
    WHERE ts.grade_id = 4
    GROUP BY ts.sample_id, ts.title_az
)
-- Ən çox suallı
SELECT * FROM question_counts ORDER BY question_count DESC LIMIT 10;

-- Ən az suallı
SELECT * FROM question_counts ORDER BY question_count ASC LIMIT 10;

-- ═══════════════════════════════════════════════════════════
-- 12. QAPALӦ SUALЛARDA VARIANT SAYI
-- ═══════════════════════════════════════════════════════════

SELECT 
    ts.sample_id,
    ts.title_az,
    q.question_number,
    jsonb_array_length(q.options::jsonb) as option_count
FROM assessment.questions q
JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
WHERE ts.grade_id = 4 
  AND q.question_type = 'multiple_choice'
  AND q.options IS NOT NULL
ORDER BY ts.sample_id, q.question_number;

-- ═══════════════════════════════════════════════════════════
-- 13. BAZA STRUKTURU
-- ═══════════════════════════════════════════════════════════

-- Cədvəl ölçüləri
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables
WHERE schemaname IN ('reading_literacy', 'assessment')
ORDER BY size_bytes DESC;

-- Sütun məlumatları - text_samples
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'reading_literacy' 
  AND table_name = 'text_samples'
ORDER BY ordinal_position;

-- Sütun məlumatları - questions
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'assessment' 
  AND table_name = 'questions'
ORDER BY ordinal_position;

-- ═══════════════════════════════════════════════════════════
-- 14. AXTARIŞ SORĞULARI
-- ═══════════════════════════════════════════════════════════

-- Mətnlərdə açar söz axtarışı
SELECT 
    sample_id,
    title_az,
    word_count,
    LEFT(content_az, 200) as preview
FROM reading_literacy.text_samples
WHERE grade_id = 4
  AND (
    LOWER(title_az) LIKE '%internet%' 
    OR LOWER(content_az) LIKE '%internet%'
  );

-- Suallarda açar söz axtarışı
SELECT 
    ts.sample_id,
    ts.title_az,
    q.question_number,
    q.question_text
FROM assessment.questions q
JOIN reading_literacy.text_samples ts ON q.text_sample_id = ts.sample_id
WHERE ts.grade_id = 4
  AND LOWER(q.question_text) LIKE '%niyə%';

-- ═══════════════════════════════════════════════════════════
-- 15. KOMPLEKSİB SORpU - TAM MƏTN MƏLUMATI
-- ═══════════════════════════════════════════════════════════

SELECT 
    ts.sample_id,
    ts.title_az,
    ts.title_en,
    ts.word_count,
    ts.grade_id,
    CASE ts.text_type_id
        WHEN 1 THEN 'Bədii'
        WHEN 2 THEN 'Məlumatverici'
        WHEN 3 THEN 'Əmredicə'
        ELSE 'Digər'
    END as text_type,
    ts.source,
    ts.notes,
    ts.created_at,
    ts.pirls_2026_compliant,
    -- Sual statistikası
    COUNT(q.question_id) as total_questions,
    SUM(CASE WHEN q.question_type = 'multiple_choice' THEN 1 ELSE 0 END) as mc_questions,
    SUM(CASE WHEN q.question_type = 'open_response' THEN 1 ELSE 0 END) as open_questions,
    COALESCE(SUM(q.max_score), 0) as total_points,
    -- Mətn preview
    LEFT(ts.content_az, 500) as content_preview
FROM reading_literacy.text_samples ts
LEFT JOIN assessment.questions q ON ts.sample_id = q.text_sample_id
WHERE ts.grade_id = 4
  AND ts.sample_id = 235  -- Mətn ID-ni dəyişdirin
GROUP BY ts.sample_id, ts.title_az, ts.title_en, ts.word_count, ts.grade_id,
         ts.text_type_id, ts.source, ts.notes, 
         ts.created_at, ts.pirls_2026_compliant, ts.content_az;

-- ═══════════════════════════════════════════════════════════
-- 16. PERFORMANS VƏ İNDEKSLƏR
-- ═══════════════════════════════════════════════════════════

-- Mövcud indekslər
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname IN ('reading_literacy', 'assessment')
ORDER BY schemaname, tablename, indexname;

-- ═══════════════════════════════════════════════════════════
-- İSTİFADƏ QEYDLƏRI:
-- ═══════════════════════════════════════════════════════════
-- 
-- 1. Bu sorğuları psql-də birbaşa çalışdırın:
--    psql -U royatalibova -d azerbaijan_language_standards
--
-- 2. və ya sorğunu fayldan çalışdırın:
--    psql -U royatalibova -d azerbaijan_language_standards -f bu_fayl.sql
--
-- 3. Nəticələri CSV-ə export edin:
--    \copy (SELECT ...) TO 'output.csv' CSV HEADER
--
-- 4. pgAdmin-də istifadə üçün:
--    Query Tool-da sorğunu yapışdırıb çalışdırın
--
-- ═══════════════════════════════════════════════════════════
