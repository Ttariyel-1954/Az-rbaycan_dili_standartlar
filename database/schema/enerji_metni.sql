-- Enerji Mətni və Sualları

-- 1. MƏTN
INSERT INTO reading_literacy.text_samples 
(title_az, content_az, text_type_id, word_count, grade_id, pirls_2026_compliant)
VALUES
(
'Azərbaycanda Enerji Mənbələri',
'# Azərbaycanda Enerji Mənbələri

## Enerji Nədir və Niyə Vacibdir?

Enerji həyatımızın hər anında lazımdır. Səhər oyandığınızda işıq yandırırsınız - enerji. Soyuducu yeməyi təzə saxlayır - enerji. Avtomobillər hərəkət edir - enerji. Fabriklərdə məhsul istehsal olunur - enerji. Enerji olmadan müasir həyat düşünülə bilməz.

Azərbaycan enerji sahəsində zəngin ölkədir. Ölkəmiz həm özünü enerji ilə təmin edir, həm də digər ölkələrə enerji ixrac edir.

## Azərbaycanda Enerji Mənbələri

### 1. Neft və Qaz

Azərbaycan "Odlar Yurdu" adlanır. Bunun əsas səbəbi yeraltı təbii qaz ehtiyatlarıdır. Min illər əvvəl Abşeronda torpaqdan alov çıxırdı - bu, təbii qazın özü idi.

**Neft hasilatı:** Azərbaycanda neft hasilatının tarixi 150 ildən çoxdur. İlk neft quyusu 1847-ci ildə Abşeronda qazılmışdır. Bu, dünyada ilk mexaniki qaydada qazılmış neft quyusudur.

Hazırda Azərbaycanda neft və qaz hasilatının böyük hissəsi Xəzər dənizinin dibindən çıxarılır. "Azəri-Çıraq-Günəşli" və "Şahdəniz" kimi böyük yataqlar vardır.

**Qaz hasilatı:** "Şahdəniz" yatağı Azərbaycanın ən böyük qaz yatağıdır. Buradan hasil olunan qaz həm Azərbaycanda istifadə olunur, həm də Türkiyə və Avropaya ixrac edilir.

### 2. Su Enerjisi (Hidroelektrik)

Azərbaycanda çaylardan enerji əldə etmək üçün su elektrik stansiyaları (SES) tikilib. Suyun axını turbinləri fırladır və elektrik enerjisi hasil olur.

Ən böyük su elektrik stansiyası Mingəçevir SES-dir. O, Kür çayı üzərində yerləşir və ölkənin elektrik enerjisi tələbatının təxminən 15%-ni təmin edir.

### 3. Günəş Enerjisi

Azərbaycan günəşli ölkədir. İldə ortalama 2400-2800 saat günəş işığı olur. Bu, günəş enerjisindən istifadə üçün əla şəraitdir.

Hazırda Azərbaycanda günəş panelləri quraşdırılır. Naxçıvan Muxtar Respublikasında böyük günəş stansiyası fəaliyyət göstərir.

### 4. Külək Enerjisi

Xəzər dənizi sahilində və dağlıq ərazilərdə güclü küləklər əsir. Bu külək enerjisindən istifadə üçün yaxşı imkandır. Abşeronda ilk külək stansiyaları artıq işləyir.

## Enerji İstehsalı Statistikası

Aşağıdakı cədvəldə Azərbaycanda müxtəlif mənbələrdən hasil olunan enerjinin faizi göstərilib:

| Enerji Mənbəyi | Faiz (%) | İzah |
|----------------|----------|------|
| Neft və Qaz | 85% | Əsas enerji mənbəyi |
| Su Enerjisi | 12% | İkinci böyük mənbə |
| Günəş Enerjisi | 2% | Yeni inkişaf edir |
| Külək Enerjisi | 1% | Başlanğıc mərhələ |

## Bərpa Olunan və Bərpa Olunmayan Mənbələr

Enerji mənbələri iki qrupa bölünür:

**Bərpa olunmayan mənbələr:** Bunlar bir dəfə istifadə olunduqdan sonra yenidən yaranmır. Neft və qaz bərpa olunmayan mənbələrdir. Onların ehtiyatı məhduddur.

**Bərpa olunan mənbələr:** Bunlar təbiətdə daim yenilənir. Günəş, külək və su enerjisi bərpa olunan mənbələrdir. Onlar heç vaxt tükənmir.

## Ətraf Mühitə Təsir

Müxtəlif enerji mənbələrinin ətraf mühitə fərqli təsiri var:

**Neft və qaz:** Yandırıldıqda atmosferə karbon qazı (CO₂) buraxır. Bu, havanı çirkləndirir və iqlim dəyişikliyinə səbəb olur.

**Su, günəş və külək:** Bu mənbələr təmiz enerjidirlər. Onlar havanı çirkləndirmir və təbiətə zərər vurmur.

## Gələcək Planlar

Azərbaycan hökuməti bərpa olunan enerji mənbələrinin payını artırmaq planı qurub. 2030-cu ilə qədər enerji istehsalının 30%-nin bərpa olunan mənbələrdən olması hədəflənir.

Bunun üçün:
- Yeni günəş stansiyaları tikiləcək
- Külək fermalarının sayı artacaq  
- Su elektrik stansiyaları modernləşdiriləcək
- Enerji səmərəliliyi artırılacaq

## Enerji Qənaəti

Hər birimiz enerji qənaətinə töhfə verə bilərik:

1. İstifadə etmədiyiniz otaqda işığı söndürün
2. Televizora baxmadıqda onu tam söndürün
3. Soyuducu qapısını uzun müddət açıq saxlamayın
4. Qısaldılmış duş qəbul edin (isti su qızdırmaq çox enerji tələb edir)
5. Məktəbə piyada və ya velosipedlə gedin

Enerji qənaəti həm pul qənaətidi, həm də təbiəti qorumaq deməkdir.',
5,
620,
4,
TRUE
)
RETURNING sample_id;

-- 2. SUALLAR (sample_id-ni əllə dəyişdirin)

INSERT INTO assessment.questions 
(text_sample_id, question_number, question_text, question_type, cognitive_level, max_score, options, correct_answer)
VALUES
-- Çoxseçimli suallar
(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 1, 'Azərbaycanda ilk mexaniki neft quyusu hansı ildə qazılmışdır?', 'multiple_choice', 'straightforward', 1, 
'[{"option":"A","text":"1747"},{"option":"B","text":"1847"},{"option":"C","text":"1947"},{"option":"D","text":"1857"}]', 'B'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 2, 'Mingəçevir SES hansı çay üzərində yerləşir?', 'multiple_choice', 'straightforward', 1,
'[{"option":"A","text":"Araz"},{"option":"B","text":"Kür"},{"option":"C","text":"Xəzər"},{"option":"D","text":"Səməd"}]', 'B'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 3, 'Cədvələ görə, Azərbaycanda enerji istehsalının ən böyük hissəsi hansı mənbədəndir?', 'multiple_choice', 'straightforward', 1,
'[{"option":"A","text":"Su enerjisi"},{"option":"B","text":"Günəş enerjisi"},{"option":"C","text":"Neft və qaz"},{"option":"D","text":"Külək enerjisi"}]', 'C'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 4, 'Azərbaycanda ildə ortalama neçə saat günəş işığı olur?', 'multiple_choice', 'straightforward', 1,
'[{"option":"A","text":"1000-1500"},{"option":"B","text":"1500-2000"},{"option":"C","text":"2400-2800"},{"option":"D","text":"3000-3500"}]', 'C'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 5, 'Niyə Azərbaycan "Odlar Yurdu" adlanır?', 'multiple_choice', 'make_inferences', 2,
'[{"option":"A","text":"Çünki burada çox yanğın olur"},{"option":"B","text":"Çünki yay çox isti olur"},{"option":"C","text":"Çünki torpaqdan təbii qaz çıxırdı və alışırdı"},{"option":"D","text":"Çünki vulkanlar var"}]', 'C'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 6, 'Cədvələ əsasən, bərpa olunan enerji mənbələrinin ümumi faizi nə qədərdir?', 'multiple_choice', 'make_inferences', 2,
'[{"option":"A","text":"10%"},{"option":"B","text":"15%"},{"option":"C","text":"20%"},{"option":"D","text":"25%"}]', 'B'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 7, 'Niyə Xəzər sahilində külək stansiyaları qurmaq yaxşı fikirdir?', 'multiple_choice', 'make_inferences', 2,
'[{"option":"A","text":"Orada çox adam yaşayır"},{"option":"B","text":"Orada güclü küləklər əsir"},{"option":"C","text":"Ora gözəldir"},{"option":"D","text":"Ora ucuzdur"}]', 'B'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 8, 'Mətnə görə, gələcəkdə hansı enerji növünün payı artacaq?', 'multiple_choice', 'interpret_and_integrate', 2,
'[{"option":"A","text":"Neft"},{"option":"B","text":"Qaz"},{"option":"C","text":"Bərpa olunan mənbələr"},{"option":"D","text":"Kömür"}]', 'C'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 9, '"Enerji qənaəti həm pul qənaətidi, həm də təbiəti qorumaq deməkdir" - bu cümlə nəyi bildirir?', 'multiple_choice', 'interpret_and_integrate', 2,
'[{"option":"A","text":"Yalnız pul qənaət etmək lazımdır"},{"option":"B","text":"İki fayda var: iqtisadi və ekoloji"},{"option":"C","text":"Təbiət vacib deyil"},{"option":"D","text":"Enerji çox bahadır"}]', 'B'),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 10, 'Sənin fikrincə, Azərbaycan niyə bərpa olunan enerjiyə keçməlidir?', 'multiple_choice', 'examine_and_evaluate', 3,
'[{"option":"A","text":"Çünki neft bitəcək və təbiəti qorumalıyıq"},{"option":"B","text":"Çünki neft ucuzdur"},{"option":"C","text":"Çünki günəş yaxşıdır"},{"option":"D","text":"Çünki başqa ölkələr belə edir"}]', 'A'),

-- Açıq cavab sualları
(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 11, 'Mətnə əsasən, bərpa olunan və bərpa olunmayan enerji mənbələri arasında əsas fərq nədir? İki nümunə göstər.', 'open_response', 'make_inferences', 2, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 12, 'Cədvələ baxaraq, niyə Azərbaycan hələ də əsasən neft və qazdan asılıdır? Məntiqli izah ver.', 'open_response', 'make_inferences', 2, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 13, 'Mətn göstərir ki, su enerjisi 12%, amma günəş enerjisi cəmi 2%-dir. Azərbaycanda günəş çoxdur, bəs niyə günəş enerjisi az istifadə olunur? Ehtimal et.', 'open_response', 'make_inferences', 3, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 14, 'Mətnin "Enerji Qənaəti" hissəsində verilən 5 məsləhətdən ən asanı hansıdır və niyə?', 'open_response', 'interpret_and_integrate', 2, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 15, 'Müəllif niyə mətnin sonunda "Enerji Qənaəti" bölməsini əlavə edib? Bu bölmənin məqsədi nədir?', 'open_response', 'interpret_and_integrate', 3, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 16, 'Mətnə əsasən, 2030-cu ilə qədər enerji strukturu necə dəyişəcək? Cədvəldəki məlumatla müqayisə et.', 'open_response', 'interpret_and_integrate', 3, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 17, 'Sənin fikrincə, məktəblərdə günəş panelləri quraşdırmaq yaxşı fikirdirmi? Nə üçün? Müsbət və mənfi cəhətlərini göstər.', 'open_response', 'examine_and_evaluate', 3, NULL, NULL),

(CURRVAL('reading_literacy.text_samples_sample_id_seq'), 18, 'Mətn neft və qazın havanı çirkləndirdiyini deyir. Bəs niyə Azərbaycan hələ də neft və qaz hasil edir? Bu ziddiyyəti necə izah edə bilərsən?', 'open_response', 'examine_and_evaluate', 3, NULL, NULL);
