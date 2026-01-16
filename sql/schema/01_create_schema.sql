-- Azərbaycan dili standartları bazası
-- PISA/PIRLS/CEFR əsaslı oxu savadı sistemi

-- Əsas sxema
CREATE SCHEMA IF NOT EXISTS reading_literacy;

SET search_path TO reading_literacy;

-- 1. Sinif məlumatları
CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    grade_level INTEGER NOT NULL CHECK (grade_level BETWEEN 1 AND 9),
    grade_name_az VARCHAR(50),
    age_range VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Beynəlxalq framework-lər
CREATE TABLE frameworks (
    framework_id SERIAL PRIMARY KEY,
    framework_name VARCHAR(50) NOT NULL,
    framework_type VARCHAR(20),
    description_az TEXT,
    description_en TEXT,
    version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Oxu savadı aspektləri (PISA əsaslı)
CREATE TABLE reading_aspects (
    aspect_id SERIAL PRIMARY KEY,
    framework_id INTEGER REFERENCES frameworks(framework_id),
    aspect_code VARCHAR(20),
    aspect_name_az VARCHAR(200),
    aspect_name_en VARCHAR(200),
    aspect_type VARCHAR(50),
    description_az TEXT,
    parent_aspect_id INTEGER REFERENCES reading_aspects(aspect_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Milli kurikulum standartları
CREATE TABLE curriculum_standards (
    standard_id SERIAL PRIMARY KEY,
    grade_id INTEGER REFERENCES grades(grade_id),
    standard_code VARCHAR(50) UNIQUE,
    content_area VARCHAR(100),
    sub_area VARCHAR(100),
    standard_text_az TEXT NOT NULL,
    standard_text_en TEXT,
    performance_indicators TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Framework-ə uyğunlaşdırma
CREATE TABLE standard_framework_mapping (
    mapping_id SERIAL PRIMARY KEY,
    standard_id INTEGER REFERENCES curriculum_standards(standard_id),
    aspect_id INTEGER REFERENCES reading_aspects(aspect_id),
    alignment_strength VARCHAR(20),
    mapping_notes TEXT,
    mapped_by VARCHAR(100),
    mapped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Mətn növləri
CREATE TABLE text_types (
    text_type_id SERIAL PRIMARY KEY,
    type_name_az VARCHAR(100),
    type_name_en VARCHAR(100),
    category VARCHAR(50),
    description_az TEXT,
    examples TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Mətn nümunələri
CREATE TABLE text_samples (
    sample_id SERIAL PRIMARY KEY,
    grade_id INTEGER REFERENCES grades(grade_id),
    text_type_id INTEGER REFERENCES text_types(text_type_id),
    title_az VARCHAR(300),
    content_az TEXT NOT NULL,
    word_count INTEGER,
    complexity_level VARCHAR(20),
    source VARCHAR(200),
    themes TEXT[],
    cultural_context TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Mətn təhlili
CREATE TABLE text_analysis (
    analysis_id SERIAL PRIMARY KEY,
    sample_id INTEGER REFERENCES text_samples(sample_id),
    readability_score DECIMAL(5,2),
    lexical_diversity DECIMAL(5,2),
    sentence_complexity JSONB,
    key_vocabulary JSONB,
    pisa_alignment JSONB,
    pirls_alignment JSONB,
    ai_analysis TEXT,
    analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Tapşırıqlar
CREATE TABLE assessment_tasks (
    task_id SERIAL PRIMARY KEY,
    sample_id INTEGER REFERENCES text_samples(sample_id),
    aspect_id INTEGER REFERENCES reading_aspects(aspect_id),
    task_text_az TEXT NOT NULL,
    task_type VARCHAR(50),
    expected_response TEXT,
    scoring_rubric JSONB,
    difficulty_level VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- İndekslər
CREATE INDEX idx_standards_grade ON curriculum_standards(grade_id);
CREATE INDEX idx_standards_area ON curriculum_standards(content_area);
CREATE INDEX idx_samples_grade ON text_samples(grade_id);
CREATE INDEX idx_samples_type ON text_samples(text_type_id);
CREATE INDEX idx_mapping_standard ON standard_framework_mapping(standard_id);
CREATE INDEX idx_mapping_aspect ON standard_framework_mapping(aspect_id);

COMMENT ON SCHEMA reading_literacy IS 'Azərbaycan dili oxu savadı - PISA/PIRLS uyğunlaşdırma';
