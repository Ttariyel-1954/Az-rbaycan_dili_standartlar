-- ═══════════════════════════════════════════════════════════
-- İMTAHAN NƏTİCƏLƏRİ BAZA STRUKTURU
-- ═══════════════════════════════════════════════════════════

-- 1. ŞAGİRDLƏR CƏDVƏLİ
CREATE TABLE IF NOT EXISTS assessment.students (
    student_id SERIAL PRIMARY KEY,
    student_code VARCHAR(50) UNIQUE NOT NULL, -- Unikal kod (məs: "S2024-001")
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level INTEGER, -- Sinif (4-cü sinif = 4)
    school_name VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. İMTAHAN SESSİYALARI
CREATE TABLE IF NOT EXISTS assessment.test_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(200) NOT NULL,
    test_date DATE DEFAULT CURRENT_DATE,
    grade_level INTEGER,
    text_sample_ids INTEGER[], -- Hansı mətnlər
    total_questions INTEGER,
    total_possible_score INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. ŞAGİRD İMTAHAN NƏTİCƏLƏRİ (ƏSAS)
CREATE TABLE IF NOT EXISTS assessment.student_test_results (
    result_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES assessment.students(student_id),
    session_id INTEGER REFERENCES assessment.test_sessions(session_id),
    
    -- Sual növləri üzrə ballar
    mc_score INTEGER DEFAULT 0, -- Multiple choice (qapalı)
    mc_total INTEGER DEFAULT 0,
    open_score NUMERIC(5,1) DEFAULT 0, -- Açıq cavab
    open_total INTEGER DEFAULT 0,
    
    -- Ümumi
    total_score NUMERIC(5,1),
    total_possible INTEGER,
    percentage NUMERIC(5,2),
    
    -- Vaxt
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    
    -- Status
    is_completed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_student_session UNIQUE(student_id, session_id)
);

-- 4. SUAL-CAVAB DETALLARI
CREATE TABLE IF NOT EXISTS assessment.student_answers (
    answer_id SERIAL PRIMARY KEY,
    result_id INTEGER REFERENCES assessment.student_test_results(result_id),
    question_id INTEGER REFERENCES assessment.questions(question_id),
    
    -- Cavab
    student_answer TEXT, -- Şagirdin cavabı
    correct_answer TEXT, -- Düzgün cavab (MC üçün)
    
    -- Qiymətləndirmə
    is_correct BOOLEAN, -- MC üçün
    score_received NUMERIC(5,1), -- Alınan bal
    max_score INTEGER, -- Maksimum bal
    
    -- AI Qiymətləndirmə (açıq cavab üçün)
    ai_feedback TEXT, -- AI-nin izahı
    rubric_level VARCHAR(50), -- "excellent", "good", "partial", "poor"
    
    -- Vaxt
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. AI QİYMƏTLƏNDİRMƏ LOQU
CREATE TABLE IF NOT EXISTS assessment.ai_grading_log (
    log_id SERIAL PRIMARY KEY,
    answer_id INTEGER REFERENCES assessment.student_answers(answer_id),
    
    -- AI məlumatı
    ai_model VARCHAR(100), -- "claude-sonnet-4"
    prompt_tokens INTEGER,
    response_tokens INTEGER,
    
    -- Qiymətləndirmə
    ai_score NUMERIC(5,1),
    ai_reasoning TEXT, -- Niyə bu balı verdi?
    confidence_score NUMERIC(3,2), -- 0.00-1.00 (AI nə qədər əmin?)
    
    -- Vaxt
    graded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ═══════════════════════════════════════════════════════════
-- İNDEKSLƏR (Sürət üçün)
-- ═══════════════════════════════════════════════════════════

CREATE INDEX idx_student_results_student ON assessment.student_test_results(student_id);
CREATE INDEX idx_student_results_session ON assessment.student_test_results(session_id);
CREATE INDEX idx_answers_result ON assessment.student_answers(result_id);
CREATE INDEX idx_answers_question ON assessment.student_answers(question_id);
CREATE INDEX idx_ai_log_answer ON assessment.ai_grading_log(answer_id);

-- ═══════════════════════════════════════════════════════════
-- VİEW: NƏTİCƏ XÜLASƏSI
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW assessment.vw_test_results_summary AS
SELECT 
    str.result_id,
    s.student_code,
    s.first_name || ' ' || s.last_name AS student_name,
    ts.session_name,
    ts.test_date,
    
    -- Ballar
    str.mc_score AS qapalı_bal,
    str.mc_total AS qapalı_maksimum,
    str.open_score AS açıq_bal,
    str.open_total AS açıq_maksimum,
    str.total_score AS ümumi_bal,
    str.total_possible AS maksimum_bal,
    str.percentage AS faiz,
    
    -- Vaxt
    str.duration_minutes AS müddət_dəqiqə,
    str.created_at AS tarix,
    
    -- Status
    CASE 
        WHEN str.percentage >= 90 THEN 'Əla (A)'
        WHEN str.percentage >= 80 THEN 'Yaxşı (B)'
        WHEN str.percentage >= 70 THEN 'Kafi (C)'
        WHEN str.percentage >= 60 THEN 'Qənaətbəxş (D)'
        ELSE 'Zəif (F)'
    END AS qiymət
    
FROM assessment.student_test_results str
JOIN assessment.students s ON str.student_id = s.student_id
JOIN assessment.test_sessions ts ON str.session_id = ts.session_id;

-- ═══════════════════════════════════════════════════════════
-- TEST DATA
-- ═══════════════════════════════════════════════════════════

-- Şagird əlavə et
INSERT INTO assessment.students (student_code, first_name, last_name, grade_level, school_name)
VALUES 
('S2024-001', 'Ayşən', 'Məmmədova', 4, '23 nömrəli məktəb'),
('S2024-002', 'Elvin', 'Həsənov', 4, '23 nömrəli məktəb')
ON CONFLICT (student_code) DO NOTHING;

-- Test sessiyası yarat
INSERT INTO assessment.test_sessions (session_name, grade_level, total_questions, total_possible_score)
VALUES ('PIRLS 2026 Sınaq Test - Yanvar 2026', 4, 18, 36)
ON CONFLICT DO NOTHING;
