-- ═══════════════════════════════════════════════════════════
-- PIRLS 2026 STANDARTLARI VƏ METADATA
-- PIRLS Standards and Documentation Database Structure
-- ═══════════════════════════════════════════════════════════

-- 1. PIRLS Documentation table yaradırıq
CREATE TABLE IF NOT EXISTS reading_literacy.pirls_documentation (
    doc_id SERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    title_az TEXT NOT NULL,
    title_en TEXT,
    content_az TEXT NOT NULL,
    content_en TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. PIRLS Reading Processes (Oxu Prosesləri)
CREATE TABLE IF NOT EXISTS reading_literacy.pirls_reading_processes (
    process_id SERIAL PRIMARY KEY,
    process_code VARCHAR(50) UNIQUE NOT NULL,
    name_az VARCHAR(200) NOT NULL,
    name_en VARCHAR(200),
    description_az TEXT,
    description_en TEXT,
    difficulty_level INTEGER, -- 1=asan, 2=orta, 3=çətin, 4=çox çətin
    typical_question_types TEXT[], -- ['multiple_choice', 'constructed_response']
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ═══════════════════════════════════════════════════════════
-- DATA INSERTION
-- ═══════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────
-- 1. MƏTN NÖVLƏRİ (Text Types)
-- ───────────────────────────────────────────────────────────

INSERT INTO reading_literacy.pirls_documentation 
(category, subcategory, title_az, title_en, content_az, content_en, sort_order)
VALUES
(
    'text_types',
    'literary',
    'Ədəbi Mətn (Literary Text)',
    'Literary Text',
    'Süjetli, hekayə, realist və ya mədəni bədii tipli mətnlər.

Xüsusiyyətləri:
• Şagirdin oxuduğunu başa düşmə bacarığını ölçür
• Duyğu və qəhrəmanlar arasındakı əlaqələri tutma bacarığı
• Material dialoqlar, təsvirlər və hadisələr ardıcıllığı ilə təqdim olunur
• Süjet inkişafı və xarakter təhlili tələb edir
• Emosional və estetik cavab tələb edə bilər

Mətn elementləri:
• Dialoqlar və monoloqlar
• Təsviri detallar
• Hadisələr ardıcıllığı
• Qəhrəman inkişafı
• Süjet strukturu (giriş, inkişaf, kulminasiya, həll)

PIRLS paylanması: 50% ədəbi mətn',
    'Narrative, story-based, realistic or cultural literary texts.

Features:
• Measures student comprehension
• Tests understanding of emotions and character relationships
• Includes dialogues, descriptions, and sequence of events
• Requires plot development and character analysis
• May require emotional and aesthetic response

Text elements:
• Dialogues and monologues
• Descriptive details
• Sequence of events
• Character development
• Plot structure (exposition, rising action, climax, resolution)

PIRLS distribution: 50% literary text',
    1
),
(
    'text_types',
    'informational',
    'İnformasiya Mətn (Informational Text)',
    'Informational Text',
    'Faktlar, izahatlar, bələdçi məqalələr, elmi-ictimai mövzular.

Xüsusiyyətləri:
• Məlumatı anlama, müqayisə etmə və istifadə etmə bacarıqlarını ölçür
• Mətnlərdə cədvəl, sxem, diaqram və başlıqlar olur (rich text features)
• Faktual məlumat və obyektiv izahat
• Struktur və təşkil prinsipləri

Rich Text Features (Zəngin Mətn Elementləri):
• Cədvəllər və qrafiklər
• Diaqramlar və sxemlər
• İnfoqrafika
• Başlıqlar və alt başlıqlar
• Sadalanmış və nömrələnmiş siyahılar
• Qalın və kursiv mətn
• Alt yazılar və izahlar

Mətn tipləri:
• Elmi məqalələr (sadələşdirilmiş)
• Bələdçi və təlimat mətnləri
• Təbii hadisələr haqqında izahatlar
• İctimai və tarixi mövzular
• Texniki təsvirlər

PIRLS paylanması: 50% informasiya mətn',
    'Facts, explanations, guide articles, scientific-social topics.

Features:
• Measures information comprehension, comparison, and application skills
• Texts include tables, diagrams, charts, and headings (rich text features)
• Factual information and objective explanation
• Structural and organizational principles

Rich Text Features:
• Tables and graphs
• Diagrams and schemes
• Infographics
• Headings and subheadings
• Bulleted and numbered lists
• Bold and italic text
• Captions and annotations

Text types:
• Scientific articles (simplified)
• Guide and instruction texts
• Explanations about natural phenomena
• Social and historical topics
• Technical descriptions

PIRLS distribution: 50% informational text',
    2
);

-- ───────────────────────────────────────────────────────────
-- 2. SUAL TİPLƏRİ (Question Types)
-- ───────────────────────────────────────────────────────────

INSERT INTO reading_literacy.pirls_documentation 
(category, subcategory, title_az, title_en, content_az, content_en, sort_order)
VALUES
(
    'question_types',
    'multiple_choice',
    'Multiple-Choice (Çoxseçimli Suallar)',
    'Multiple-Choice Questions',
    'Bir düzgün cavab variantı seçilir.

Xüsusiyyətləri:
• Cavablar A, B, C, D şəklində təqdim olunur
• Sadə məlumatı tapmaq üçün istifadə olunur
• Bəzi inferensial bacarıqları ölçməkdə geniş tətbiq edilir
• Sürətli qiymətləndirmə mümkündür
• Obyektiv qiymətləndirmə

İstifadə sahələri:
• Literal anlayış (faktları tanıma)
• Məlumat axtarışı
• Sadə nəticə çıxarma
• Cavab seçimi və müqayisə

Üstünlükləri:
• Tez yoxlanılır
• Obyektiv qiymətləndirmə
• Geniş məzmun əhatəsi
• Statistik analiz asandır

Məhdudiyyətlər:
• Dərin düşüncəni tam ölçə bilməz
• Təsadüfi düzgün cavab ehtimalı
• Yazı bacarığını ölçmür',
    'One correct answer option is selected.

Features:
• Answers presented as A, B, C, D
• Used for finding simple information
• Widely applied for measuring some inferential skills
• Rapid assessment possible
• Objective evaluation

Usage areas:
• Literal comprehension (recognizing facts)
• Information retrieval
• Simple inference
• Answer selection and comparison

Advantages:
• Quick to check
• Objective assessment
• Wide content coverage
• Easy statistical analysis

Limitations:
• Cannot fully measure deep thinking
• Possibility of random correct answer
• Does not measure writing skills',
    3
),
(
    'question_types',
    'constructed_response',
    'Constructed Response (Açıq Cavab Sualları)',
    'Constructed Response Questions',
    'Şagird mətndən çıxışla cavabı öz sözləri ilə yazır.

Xüsusiyyətləri:
• Rubrik əsasında qiymətləndirilir (adətən 1-3 bal)
• İnferensiya, qiymətləndirmə və mətni dil/struktur baxımından anlama bacarıqlarını ölçür
• Şagird öz fikirlərini ifadə etməlidir
• Mətn əsaslı sübutlar tələb olunur

Cavab növləri:
• Qısa cavab (1-2 cümlə)
• Orta cavab (3-5 cümlə)
• Uzun cavab (paraqraf)

Ölçülən bacarıqlar:
• Mətndəki fikir arasında əlaqə göstərmə
• Mətn sübutundan istifadə edərək əsaslandırma
• Xülasə və nəticə çıxarışı yazma
• Tənqidi düşüncə
• Yazı bacarığı

Qiymətləndirmə rubrikləri:
• 0 bal: Cavab yoxdur və ya tamamilə yanlışdır
• 1 bal: Qismən düzgün, ancaq natamam
• 2 bal: Əsasən düzgün, kiçik səhvlərlə
• 3 bal: Tam və düzgün cavab, yaxşı əsaslandırılmış

Üstünlükləri:
• Dərin düşüncəni ölçür
• Yazı bacarığını qiymətləndirir
• Məntiq və əsaslandırma bacarıqları
• Yaradıcı cavablara imkan

Məhdudiyyətlər:
• Yoxlanılması çətin və zaman aparır
• Subyektiv qiymətləndirmə riski
• Az məzmun əhatəsi',
    'Student writes answer in own words based on text.

Features:
• Evaluated based on rubric (typically 1-3 points)
• Measures inference, evaluation, and language/structure comprehension
• Student must express own thoughts
• Text-based evidence required

Answer types:
• Short answer (1-2 sentences)
• Medium answer (3-5 sentences)
• Extended answer (paragraph)

Skills measured:
• Showing connections between ideas in text
• Justifying using text evidence
• Writing summary and conclusions
• Critical thinking
• Writing skills

Assessment rubrics:
• 0 points: No answer or completely incorrect
• 1 point: Partially correct but incomplete
• 2 points: Mostly correct with minor errors
• 3 points: Complete and correct answer, well-justified

Advantages:
• Measures deep thinking
• Assesses writing skills
• Logic and reasoning abilities
• Allows creative responses

Limitations:
• Difficult and time-consuming to check
• Risk of subjective evaluation
• Limited content coverage',
    4
);

-- ───────────────────────────────────────────────────────────
-- 3. OXU PROSESLƏRİ (Reading Processes)
-- ───────────────────────────────────────────────────────────

INSERT INTO reading_literacy.pirls_reading_processes
(process_code, name_az, name_en, description_az, description_en, difficulty_level, typical_question_types, sort_order)
VALUES
(
    'focus_retrieve',
    'Fokus və açıq şəkildə verilən məlumatı tapma',
    'Focus on and retrieve explicitly stated information',
    'Literal anlayış - mətndə birbaşa verilmiş məlumatın tapılması.

Bacarıqlar:
• Kim, nə, harada, nə zaman kimi sualların cavabını tapmaq
• Mətn elementlərini tanımaq
• Faktları xatırlamaq
• Birbaşa ifadələri tapmaq

Nümunə suallar:
• "Hekayə harada baş verir?"
• "Əsas qəhrəman kimdir?"
• "Hadisə nə zaman baş verdi?"
• "Mətnə görə, nə baş verdi?"

Çətinlik: Ən asan səviyyə
Ən çox istifadə olunan sual tipi: Multiple-choice',
    'Literal comprehension - finding directly stated information in text.

Skills:
• Finding answers to who, what, where, when questions
• Recognizing text elements
• Recalling facts
• Locating explicit statements

Example questions:
• "Where does the story take place?"
• "Who is the main character?"
• "When did the event occur?"
• "According to the text, what happened?"

Difficulty: Easiest level
Most common question type: Multiple-choice',
    1,
    ARRAY['multiple_choice'],
    1
),
(
    'make_inferences',
    'Sadə nəticə çıxarma (Inferential)',
    'Make straightforward inferences',
    'Mətndə açıq-aşkar yazılmayan, lakin məntiqən anlaşılan məlumatı çıxarmaq.

Bacarıqlar:
• Səbəb-nəticə əlaqəsi qurmaq
• "Niyə?" sualına cavab tapmaq
• Qəhrəmanın hərəkətlərinin səbəblərini anlamaq
• Kontekstdən məna çıxarmaq
• İki və ya daha çox məlumatı əlaqələndirmək

Nümunə suallar:
• "Niyə qəhrəman belə davrandı?"
• "Bu hadisənin səbəbi nə idi?"
• "Nəticədə nə baş verdi?"
• "Qəhrəman necə hiss etdi?"

Çətinlik: Orta səviyyə
İstifadə olunan sual tipləri: Multiple-choice və Constructed Response',
    'Drawing information that is not explicitly stated but logically understood.

Skills:
• Establishing cause-effect relationships
• Finding answers to "why?" questions
• Understanding reasons for character actions
• Deriving meaning from context
• Connecting two or more pieces of information

Example questions:
• "Why did the character act this way?"
• "What caused this event?"
• "What happened as a result?"
• "How did the character feel?"

Difficulty: Medium level
Question types used: Multiple-choice and Constructed Response',
    2,
    ARRAY['multiple_choice', 'constructed_response'],
    2
),
(
    'interpret_integrate',
    'Məlumat və ideyaları birləşdirmə və şərh etmə',
    'Interpret and integrate ideas and information',
    'Müxtəlif mətn hissələrini tutma və əlaqələndirmə, dərin məna çıxarma.

Bacarıqlar:
• Mətnin müxtəlif hissələrindən məlumat birləşdirmək
• Ümumiləşdirmə etmək
• Əlaqələr və nümunələr görmək
• Mətnin əsas ideyasını müəyyənləşdirmək
• Müqayisə və qarşılaşdırma
• Nəticə çıxarma

Nümunə suallar:
• "Mətnin əsas fikri nədir?"
• "Bu iki hadisə arasında hansı əlaqə var?"
• "Müəllif hansı mesajı vermək istəyir?"
• "Mətn necə təşkil olunub?"

Çətinlik: Çətin səviyyə
Çox vaxt Constructed Response tələb edir',
    'Grasping and connecting different text parts, deriving deep meaning.

Skills:
• Combining information from different text parts
• Making generalizations
• Seeing connections and patterns
• Identifying main idea of text
• Comparing and contrasting
• Drawing conclusions

Example questions:
• "What is the main idea of the text?"
• "What connection exists between these two events?"
• "What message does the author want to convey?"
• "How is the text organized?"

Difficulty: Difficult level
Often requires Constructed Response',
    3,
    ARRAY['constructed_response', 'multiple_choice'],
    3
),
(
    'examine_evaluate',
    'Məzmun və mətn elementlərini qiymətləndirmə',
    'Examine and evaluate content, language, and textual elements',
    'Mətni tənqidi oxuma və qiymətləndirmə, müəllif niyyətini anlama.

Bacarıqlar:
• Mətni tənqidi qiymətləndirmə
• Müəllif niyyətini anlama və əsaslandırma
• Mətnin effektivliyini qiymətləndirmə
• Dil və üslub seçimlərini təhlil etmə
• Mətn strukturunun təsirini anlamaq
• Sübutların etibarlılığını qiymətləndirmə

Nümunə suallar:
• "Müəllif niyə bu üslubu seçib?"
• "Bu mətn məqsədinə çatıbmı?"
• "Hansı dil vasitələri istifadə olunub?"
• "Mətn nə dərəcədə inandırıcıdır?"
• "Alternativ başlıq nə ola bilərdi?"

Çətinlik: Ən çətin səviyyə
Əsasən Constructed Response ilə ölçülür',
    'Critical reading and evaluation of text, understanding author intent.

Skills:
• Critical evaluation of text
• Understanding and justifying author intent
• Assessing text effectiveness
• Analyzing language and style choices
• Understanding impact of text structure
• Evaluating reliability of evidence

Example questions:
• "Why did the author choose this style?"
• "Did this text achieve its purpose?"
• "What language devices were used?"
• "How convincing is the text?"
• "What could be an alternative title?"

Difficulty: Most difficult level
Mainly measured through Constructed Response',
    4,
    ARRAY['constructed_response'],
    4
);

-- ───────────────────────────────────────────────────────────
-- 4. TEST STRUKTURU
-- ───────────────────────────────────────────────────────────

INSERT INTO reading_literacy.pirls_documentation 
(category, title_az, title_en, content_az, content_en, sort_order)
VALUES
(
    'test_structure',
    'PIRLS 2026 Test Strukturu',
    'PIRLS 2026 Test Structure',
    'Test strukturu və təşkili prinsipləri:

MƏTN SAYı VƏ PAYLANMA:
• Toplam 18 mətn
• Matrix sampling (matris seçmə) üsulu ilə kitabçalara paylanır
• Hər şagird 2 mətn cavablandırır:
  - 1 ədəbi mətn (literary)
  - 1 informasiya mətni (informational)
• Balanslaşdırılmış obyektiv və yazılı cavab tapşırıqları

MƏTN XÜSUSİYYƏTLƏRİ:
• Mətn uzunluğu: təxminən 500-900 söz
• Çarpaz mədəni uyğunlaşdırılmış
• Fərqli çətinlik səviyyələri
• 4-cü sinif səviyyəsinə uyğun

SUAL PAYLANMASI:
• Hər mətn üçün ortalama 12-15 sual
• Multiple-choice (çoxseçimli)
• Constructed response (açıq cavab)
• Literal, inferential, interpretive və evaluative prosesləri ölçür

QIYMƏTLƏNDIRMƏ YANAŞMASI:
• Çoxseçimli suallar: 1 bal
• Açıq cavab sualları: 1-3 bal (rubrik əsasında)
• Ümumi test müddəti: təxminən 80 dəqiqə (hər mətn üçün 40 dəqiqə)

YENİLİKLƏR 2026:
• Kompüter əsaslı (digitalPIRLS) format
• ePIRLS (onlayn oxu) tapşırıqları
• Bəzi açıq cavabların süni intellekt ilə yoxlanması sınaqdan keçiriləcək
• Adaptiv test elementləri',
    'Test structure and organization principles:

TEXT COUNT AND DISTRIBUTION:
• Total 18 texts
• Distributed to booklets using matrix sampling method
• Each student answers 2 texts:
  - 1 literary text
  - 1 informational text
• Balanced objective and written response tasks

TEXT CHARACTERISTICS:
• Text length: approximately 500-900 words
• Cross-culturally adapted
• Different difficulty levels
• Appropriate for grade 4 level

QUESTION DISTRIBUTION:
• Average 12-15 questions per text
• Multiple-choice
• Constructed response
• Measures literal, inferential, interpretive and evaluative processes

ASSESSMENT APPROACH:
• Multiple-choice questions: 1 point
• Constructed response questions: 1-3 points (rubric-based)
• Total test duration: approximately 80 minutes (40 minutes per text)

INNOVATIONS 2026:
• Computer-based (digitalPIRLS) format
• ePIRLS (online reading) tasks
• AI-assisted scoring of some constructed responses being piloted
• Adaptive test elements',
    5
);

-- ───────────────────────────────────────────────────────────
-- 5. KOGNİTİV SƏVIYYƏLƏR VƏ BAL PAYLANMASI
-- ───────────────────────────────────────────────────────────

INSERT INTO reading_literacy.pirls_documentation 
(category, title_az, title_en, content_az, content_en, sort_order)
VALUES
(
    'cognitive_distribution',
    'Kognitiv Proses Paylanması və Qiymətləndirmə',
    'Cognitive Process Distribution and Assessment',
    'PIRLS 2026 oxu proseslərinin paylanması və qiymətləndirmə prinsipləri:

OXU PROSES PAYLANMASI (Təxmini):
1. Focus and Retrieve (Literal): 20-25%
   - Ən sadə səviyyə
   - Mətn faktlarını tapma
   - Əsasən multiple-choice

2. Make Inferences: 30-35%
   - Orta çətinlik
   - Səbəb-nəticə əlaqələri
   - MC və açıq cavab qarışıq

3. Interpret and Integrate: 25-30%
   - Çətin səviyyə
   - Məlumat birləşdirmə
   - Əsasən açıq cavab

4. Examine and Evaluate: 15-20%
   - Ən çətin səviyyə
   - Tənqidi qiymətləndirmə
   - Açıq cavab

SUAL TİPİ PAYLANMASI:
• Multiple-choice: 50-55%
• Constructed response (açıq): 45-50%

BAL PAYLANMASI:
Multiple-choice suallar:
• 1 bal (düzgün/səhv)

Constructed response (rubrik əsasında):
• 1 bal: Qısa, sadə cavab
  - Bir detalı düzgün göstərmək
  - Məhdud izahat

• 2 bal: Orta cavab
  - İki və ya daha çox detal
  - Qismən əsaslandırma
  - Mətn sübutu ilə dəstək

• 3 bal: Tam cavab
  - Bütün tələb olunan elementlər
  - Tam əsaslandırma
  - Mətn sübutu ilə güclü dəstək
  - Aydın və məntiqi struktur

QİYMƏTLƏNDİRMƏ PRİNSİPLƏRİ:
• Mətn əsaslı cavablar
• Sübutlarla dəstəklənmə
• Aydın və məntiqi ifadə
• Tam və dəqiq cavab',
    'PIRLS 2026 reading process distribution and assessment principles:

READING PROCESS DISTRIBUTION (Approximate):
1. Focus and Retrieve (Literal): 20-25%
   - Easiest level
   - Finding text facts
   - Mainly multiple-choice

2. Make Inferences: 30-35%
   - Medium difficulty
   - Cause-effect relationships
   - Mixed MC and constructed response

3. Interpret and Integrate: 25-30%
   - Difficult level
   - Information integration
   - Mainly constructed response

4. Examine and Evaluate: 15-20%
   - Most difficult level
   - Critical evaluation
   - Constructed response

QUESTION TYPE DISTRIBUTION:
• Multiple-choice: 50-55%
• Constructed response: 45-50%

SCORING DISTRIBUTION:
Multiple-choice questions:
• 1 point (correct/incorrect)

Constructed response (rubric-based):
• 1 point: Short, simple answer
  - Correctly showing one detail
  - Limited explanation

• 2 points: Medium answer
  - Two or more details
  - Partial justification
  - Support with text evidence

• 3 points: Complete answer
  - All required elements
  - Full justification
  - Strong support with text evidence
  - Clear and logical structure

ASSESSMENT PRINCIPLES:
• Text-based answers
• Support with evidence
• Clear and logical expression
• Complete and accurate answer',
    6
);

-- ═══════════════════════════════════════════════════════════
-- İNDEKSLƏR
-- ═══════════════════════════════════════════════════════════

CREATE INDEX idx_pirls_doc_category ON reading_literacy.pirls_documentation(category);
CREATE INDEX idx_pirls_doc_active ON reading_literacy.pirls_documentation(is_active);
CREATE INDEX idx_pirls_process_code ON reading_literacy.pirls_reading_processes(process_code);

-- ═══════════════════════════════════════════════════════════
-- UPDATED TIMESTAMP TRIGGER
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION reading_literacy.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pirls_doc_update_timestamp
BEFORE UPDATE ON reading_literacy.pirls_documentation
FOR EACH ROW
EXECUTE FUNCTION reading_literacy.update_timestamp();

-- ═══════════════════════════════════════════════════════════
-- VERİFİKASİYA QUERIES
-- ═══════════════════════════════════════════════════════════

-- Bütün mətn növləri
SELECT * FROM reading_literacy.pirls_documentation 
WHERE category = 'text_types' ORDER BY sort_order;

-- Bütün sual tipləri
SELECT * FROM reading_literacy.pirls_documentation 
WHERE category = 'question_types' ORDER BY sort_order;

-- Bütün oxu prosesləri
SELECT * FROM reading_literacy.pirls_reading_processes 
ORDER BY sort_order;

-- Test strukturu
SELECT * FROM reading_literacy.pirls_documentation 
WHERE category = 'test_structure';

-- Statistika
SELECT 
    category,
    COUNT(*) as entry_count
FROM reading_literacy.pirls_documentation
GROUP BY category
ORDER BY category;
