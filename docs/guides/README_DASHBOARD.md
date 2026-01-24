# 📊 POSTGRESQL BAZA ANALİZ SİSTEMİ

Bu paket PostgreSQL bazanızı ətraflı analiz etmək üçün 2 variant təqdim edir:

## 🎯 VARİANT 1: R Shiny Dashboard (İnteraktiv - Tövsiyə olunur)

### Xüsusiyyətlər:
- ✅ Birbaşa PostgreSQL-ə qoşulur
- ✅ Real-time data
- ✅ Tam interaktiv
- ✅ Çoxlu qrafik və cədvəl
- ✅ Mətn oxuyucu
- ✅ Axtarış sistemi

### İstifadə:

```r
# RStudio-da aç və çalışdır
library(shiny)
runApp("baza_analiz_dashboard.R")
```

### Tələb olunan paketlər:
```r
install.packages(c(
  "shiny",
  "shinydashboard", 
  "DT",
  "ggplot2",
  "plotly",
  "RPostgreSQL",
  "dplyr",
  "tidyr",
  "jsonlite",
  "htmltools",
  "markdown"
))
```

### Dashboard Bölmələri:

1. **🏠 Ümumi Məlumat**
   - Əsas statistika (mətn, sual, söz sayı)
   - Mətn növləri qrafiki
   - Sual tipləri qrafiki
   - Son mətnlər cədvəli

2. **📚 Mətn Siyahısı**
   - Bütün mətnlər cədvəli
   - Filtrlər (növ, sinif, söz sayı)
   - Sıralama
   - Detallara keçid

3. **❓ Sual Təhlili**
   - Mətn seçimi
   - Sual statistikası
   - Qapalı/Açıq bölgüsü
   - Bal bölgüsü qrafiki
   - Bütün suallar və cavablar

4. **📖 Mətn Oxu**
   - Mətn seçimi
   - Markdown render
   - Metadata
   - Tam mətn təqdimati

5. **📊 Statistika**
   - Söz sayı qrafikləri
   - Sual sayı qrafikləri
   - Bal bölgüsü
   - Tarix xətti

6. **🔍 Axtarış**
   - Mətn və sual axtarışı
   - Açar söz ilə axtarış
   - Nəticələr siyahısı

7. **⚙️ Baza Strukturu**
   - Cədvəl siyahısı
   - Cədvəl ölçüləri
   - Sütun strukturları

---

## 🌐 VARİANT 2: HTML Dashboard (Statik)

### Xüsusiyyətlər:
- ✅ Brauzer əsaslı
- ✅ Sadə istifadə
- ✅ İnternet lazım deyil
- ⚠️ Data əvvəlcədən export edilməlidir

### İstifadə Addımları:

#### ADDIM 1: Data Export
```r
# R Console-da çalışdırın
source("export_baza_json.R")

# Nəticə: baza_data.json faylı yaranacaq
```

#### ADDIM 2: Faylları Yerləşdirin
```
my_folder/
  ├── baza_dashboard.html
  └── baza_data.json
```

#### ADDIM 3: Brauzer-də Açın
- `baza_dashboard.html` faylını ikiqat klikləyin
- və ya sağ klik → "Open with → Chrome/Firefox"

### HTML Dashboard Bölmələri:

1. **🏠 Ümumi Məlumat** - Əsas statistika və qrafiklər
2. **📚 Mətn Siyahısı** - Filtrlənə bilən cədvəl
3. **❓ Sual Təhlili** - Mətn üzrə sual təhlili
4. **📖 Mətn Oxu** - Markdown formatında mətn oxuyucu
5. **📊 Statistika** - Ətraflı qrafiklər
6. **🔍 Axtarış** - Açar söz axtarışı

---

## 📋 MÜQAYİSƏ

| Xüsusiyyət | R Shiny | HTML |
|------------|---------|------|
| PostgreSQL birbaşa | ✅ | ❌ |
| Real-time data | ✅ | ❌ |
| Setup asan | ⚠️ | ✅ |
| Paket tələbi | Var | Yox |
| İnternet | Yox | Yox |
| Daha çox funksiya | ✅ | ⚠️ |

---

## 🔧 TROUBLESHOOTİNG

### Problem: R Shiny açılmır
**Həll:** Paketləri yenidən yükləyin:
```r
install.packages("shiny", dependencies = TRUE)
```

### Problem: PostgreSQL qoşulmur
**Həll:** Baza məlumatlarını yoxlayın:
```r
# baza_analiz_dashboard.R faylında
# 24-33 sətirlər - qoşulma məlumatları
dbname = "azerbaijan_language_standards"
user = "royatalibova"
```

### Problem: HTML-də data görünmür
**Həll:** 
1. `export_baza_json.R` çalışdırın
2. `baza_data.json` faylının eyni qovluqda olduğunu yoxlayın
3. Brauzer console-da xəta yoxlayın (F12)

### Problem: Markdown düzgün render olmur
**Həll:** Şəkil və cədvəllərdə HTML istifadə edin, saf markdown yox

---

## 💡 TÖVSİYƏLƏR

1. **R Shiny-i işlətmək daha yaxşıdır** - real-time data və daha çox funksiya
2. **HTML-i demo üçün işlədin** - sadə və sürətli
3. **Data-nı mütəmadi export edin** - HTML versiyası üçün
4. **Qrafiklər PNG export edilə bilər** - hesabatlar üçün

---

## 📞 DƏSTƏK

Problemlə qarşılaşsanız:
1. README-ni yenidən oxuyun
2. R Console-da xəta mesajlarına baxın
3. Brauzer console-da xəta yoxlayın (F12)

---

## 🎯 GƏLƏCƏKDƏ ƏLAVƏLƏR

- [ ] PDF Export
- [ ] Excel Export  
- [ ] Avtomatik hesabat yaratma
- [ ] Email göndərmə
- [ ] Daha çox qrafik növləri

---

**Müəllif:** ARTI  
**Tarix:** 2025  
**Versiya:** 1.0
