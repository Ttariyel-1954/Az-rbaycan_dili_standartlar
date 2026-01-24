-- ═══════════════════════════════════════════════════════════
-- KÖHNƏ STRUKTURU TƏMİZLƏ VƏ YENİDƏN YARAT
-- ═══════════════════════════════════════════════════════════

-- 1. Köhnə cədvəlləri sil
DROP TABLE IF EXISTS assessment.ai_grading_log CASCADE;
DROP TABLE IF EXISTS assessment.student_answers CASCADE;
DROP TABLE IF EXISTS assessment.student_test_results CASCADE;
DROP TABLE IF EXISTS assessment.test_sessions CASCADE;
DROP TABLE IF EXISTS assessment.students CASCADE;

-- View-ları sil
DROP VIEW IF EXISTS assessment.vw_test_results_summary CASCADE;

-- 2. Yenidən yarat

-- STUDENTS
CREATE TABLE assessment.students (
    student_id SERIAL PRIMARY KEY,
    student_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level INTEGER,
    school_name VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TEST SESSIONS
CREATE TABLE assessment.test_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(200) NOT NULL,
    test_date DATE DEFAULT CURRENT_DATE,
    grade_level INTEGER,
    text_sample_ids INTEGER[],
    total_questions INTEGER,
    total_possible_score INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STUDENT TEST RESULTS
CREATE TABLE assessment.student_test_results (
    result_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES assessment.students(student_id),
    session_id INTEGER REFERENCES assessment.test_sessions(session_id),
    
    mc_score INTEGER DEFAULT 0,
    mc_total INTEGER DEFAULT 0,
    open_score NUMERIC(5,1) DEFAULT 0,
    open_total INTEGER DEFAULT 0,
    
    total_score NUMERIC(5,1),
    total_possible INTEGER,
    percentage NUMERIC(5,2),
    
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    
    is_completed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_student_session UNIQUE(student_id, session_id)
);

-- STUDENT ANSWERS
CREATE TABLE assessment.student_answers (
    answer_id SERIAL PRIMARY KEY,
    result_id INTEGER REFERENCES assessment.student_test_results(result_id),
    question_id INTEGER REFERENCES assessment.questions(question_id),
    
    student_answer TEXT,
    correct_answer TEXT,
    
    is_correct BOOLEAN,
    score_received NUMERIC(5,1),
    max_score INTEGER,
    
    ai_feedback TEXT,
    rubric_level VARCHAR(50),
    
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI GRADING LOG
CREATE TABLE assessment.ai_grading_log (
    log_id SERIAL PRIMARY KEY,
    answer_id INTEGER REFERENCES assessment.student_answers(answer_id),
    
    ai_model VARCHAR(100),
    prompt_tokens INTEGER,
    response_tokens INTEGER,
    
    ai_score NUMERIC(5,1),
    ai_reasoning TEXT,
    confidence_score NUMERIC(3,2),
    
    graded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. İndekslər
CREATE INDEX idx_student_results_student ON assessment.student_test_results(student_id);
CREATE INDEX idx_student_results_session ON assessment.student_test_results(session_id);
CREATE INDEX idx_answers_result ON assessment.student_answers(result_id);
CREATE INDEX idx_answers_question ON assessment.student_answers(question_id);
CREATE INDEX idx_ai_log_answer ON assessment.ai_grading_log(answer_id);

-- 4. View
CREATE VIEW assessment.vw_test_results_summary AS
SELECT 
    str.result_id,
    s.student_code,
    s.first_name || ' ' || s.last_name AS student_name,
    ts.session_name,
    ts.test_date,
    
    str.mc_score AS qapalı_bal,
    str.mc_total AS qapalı_maksimum,
    str.open_score AS açıq_bal,
    str.open_total AS açıq_maksimum,
    str.total_score AS ümumi_bal,
    str.total_possible AS maksimum_bal,
    str.percentage AS faiz,
    
    str.duration_minutes AS müddət_dəqiqə,
    str.created_at AS tarix,
    
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

-- 5. Test data
INSERT INTO assessment.students (student_code, first_name, last_name, grade_level, school_name)
VALUES 
('S2024-001', 'Ayşən', 'Məmmədova', 4, '23 nömrəli məktəb'),
('S2024-002', 'Elvin', 'Həsənov', 4, '23 nömrəli məktəb');

INSERT INTO assessment.test_sessions (session_name, grade_level, total_questions, total_possible_score, text_sample_ids)
VALUES ('PIRLS 2026 Sınaq Test - Yanvar 2026', 4, 18, 36, ARRAY[228]);

-- Uğurlu!
SELECT 'Baza hazırdır! ✓' AS status;
