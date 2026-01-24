-- İnternet Mətni və Sualları

-- 1. MƏTN
INSERT INTO reading_literacy.text_samples 
(title_az, content_az, text_type_id, word_count, grade_id, pirls_2026_compliant)
VALUES
(
'İnternet: Virtual Dünyaya Pəncərə',
'# İnternet: Virtual Dünyaya Pəncərə

İnternet – bu, dünya üzrə milyonlarla kompüterin bir-birinə bağlandığı böyük bir şəbəkədir. Təsəvvür edin ki, siz öz evinizin pəncərəsindən bütün dünyanı görə bilirsiniz. İnternet də elə belə bir "pəncərə"dir, ancaq bu pəncərədən siz yalnız görmür, həm də danışır, öyrənir və əylənirsıniz.

## İnternetin Tarixi

1960-cı illərdə Amerika alimləri kompüterləri bir-birinə bağlamağın yolunu tapdılar. O zaman yalnız dörd kompüter bu şəbəkəyə qoşulmuşdu. Bu, internetin ilk addımı idi. Zaman keçdikcə daha çox kompüter şəbəkəyə qoşuldu. 1990-cı illərdə isə "World Wide Web" (Ümumdünya Şəbəkəsi) yarandı və internet hamının istifadə edə biləcəyi şəkildə inkişaf etdi.

Bu gün dünyada 5 milyarddan çox insan internetdən istifadə edir. Bu, dünyanın əhalisinin təxminən yarısıdır! Azərbaycanda da 8 milyon nəfərdən çoxu internetə çıxış imkanına malikdir.

## İnternet Necə İşləyir?

İnternet kabellər və peyklər vasitəsilə işləyir. Evinizdəki kompüter və ya telefon xüsusi kabellə internetə qoşulur. Məlumat bu kabellərdən çox sürətlə ötürülür. Bəzən məlumat yeraltı kabellərə, bəzən də kosmosda yerləşən peyklərə göndərilir.

Məlumat paketlər şəklində göndərilir. Məsələn, siz videoya baxırsınızsa, video minlərlə kiçik paketə bölünür və bu paketlər ayrı-ayrılıqda sizə göndərilir. Sonra isə kompüteriniz bu paketləri yenidən birləşdirir və siz tam videounu görürsünüz.

İnternetin sürəti megabayt və ya qiqabaytla ölçülür. Sürətli internet nə qədər çox məlumatı tez ötürə bilirsə, o qədər yaxşıdır. Məsələn, 100 megabaytlıq internet 1 dəqiqədə böyük bir filmi yükləyə bilər.

## İnternetin Faydaları

İnternet bizə çoxlu imkanlar verir:

**Təhsil sahəsində:** İnternet vasitəsilə biz istənilən mövzuda məlumat tapa bilərik. Məktəbdə öyrəndiyimiz hər şeyi internetdə daha ətraflı araşdıra bilərik. Hətta online dərslərə qatıla və xaricdəki müəllimlərə sual verə bilərik.

**Ünsiyyət sahəsində:** İnternet vasitəsilə biz dünyanın istənilən nöqtəsindəki insanlarla danışa bilərik. Video zəng edib onları görə bilərik. Ailə üzvlərimiz uzaq şəhərdə olsa belə, hər gün onlarla əlaqə saxlaya bilərik.

**Əyləncə sahəsində:** İnternetdə maraqlı oyunlar oynaya, mahnı dinləyə, film və mult-filmlər izləyə bilərik. Həmçinin öz maraqlarımıza uyğun video və şəkillər tapa bilərik.

**Alış-veriş sahəsində:** İnternetdə mağazalar var. Orada istədiyimiz şeyi sifariş edib evə çatdıra bilərik. Valideynlərimiz ərzaq, geyim və digər əşyaları internetdən sifariş edirlər.

## İnternetin Təhlükələri

İnternet çox faydalı olsa da, bəzi təhlükələr də var:

**Şəxsi məlumatların oğurlanması:** Bəzi pis insanlar internetdə başqalarının şifrələrini və şəxsi məlumatlarını oğurlamağa çalışırlar. Ona görə də heç vaxt öz şifrəni tanımadığın adamlara verməməlisən.

**Saxta məlumat:** İnternetdə bütün məlumatlar doğru deyil. Bəzi saytlar yalan xəbərlər yayır. Məlumatın doğru olub-olmadığını yoxlamaq üçün bir neçə mənbəyə baxmaq lazımdır.

**Çox vaxt sərf etmək:** İnternetdə çox uzun müddət qalmaq gözlərə və əsəblərə zərər verir. Həmçinin fiziki hərəkətsizliyə səbəb olur. Ona görə də gündə 1-2 saatdan çox internetdə olmamalısan.

## Təhlükəsiz İnternet İstifadəsi

İnternetdən təhlükəsiz istifadə etmək üçün:

1. Heç vaxt tanımadığın adamlarla şəxsi məlumatlarını paylaşma
2. Valideynlərinin icazəsi olmadan heç bir proqram yükləmə
3. Şübhəli linkləri açma
4. Gündə müəyyən vaxt internetdə ol və fasilələr ver
5. Problemlə qarşılaşsan, dərhal böyüklərə xəbər ver

İnternet – müasir dünyanın vacib hissəsidir. O, dünyamızı kiçildir və bizi bir-birimizə yaxınlaşdırır. Amma internetdən düzgün və təhlükəsiz istifadə etmək çox vacibdir. Unutma ki, internet – alətdir və onu necə istifadə etməyimiz bizdən asılıdır!',
2,
750,
4,
true
);

-- 2. SUALLAR

-- QAPALI SUALLAR (10 ədd)

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    1,
    'İnternetin ilk versiyasında neçə kompüter bir-birinə bağlanmışdı?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "İki"},
        {"option": "B", "text": "Dörd"},
        {"option": "C", "text": "Altı"},
        {"option": "D", "text": "On"}
    ]'::jsonb,
    'B'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    2,
    'Mətnə görə, bu gün dünyada neçə milyarddan çox insan internetdən istifadə edir?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "3 milyarddan çox"},
        {"option": "B", "text": "4 milyarddan çox"},
        {"option": "C", "text": "5 milyarddan çox"},
        {"option": "D", "text": "6 milyarddan çox"}
    ]'::jsonb,
    'C'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    3,
    'İnternetdə məlumat necə göndərilir?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "Bütöv fayl şəklində"},
        {"option": "B", "text": "Paketlər şəklində"},
        {"option": "C", "text": "Şəkil şəklində"},
        {"option": "D", "text": "Səs şəklində"}
    ]'::jsonb,
    'B'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    4,
    'İnternetin sürəti nə ilə ölçülür?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "Kilometr və metr"},
        {"option": "B", "text": "Kiloqram və qram"},
        {"option": "C", "text": "Megabayt və qiqabayt"},
        {"option": "D", "text": "Litr və millilitr"}
    ]'::jsonb,
    'C'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    5,
    '100 megabaytlıq internet neçə dəqiqədə böyük bir filmi yükləyə bilər?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "30 saniyə"},
        {"option": "B", "text": "1 dəqiqə"},
        {"option": "C", "text": "5 dəqiqə"},
        {"option": "D", "text": "10 dəqiqə"}
    ]'::jsonb,
    'B'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    6,
    'İnternet vasitəsilə hansı sahədə məlumat tapa bilərik?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "Yalnız tarix sahəsində"},
        {"option": "B", "text": "Yalnız riyaziyyat sahəsində"},
        {"option": "C", "text": "Yalnız idman sahəsində"},
        {"option": "D", "text": "İstənilən mövzuda"}
    ]'::jsonb,
    'D'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    7,
    'Mətnə görə, internetdə ən böyük təhlükələrdən biri nədir?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "Elektrik enerjisinin tükənməsi"},
        {"option": "B", "text": "Şəxsi məlumatların oğurlanması"},
        {"option": "C", "text": "Kompüterin soyuması"},
        {"option": "D", "text": "Ekranın parlaması"}
    ]'::jsonb,
    'B'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    8,
    'İnternetdə gündə maksimum neçə saat qalmaq tövsiyə olunur?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "30 dəqiqə - 1 saat"},
        {"option": "B", "text": "1-2 saat"},
        {"option": "C", "text": "3-4 saat"},
        {"option": "D", "text": "5-6 saat"}
    ]'::jsonb,
    'B'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    9,
    '"World Wide Web" nə vaxt yaranmışdır?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "1960-cı illərdə"},
        {"option": "B", "text": "1970-ci illərdə"},
        {"option": "C", "text": "1980-ci illərdə"},
        {"option": "D", "text": "1990-cı illərdə"}
    ]'::jsonb,
    'D'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score, options, correct_answer)
SELECT 
    sample_id,
    10,
    'Təhlükəsiz internet istifadəsi üçün nə etməməlisən?',
    'multiple_choice',
    1,
    '[
        {"option": "A", "text": "Valideynlərdən soruşmalısan"},
        {"option": "B", "text": "Fasilələr verməlisən"},
        {"option": "C", "text": "Tanımadığınla məlumat paylaşmalısan"},
        {"option": "D", "text": "Şübhəli linkləri açmamalısan"}
    ]'::jsonb,
    'C'
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

-- AÇIQ SUALLAR (8 ədd)

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    11,
    'İnternetin 1960-cı illərdə yarandığı vaxtdan bu günə qədər necə dəyişdiyini öz sözlərinlə izah et.',
    'open_response',
    2
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    12,
    'Mətnə əsasən, internetin təhsil sahəsində verdiyi üç əsas faydanı yaz.',
    'open_response',
    3
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    13,
    'İnternetdə məlumatın paketlər şəklində göndərilməsi prosesini izah et. Video nümunəsindən istifadə edərək izah et.',
    'open_response',
    4
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    14,
    'Azərbaycanda neçə nəfər internetə çıxış imkanına malikdir? Mətnə əsasən cavab ver.',
    'open_response',
    2
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    15,
    'İnternetdə saxta məlumatla qarşılaşdıqda nə etməli? Öz fikirlərini də əlavə edərək 3-4 cümlə ilə cavab ver.',
    'open_response',
    4
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    16,
    'Müəllif niyə deyir ki, "internetdən çox vaxt sərf etmək" təhlükəlidir? Mətnə əsasən 2-3 səbəb göstər.',
    'open_response',
    3
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    17,
    'Mətnin "Təhlükəsiz İnternet İstifadəsi" bölməsində verilən 5 qayda içərisindən sənin fikrincə ən vacib 2-sini seç və niyə vacib olduğunu izah et.',
    'open_response',
    4
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, max_score)
SELECT 
    sample_id,
    18,
    'Müəllif internetin dünyamızı necə dəyişdirdiyini necə izah edir? Son abzasa əsaslanaraq öz fikirlərini də əlavə et.',
    'open_response',
    4
FROM reading_literacy.text_samples 
WHERE title_az = 'İnternet: Virtual Dünyaya Pəncərə';
