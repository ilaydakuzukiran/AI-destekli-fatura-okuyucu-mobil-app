from flask import Flask, request, jsonify
from ultralytics import YOLO
import cv2
import numpy as np
import base64
import pytesseract
import re

# ---------------------------------------------------------
# TESSERACT YOLU
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
# ---------------------------------------------------------

app = Flask(__name__)

print("Model yükleniyor...")
try:
    model = YOLO("best_new.pt")  # Yeni eğitilmiş model
    print("YENİ MODEL HAZIR! 🚀")
except Exception as e:
    print(f"HATA: {e}")
    model = YOLO("best.pt")  # Eski model yedek

def base64_to_image(base64_string):
    decoded_data = base64.b64decode(base64_string)
    np_data = np.frombuffer(decoded_data, np.uint8)
    image = cv2.imdecode(np_data, cv2.IMREAD_COLOR)
    return image

# --- GÖRÜNTÜ İŞLEME ---
def preprocess_image(img_crop):
    # 1. Büyütme (Upscale)
    img_crop = cv2.resize(img_crop, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)
    
    # 2. Griye Çevir
    gray = cv2.cvtColor(img_crop, cv2.COLOR_BGR2GRAY)
    
    # 3. İki Versiyon Hazırla:
    # A: Adaptive Threshold (Siyah-Beyaz) - Net yazılar için
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                   cv2.THRESH_BINARY, 11, 2)
    
    # B: Orijinal Gri (Gray) - Silik noktalar için yedek
    return thresh, gray

# --- METİN DÜZELTME ---
def correct_typos(text):
    text = text.upper()
    corrections = {
        "HAGAZACILIK": "MAĞAZACILIK",
        "MAGAZACILIK": "MAĞAZACILIK",
        "NAGAZACILIK": "MAĞAZACILIK",
        "BABAZALILIK": "MAĞAZACILIK",
        "YENL": "YENİ",
        "YEN1": "YENİ",
        "VEN ": "YENİ ",
        "A.5": "A.Ş",
        "A.$": "A.Ş",
        "ATO1": "A101"
    }
    for wrong, right in corrections.items():
        if wrong in text:
            text = text.replace(wrong, right)
    return text

def extract_clean_company_name(text):
    """Şirket adını temizler ve sadece ilgili kısmı alır"""
    text = correct_typos(text)
    
    # Başlangıç temizliği: Gereksiz karakterler
    text = text.strip().lstrip('.:;,- ')
    text = text.replace('\n', ' ')
    
    # Yaygın yanlış okumaları düzelt
    text = text.replace('SELÇGUKLU', 'SELÇUKLU')
    text = text.replace('SELCGUKLU', 'SELÇUKLU')
    
    suffixes = ['A.Ş', 'A.S', 'LTD', 'TİC', 'SAN', 'MARKET', 'MAĞAZACILIK', 'AKADEMİ', 'CAFE', 'RESTORAN']
    
    clean_text = text
    
    for suffix in suffixes:
        if suffix in clean_text:
            end_pos = clean_text.find(suffix) + len(suffix)
            raw_part = clean_text[:end_pos]
            
            # Sadece sondan geriye 5 kelimeyi al (Baştaki İlaz Kodu vb. gitsin)
            words = raw_part.split()
            if len(words) > 5:
                final_name = " ".join(words[-5:])
            else:
                final_name = raw_part
            return final_name.strip()
    
    # Suffix yoksa ilk 300 karakteri al (parantez açılırsa orada kes)
    if '(' in clean_text:
        clean_text = clean_text[:clean_text.find('(')].strip()
    
    # Maksimum 300 karakter
    if len(clean_text) > 500:
        words = clean_text.split()[:40]  # İlk 40 kelime
        return " ".join(words).strip()
    
    return clean_text.strip()

def format_date_turkish(date_text):
    """Tarihi senin istediğin DD-MM-YYYY formatına çevirir"""
    try:
        # Sadece rakamları al
        nums = re.sub(r'[^\d]', '', date_text)
        
        # Eğer 8 haneli bitişik sayıysa (29122025)
        if len(nums) == 8:
            day = nums[:2]
            month = nums[2:4]
            year = nums[4:]
            if int(month) <= 12 and int(day) <= 31:
                return f"{day}-{month}-{year}"

        # Ayracı (nokta, tire, slash) olan formatlar (29.12.2025)
        match = re.search(r'(\d{2})[.\-/](\d{2})[.\-/](\d{4})', date_text)
        if match:
            day, month, year = match.groups()
            # BURAYI GÜNCELLEDİK: Artık Gün-Ay-Yıl dönüyor
            return f"{day}-{month}-{year}"
    except:
        pass
    return ""

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.json: return jsonify({'error': 'No image'}), 400

    try:
        img = base64_to_image(request.json['image'])
        results = model(img, conf=0.10) 
        
        # Görselleştirme için kopyala
        visualize = request.json.get('visualize', False)
        if visualize:
            img_vis = img.copy()
        
        response_data = {"date": "", "price": "", "workplace": ""}
        candidates = []

        print("-" * 30)
        print(f"Toplam {len(results[0].boxes)} bounding box bulundu!")
        
        for result in results:
            for box in result.boxes:
                cls_id = int(box.cls[0])
                label = model.names[cls_id]
                conf = float(box.conf[0])
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                
                print(f"📦 Box: {label} | Güven: {conf:.2%} | Koordinat: ({x1},{y1})-({x2},{y2})")
                
                roi = img[y1:y2, x1:x2]
                
                # Görselleştirme: Bounding box çiz
                if visualize:
                    color_map = {'date': (255, 0, 0), 'price': (0, 255, 0), 'workplace': (0, 0, 255)}
                    color = color_map.get(label, (255, 255, 255))
                    cv2.rectangle(img_vis, (x1, y1), (x2, y2), color, 2)
                    cv2.putText(img_vis, f"{label} {conf:.2f}", (x1, y1-10), 
                               cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
                
                # Çift Okuma
                thresh, gray = preprocess_image(roi)
                
                text = pytesseract.image_to_string(thresh, lang='tur', config='--psm 6').strip()
                if len(text) < 3: 
                    text = pytesseract.image_to_string(gray, lang='tur', config='--psm 6').strip()
                
                if len(text) > 1:
                    candidates.append({"label": label, "text": text})
                    print(f"Ham Veri ({label}): {text}")

        # --- MANTIK (AKILLI ALGILAMA - Label'a bağımsız) ---
        date_found = False
        price_found = False
        workplace_found = False

        # 1. TARİH - Tüm candidate'lerde tarih formatı ara
        for item in candidates:
            if date_found:
                break
            formatted = format_date_turkish(item['text'])
            if formatted:
                response_data['date'] = formatted
                print(f"--> Tarih Bulundu: {formatted} (etiket: {item['label']})")
                date_found = True
                break
        
        # 2. TUTAR - Tüm candidate'lerde fiyat ara (tarih olmayanlar)
        price_candidates = []
        for item in candidates:
            raw = item['text']
            
            # Eğer tarih formatındaysa atla
            if format_date_turkish(raw):
                continue
                
            clean_val = raw.replace('TL', '').replace('TRY', '').strip()
            clean_val = clean_val.replace(',', '.') # Virgül -> Nokta
            numeric_val = "".join([c for c in clean_val if c.isdigit() or c == '.'])
            
            if len(numeric_val) > 0:
                try:
                    val_float = float(numeric_val)
                    
                    # FİLTRE 1: Fiyat 30.000 TL'den büyükse muhtemelen tarihtir
                    if val_float > 30000: continue 
                    
                    # FİLTRE 2: Çok küçük değerler gürültüdür
                    if val_float < 1.0: continue
                    
                    price_candidates.append({'value': numeric_val, 'raw': raw, 'label': item['label']})
                    print(f"--> Fiyat Adayı: {numeric_val} (raw: {raw}, etiket: {item['label']})")
                except:
                    pass

        if price_candidates:
            # İçinde nokta (.) olan (Kuruşlu) değeri tercih et
            best = max(price_candidates, key=lambda x: ('.' in x['value'], len(x['value'])))
            response_data['price'] = best['value']
            print(f"--> Tutar Seçildi: {best['value']}")
            price_found = True

        # 3. ŞİRKET ADI - Tarih ve fiyat olmayanlar
        for item in candidates:
            if workplace_found:
                break
            
            raw = item['text']
            
            # Tarih formatında ise atla
            if format_date_turkish(raw):
                continue
            
            # Sadece sayı ve nokta/virgül içeren metinleri atla (fiyat olabilir)
            text_clean = raw.replace('TL', '').replace('TRY', '').replace(',', '.').strip()
            numeric_only = "".join([c for c in text_clean if c.isdigit() or c == '.'])
            
            # Eğer metnin %80'i sayıysa (fiyat/tarih olabilir) atla
            if len(numeric_only) > 0 and len(numeric_only) / len(text_clean.replace(' ', '')) > 0.8:
                continue
            
            # Çok kısa metinleri atla
            if len(raw.strip()) < 5:
                continue
            
            clean_name = extract_clean_company_name(raw)
            if len(clean_name) > 3:
                response_data['workplace'] = clean_name
                print(f"--> İşyeri Bulundu: {clean_name} (etiket: {item['label']})")
                workplace_found = True
                break

        print("Sonuç:", response_data)
        
        # Görselleştirilmiş görseli döndür
        if visualize:
            _, buffer = cv2.imencode('.jpg', img_vis)
            img_base64 = base64.b64encode(buffer).decode('utf-8')
            response_data['visualized_image'] = img_base64
            print("✅ Görselleştirilmiş görsel eklendi!")
        
        return jsonify(response_data)

    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
