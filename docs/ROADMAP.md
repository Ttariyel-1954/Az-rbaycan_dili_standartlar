# Oxu Savadlılığı Qiymətləndirmə Sistemi - Yol Xəritəsi

**Author:** Talıbov Tariyel İsmayıl oğlu  
**Təşkilat:** ARTI - Azerbaijan Republic Education Institute  
**Tarix:** Yanvar 2025

---

## 📊 Mövcud Vəziyyət

### Hazırda Olanlar ✅
- ✅ **Standartlar**: 1-4 sinif Azərbaycan dili standartları (PISA/PIRLS-ə uyğun)
- ✅ **Mətn Bankı**: 40+ keyfiyyətli mətn (beynəlxalq best practices)
- ✅ **Verilənlər Bazası**: PostgreSQL strukturu
- ✅ **İnteraktiv Dashboardlar**: 
  - Mətn Kəşfiyyatçısı (görüntüləmə)
  - Mətn Redaktoru (redaktə)

### Best Practices Tətbiqi
- 🇸🇬 **Sinqapur**: CPA (Concrete-Pictorial-Abstract) metodologiyası
- 🇫🇮 **Finlandiya**: Oyun əsaslı öyrənmə
- 🇯🇵 **Yaponiya**: Lesson Study yanaşması
- 🇪🇪 **Estoniya**: Rəqəmsal savadlılıq
- 🇳🇿 **Yeni Zelandiya**: Mədəni həssaslıq

---

## 🎯 Ümumi Məqsəd

**Vizyon:** Azərbaycanın ibtidai təhsil sistemi üçün AI-powered, beynəlxalq standartlara uyğun, adaptiv oxu savadlılığı qiymətləndirmə sistemi yaratmaq.

**Mission:** 
1. Şagirdlərin oxu bacarıqlarını obyektiv qiymətləndirmək
2. Müəllimlərə real-vaxt feedback təqdim etmək
3. Kurrikulumu məlumat əsasında təkmilləşdirmək
4. Azərbaycan təhsil sistemini beynəlxalq səviyyəyə çatdırmaq

---

## 📅 6 Mərhələli İmplementasiya Planı

### **MƏRHƏLƏ 1: Sual Bankı Yaratmaq** 
**Müddət:** 2-3 həftə  
**Status:** 🟡 Hazırlanır

#### Texniki Məqsəd
Hər mətn üçün PISA/PIRLS formatında 6 sual yaratmaq:
- 2 Literal Anlama sualı (məlumat tapmaq)
- 2 İnformal Anlama sualı (nəticə çıxarmaq)
- 2 Qiymətləndirmə/Təhlil sualı (tənqidi düşünmək)

#### Sual Tipləri
1. **Çoxseçimli** (Multiple Choice)
   - 4 variant
   - 1 düzgün cavab
   - Avtomatik qiymətləndirmə
   
2. **Qısa Cavab** (Short Answer)
   - 1-2 cümlə
   - AI qiymətləndirmə (0-1 bal)
   
3. **Uzun Cavab** (Extended Response)
   - 3-5 cümlə
   - AI qiymətləndirmə (0-2 bal)
   - Ətraflı rubrik

#### Texniki Həll
- **question_generator.R**: Claude API ilə avtomatik sual generasiyası
- **Verilənlər bazası**: `assessment.questions` cədvəli
- **Format**: JSON → PostgreSQL

#### Əsas Addımlar
1. Claude API key konfiqurasiyası
2. Bir neçə mətn üçün pilot sual yaratma
3. Sualların keyfiyyət yoxlaması (pedaqoq ekspert)
4. Toplu sual yaratma (40 mətn × 6 sual = 240 sual)
5. Bazaya yükləmə

#### Çıxış
- 240 yüksək keyfiyyətli sual
- Hər sual metadata ilə (cognitive level, skill focus)
- PostgreSQL bazasında saxlanılmış

---

### **MƏRHƏLƏ 2: AI Qiymətləndirmə Sistemi**
**Müddət:** 1-2 həftə  
**Status:** 🟡 Hazırlanır

#### Texniki Məqsəd
Şagird cavablarını avtomatik və obyektiv qiymətləndirmək

#### Qiymətləndirmə Növləri

**1. Çoxseçimli Suallar**
- Avtomatik qiymətləndirmə (0 və ya 1 bal)
- Düzgün/yanlış feedback

**2. Açıq Cavablar (AI-powered)**
- Claude Sonnet 4 istifadə edilir
- Rubrik əsasında bal (0-2)
- Ətraflı feedback:
  - Güclü tərəflər
  - İnkişaf sahələri
  - Düzəldilmiş nümunə cavab

#### Texniki Həll
- **ai_grading_system.R**: AI qiymətləndirmə mühərriki
- **Prompt Engineering**: Rubrik-based grading
- **Feedback Generation**: Konstruktiv, yaşa uyğun

#### Keyfiyyət Təminatı
1. **Pilot Testing**: 10-20 real şagird cavabı
2. **Human Review**: Müəllim ekspert yoxlaması
3. **Calibration**: AI vs insan qiymətləndirməsi (>85% uyğunluq)
4. **Iteration**: Prompt təkmilləşdirməsi

#### Çıxış
- Avtomatik qiymətləndirmə sistemi
- Ətraflı feedback mexanizmi
- Qiymətləndirmə keyfiyyət metriki

---

### **MƏRHƏLƏ 3: İnteraktiv Test Platforması**
**Müddət:** 2 həftə  
**Status:** 🟡 Hazırlanır

#### Texniki Məqsəd
Shiny-based veb platforması - şagirdlər üçün user-friendly

#### Funksional Xüsusiyyətlər

**1. Şagird Girişi**
- Ad, soyad, sinif, məktəb
- Session tracking

**2. Test İnterfeyi**
- Mətn oxunuşu (böyük, rahat şrift)
- Suallar bir-bir göstərilir
- Progress bar (cavablanma vəziyyəti)
- Cavabların avtomatik saxlanması

**3. Cavab Tipləri**
- Radio buttons (çoxseçimli)
- Text area (açıq cavablar, böyük şrift)
- Timer (optional, adaptiv)

**4. Nəticələr və Feedback**
- Real-vaxt bal hesablanması
- Bacarıq təhlili (cognitive levels)
- Hər sual üçün ətraflı feedback
- İnkişaf tövsiyələri

#### Texniki Həll
- **test_platform_app.R**: Shiny dashboard
- **Real-time grading**: Submit → AI grade → Results
- **Responsive design**: Tablet/desktop uyğun

#### Çıxış
- İşlək test platforması
- Şagird-friendly interfeys
- Real-vaxt feedback sistemi

---

### **MƏRHƏLƏ 4: Pilot Testing və Validasiya**
**Müddət:** 3-4 həftə  
**Status:** ⚪ Planlaşdırılır

#### Məqsəd
Real şagirdlərlə test və sistem validasiyası

#### Pilot Qrup
- **Həcm**: 50-100 şagird (hər sinifdən 25)
- **Məktəblər**: 2-3 pilot məktəb (Bakı və region)
- **Müəllimlər**: 4-6 müəllim (hər sinifdən 1-2)

#### Test Protokolu
1. **Pre-test Briefing**: Müəllim təlimi
2. **Test İcra**: 
   - Hər şagird 1 mətn, 6 sual (~30 dəqiqə)
   - Müşahidəçi qeydləri
3. **Post-test**: Şagird/müəllim sorğusu

#### Məlumat Toplanması
- Test nəticələri (bal, vaxt, feedback)
- Texniki məsələlər (UI/UX problemləri)
- Pedaqoji feedback (sual keyfiyyəti)
- İstifadəçi təcrübəsi (user satisfaction)

#### Validasiya Metriki
- **Reliability**: Test-retest reliability >0.80
- **AI Accuracy**: AI vs müəllim qiymətləndirməsi >85% uyğunluq
- **User Experience**: Satisfaction >4.0/5.0
- **Technical Performance**: <5% texniki xəta

#### Çıxış
- Validasiya hesabatı
- Sistem təkmilləşdirmə planı
- Genişləndirmə hazırlığı

---

### **MƏRHƏLƏ 5: Mətn və Sual Təkmilləşdirməsi**
**Müddət:** 2-3 həftə  
**Status:** ⚪ Planlaşdırılır

#### Məqsəd
Pilot testing nəticələrinə əsasən mətn və sualları düzəltmək

#### Təkmilləşdirmə Sahələri

**1. Mətn Təkmilləşdirməsi**
- Çətinlik səviyyəsi ayarlanması
- Mədəni kontekst yoxlaması
- Söz sayı optimizasiyası
- Maraq dərəcəsi artırma

**2. Sual Təkmilləşdirməsi**
- Qeyri-müəyyən sualların düzəldilməsi
- Variant çətinliyinin balanslaşdırılması
- Rubrik dəqiqləşdirilməsi
- Yeni sual növlərinin əlavəsi

#### Metodologiya
1. **İtem Analysis**:
   - Difficulty index (p-value)
   - Discrimination index
   - Distractor analysis

2. **Expert Review**:
   - Pedaqoq komanda (4-5 nəfər)
   - Dil mütəxəssisi
   - Assessment eksperti

3. **Revision Cycle**:
   - Problemli itemlərin identifikasiyası
   - Redaktə və yenidən yazma
   - Re-pilot testing (kiçik qrup)

#### Çıxış
- Təkmilləşdirilmiş mətn bankı
- Yüksək keyfiyyətli sual bankı
- Finalized assessment materials

---

### **MƏRHƏLƏ 6: Geniş İmplementasiya və Adaptive Testing**
**Müddət:** 4-6 ay  
**Status:** ⚪ Planlaşdırılır

#### Məqsəd
Sistemi genişləndirmək və adaptiv test funksiyası əlavə etmək

#### 6A. Genişləndirmə (Scale-up)
- **Həcm**: 22 məktəb/gimnaziya (ARTI şəbəkəsi)
- **Şagirdlər**: ~1000-2000 şagird
- **Müəllimlər**: ~50 müəllim təlimi

#### 6B. Adaptive Testing Sistemi (CAT)
**Computer Adaptive Testing** - Item Response Theory (IRT) əsaslı

**Necə işləyir:**
1. Orta çətinlikdə sual ilə başla
2. Düzgün cavab → daha çətin sual
3. Yanlış cavab → daha asan sual
4. 6-8 sual sonra dəqiq səviyyə müəyyənləşir

**Üstünlüklər:**
- Daha qısa test (6-8 sual vs 15-20)
- Daha dəqiq qiymətləndirmə
- Şagird frustration azalır
- Real-time bacarıq təxmini

#### Texniki Tələblər (CAT)
- IRT parametrləri (a, b, c)
- Item calibration (minimum 200 test-taker)
- Adaptive algorithm (R: mirt, catR paketləri)

#### 6C. Müəllim Dashboard
Müəllimlər üçün real-time analitika:
- Sinif performansı
- Şagird inkişaf izləmə
- Boşluq identifikasiyası
- Intervention tövsiyələri

#### Çıxış
- Tam funksional, genişmiqyaslı sistem
- Adaptive testing imkanı
- Müəllim analitika platforması
- Milli səviyyədə readiness

---

## 🛠️ Texniki Arxitektura

### Sistem Komponentləri

```
┌─────────────────────────────────────────┐
│     Frontend (Shiny Dashboards)         │
├─────────────────────────────────────────┤
│  • Test Platform (student interface)    │
│  • Text Explorer (browse texts)         │
│  • Text Editor (edit texts)             │
│  • Teacher Dashboard (analytics)        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│     Backend (R + Claude API)            │
├─────────────────────────────────────────┤
│  • Question Generator                   │
│  • AI Grading System                    │
│  • Adaptive Algorithm (future)          │
│  • Analytics Engine                     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│     Database (PostgreSQL)               │
├─────────────────────────────────────────┤
│  Schema: reading_literacy               │
│   • text_samples                        │
│   • grades, text_types                  │
│                                         │
│  Schema: assessment                     │
│   • questions                           │
│   • students                            │
│   • test_sessions                       │
│   • student_answers                     │
└─────────────────────────────────────────┘
```

### Texnologiya Stack
- **Frontend**: R Shiny, shinydashboard, shinyjs
- **Backend**: R (tidyverse, httr, jsonlite)
- **AI**: Claude Sonnet 4 (API)
- **Database**: PostgreSQL
- **Analytics**: ggplot2, plotly (visualizations)
- **Adaptive**: mirt, catR (IRT/CAT - future)

---

## 📊 Uğur Metriki (KPIs)

### Texniki Metriklər
- ✅ Test completion rate: >95%
- ✅ System uptime: >99%
- ✅ AI grading accuracy: >85% (vs human)
- ✅ Average test time: 25-35 dəqiqə

### Pedaqoji Metriklər
- 📚 Test reliability (Cronbach's α): >0.80
- 📚 Item discrimination: >0.30
- 📚 Student satisfaction: >4.0/5.0
- 📚 Teacher satisfaction: >4.2/5.0

### Impact Metriklər
- 🎯 Şagird inkişafı (pre-post): >10% artım
- 🎯 Müəllim feedback istifadəsi: >70%
- 🎯 Mətn keyfiyyəti reytinqi: >4.3/5.0
- 🎯 Sistem adoption rate: >80% (pilot məktəblər)

---

## 💰 Resurs Tələbləri

### İnsan Resursları
- **Layihə Meneceri**: 1 nəfər (part-time, 6 ay)
- **R Developer**: 1 nəfər (full-time, 3 ay)
- **Pedaqoji Ekspert**: 2 nəfər (part-time, mərhələ 1, 4, 5)
- **Assessment Ekspert**: 1 nəfər (part-time, bütün mərhələlər)
- **Pilot Müəllimlər**: 4-6 nəfər (mərhələ 4)

### Texniki Resurslar
- **Cloud Server**: DigitalOcean və ya AWS (PostgreSQL + Shiny Server)
- **Claude API**: ~5000-10000 API çağırışı (Mərhələ 1, 2)
- **Backup Storage**: 50GB (mətn, sual, data)

### Maliyyə (Təxmini)
- **Cloud Infrastructure**: $50-100/ay × 6 ay = $300-600
- **Claude API**: $100-200 (sual generasiya + grading)
- **Human Resources**: Internal ARTI resursları
- **Pilot Testing**: Minimal (material printing)

**Ümumi Təxmini**: $500-1000 (6 ay)

---

## ⚠️ Risklər və Azaldılması

### Risk 1: AI Qiymətləndirmə Dəqiqliyi
**Risk**: AI qiymətləndirməsi müəllimlərdən fərqlənir  
**Azaldılma**: 
- Geniş pilot testing və calibration
- Müntəzəm human review
- Rubrik dəqiqləşdirməsi

### Risk 2: Texniki Problemlər (Server, Əlaqə)
**Risk**: İnternet/server problemləri testə mane olur  
**Azaldılma**:
- Offline mode (local SQLite backup)
- Cloud redundancy
- Pilot phase-də texniki test

### Risk 3: Müəllim/Şagird Qəbulu
**Risk**: İstifadəçilər sistemi qəbul etmir  
**Azaldılma**:
- User-friendly dizayn
- Ətraflı təlim
- Pilot feedback-in inteqrasiyası

### Risk 4: Mətn/Sual Keyfiyyəti
**Risk**: Mətnlər və ya suallar yaşa uyğun deyil  
**Azaldılma**:
- Ekspert review (Mərhələ 1)
- Pilot testing (Mərhələ 4)
- İterative revision (Mərhələ 5)

---

## 🎓 Təlim və Dəstək

### Müəllim Təlimi
**Mərhələ 4 öncəsi:**
1. **Online Təlim** (2 saat)
   - Sistem overview
   - Test protocol
   - Feedback interpretation

2. **Hands-on Workshop** (3 saat)
   - Live demo
   - Test taking (müəllim perspektivi)
   - Q&A session

**Dəstək Materialları:**
- Video tutorial
- PDF quick guide
- FAQ document

### Texniki Dəstək
- **Help Desk**: Email/telefon support (pilot phase)
- **Documentation**: GitHub README
- **Troubleshooting Guide**: Common issues

---

## 📈 Uzunmüddətli Vizyon (1-2 il)

### Faza 2: Genişləndirmə
- Bütün ibtidai siniflər (I-IV)
- Bütün ARTI məktəbləri (22 məktəb)
- Tam adaptiv testing (CAT)

### Faza 3: Milli Səviyyə
- Azərbaycanın digər məktəbləri
- Təhsil Nazirliyi inteqrasiyası
- Milli benchmark normaları

### Faza 4: Məzmun Genişlənməsi
- Riyaziyyat qiymətləndirməsi
- Elm qiymətləndirməsi
- Formative assessment tools

---

## 📞 Əlaqə və Məsuliyyət

**Layihə Rəhbəri:**  
Talıbov Tariyel İsmayıl oğlu  
Deputy Director of Assessment, Analysis and Monitoring  
ARTI - Azerbaijan Republic Education Institute

**Texniki Komanda:**  
R Development & Database: Tariyel Talıbov  
Assessment Design: ARTI Pedaqoji Şöbə  
Pilot Coordination: ARTI Field Team

---

## ✅ Növbəti Addımlar (İmmediate)

### Bu həftə:
1. ✅ Yol xəritəsi təsdiqi
2. ⏳ Claude API key əldə etmək
3. ⏳ Pilot məktəbləri seçmək

### Növbəti həftə:
1. Mərhələ 1 başlanğıc (sual generasiyası)
2. 10 mətn üçün sual yaratmaq (test)
3. Ekspert review təşkil etmək

### 2 həftə içində:
1. Bütün mətnlər üçün suallar (240 sual)
2. AI grading system test
3. Test platform beta versiya

---

**Tərtib tarixi:** Yanvar 2025  
**Versiya:** 1.0  
**Status:** Draft - ARTI rəhbərliyinin təsdiqi gözlənilir