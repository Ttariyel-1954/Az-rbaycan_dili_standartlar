#!/bin/bash
# Azərbaycan dili standartları - Tam proses

echo "🚀 AZƏRBAYCAN DİLİ STANDARTLARI - PISA/PIRLS UYĞUNLAŞDIRMA"
echo "============================================================"
echo ""

cd ~/Desktop/Azərbaycan_dili_standartlar

# Rəng kodları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}MƏRHƏLƏ 1: Baza strukturunun yoxlanılması${NC}"
psql azerbaijan_language_standards -c "\dt reading_literacy.*" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL baza hazırdır${NC}"
else
    echo -e "${YELLOW}⚠️  Baza yoxdur, yaradılır...${NC}"
    createdb azerbaijan_language_standards
    psql azerbaijan_language_standards -f sql/schema/01_create_schema.sql
    psql azerbaijan_language_standards -f sql/schema/02_insert_initial_data.sql
    echo -e "${GREEN}✅ Baza yaradıldı${NC}"
fi
echo ""

echo -e "${BLUE}MƏRHƏLƏ 2: Standartların yüklənməsi${NC}"
Rscript scripts/database/01_load_standards.R
echo ""

echo -e "${BLUE}MƏRHƏLƏ 3: PISA/PIRLS mapping (ilk 10 standart)${NC}"
Rscript scripts/api_integration/03_full_mapping_system.R
echo ""

echo -e "${BLUE}MƏRHƏLƏ 4: Qalan standartların mapping-i${NC}"
Rscript scripts/api_integration/04_map_all_standards.R
echo ""

echo -e "${BLUE}MƏRHƏLƏ 5: Mətn nümunələri generasiyası${NC}"
Rscript scripts/api_integration/05_generate_text_samples.R
echo ""

echo -e "${BLUE}MƏRHƏLƏ 6: Mətn təhlili və tapşırıqlar${NC}"
Rscript scripts/api_integration/06_analyze_and_create_tasks.R
echo ""

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}✅ BÜTÜN PROSES TAMAMLANDI!${NC}"
echo ""
echo "📊 Dashboard-u işə salmaq üçün:"
echo "   Rscript -e \"shiny::runApp('shiny_app', port = 3838)\""
echo ""
