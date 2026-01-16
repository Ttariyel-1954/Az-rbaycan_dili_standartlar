-- Dublikatları təmizləyirik
SET search_path TO reading_literacy;

-- Bütün cədvəlləri təmizləyirik
TRUNCATE TABLE assessment_tasks CASCADE;
TRUNCATE TABLE text_analysis CASCADE;
TRUNCATE TABLE text_samples CASCADE;
TRUNCATE TABLE standard_framework_mapping CASCADE;
TRUNCATE TABLE curriculum_standards CASCADE;
TRUNCATE TABLE reading_aspects CASCADE;
TRUNCATE TABLE text_types CASCADE;
TRUNCATE TABLE frameworks CASCADE;
TRUNCATE TABLE grades CASCADE;

-- Sequence-ləri sıfırlayırıq
ALTER SEQUENCE grades_grade_id_seq RESTART WITH 1;
ALTER SEQUENCE frameworks_framework_id_seq RESTART WITH 1;
ALTER SEQUENCE reading_aspects_aspect_id_seq RESTART WITH 1;
ALTER SEQUENCE text_types_text_type_id_seq RESTART WITH 1;
ALTER SEQUENCE curriculum_standards_standard_id_seq RESTART WITH 1;
ALTER SEQUENCE text_samples_sample_id_seq RESTART WITH 1;
ALTER SEQUENCE text_analysis_analysis_id_seq RESTART WITH 1;
ALTER SEQUENCE assessment_tasks_task_id_seq RESTART WITH 1;
ALTER SEQUENCE standard_framework_mapping_mapping_id_seq RESTART WITH 1;

SELECT 'Baza təmizləndi, hazırdır yenidən yükləməyə!' as status;
