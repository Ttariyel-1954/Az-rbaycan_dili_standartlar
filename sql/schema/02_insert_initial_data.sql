-- İlkin məlumatların yüklənməsi
SET search_path TO reading_literacy;

-- 1. Sinifləri əlavə edirik
INSERT INTO grades (grade_level, grade_name_az, age_range) VALUES
(1, 'I sinif', '6-7 yaş'),
(2, 'II sinif', '7-8 yaş'),
(3, 'III sinif', '8-9 yaş'),
(4, 'IV sinif', '9-10 yaş'),
(5, 'V sinif', '10-11 yaş'),
(6, 'VI sinif', '11-12 yaş'),
(7, 'VII sinif', '12-13 yaş'),
(8, 'VIII sinif', '13-14 yaş'),
(9, 'IX sinif', '14-15 yaş');

-- 2. Beynəlxalq framework-ləri
INSERT INTO frameworks (framework_name, framework_type, description_az, description_en, version) VALUES
('PISA', 'primary', 
 'Beynəlxalq Şagird Qiymətləndirmə Proqramı - əsas strateji hədəf',
 'Programme for International Student Assessment - primary strategic target',
 '2022'),
 
('PIRLS', 'secondary',
 'Beynəlxalq Oxu Savadı Tədqiqatı - fundamentin ölçülməsi',
 'Progress in International Reading Literacy Study - foundation measurement',
 '2021'),
 
('CEFR', 'complementary',
 'Avropa Dil Bilikləri Çərçivəsi - tamamlayıcı alət',
 'Common European Framework of Reference for Languages',
 'A1-C2'),
 
('EGRA', 'complementary',
 'Erkən Siniflərdə Oxu Bacarıqlarının Qiymətləndirilməsi',
 'Early Grade Reading Assessment - USAID/World Bank',
 '2020');

-- 3. PISA Reading Framework - əsas aspektlər
INSERT INTO reading_aspects (framework_id, aspect_code, aspect_name_az, aspect_name_en, aspect_type, description_az) VALUES
-- Ana aspektlər
(1, 'PISA_LOC', 'Məlumatı tapmaq və çıxarmaq', 'Locate and retrieve information', 'locate_info',
 'Mətndə konkret məlumatı tapmaq, əlaqəli məlumatları müəyyən etmək'),
 
(1, 'PISA_UND', 'Mətnə anlamaq və başa düşmək', 'Understand and integrate', 'understand',
 'Mətnin mənasını qavramaq, əsas fikri müəyyən etmək, əlaqələri anlamaq'),
 
(1, 'PISA_EVL', 'Qiymətləndirmək və mühakimə yürütmək', 'Evaluate and reflect', 'evaluate',
 'Mətnin keyfiyyətini, etibarlılığını qiymətləndirmək, məzmunla bağlı mühakimə yürütmək'),
 
(1, 'PISA_REF', 'Refleksiya və tətbiq', 'Reflect and apply', 'reflect',
 'Mətn məzmununu öz biliklə əlaqələndirmək, praktiki həyatda tətbiq etmək');

-- 4. PIRLS Reading Framework - əsas komponentlər
INSERT INTO reading_aspects (framework_id, aspect_code, aspect_name_az, aspect_name_en, aspect_type, description_az) VALUES
(2, 'PIRLS_RET', 'Açıq-aydın verilmiş məlumatı tapmaq', 'Retrieve explicitly stated information', 'locate_info',
 'Mətndə birbaşa ifadə olunmuş faktları və detalları tapmaq'),
 
(2, 'PIRLS_INF', 'Sadə nəticələr çıxarmaq', 'Make straightforward inferences', 'understand',
 'Mətn əsasında birbaşa nəticələr çıxarmaq və əlaqələr qurmaq'),
 
(2, 'PIRLS_INT', 'Fikirləri və məlumatları birləşdirmək', 'Integrate ideas and information', 'understand',
 'Mətnin müxtəlif hissələrindən məlumatları birləşdirərək ümumi mənzərə yaratmaq'),
 
(2, 'PIRLS_EXM', 'Məzmunu təhlil və qiymətləndirmək', 'Examine and evaluate content', 'evaluate',
 'Mətnin məzmununu, strukturunu və dil xüsusiyyətlərini təhlil etmək');

-- 5. PISA Mətn növləri
INSERT INTO text_types (type_name_az, type_name_en, category, description_az, examples) VALUES
('Təsviri mətn', 'Description', 'continuous',
 'Obyekt, insan, hadisə və ya fenomenin xüsusiyyətlərini təsvir edən mətn',
 ARRAY['Təbiət təsvirləri', 'Portret', 'Yer təsviri']),
 
('Nəqli mətn', 'Narration', 'continuous',
 'Zaman ardıcıllığı ilə hadisələrin təqdimatı',
 ARRAY['Hekayə', 'Təbii hadisələr', 'Bioqrafiya']),
 
('İzahlı mətn', 'Exposition', 'continuous',
 'Konsepsiya və anlayışların izahı',
 ARRAY['Elmi məqalə', 'Təlimat', 'Ensiklopediya maddəsi']),
 
('Arqumentativ mətn', 'Argumentation', 'continuous',
 'Fikir və ideyaların əsaslandırılması',
 ARRAY['Müzakirə', 'Rəy yazısı', 'Tövsiyə']),
 
('Qrafik/Cədvəl', 'Graphic/Table', 'non-continuous',
 'Vizual formada məlumat təqdimatı',
 ARRAY['Cədvəl', 'Diaqram', 'Xəritə', 'Forma']),
 
('Qarışıq mətn', 'Mixed', 'mixed',
 'Müxtəlif növ mətnlərin birləşməsi',
 ARRAY['Jurnal məqaləsi', 'Veb səhifə']);

SELECT 'İlkin məlumatlar uğurla yükləndi!' as status;
