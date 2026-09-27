# MODEL PERFORMANS RAPORU

## Görselleştirme Sonuçları

### Test Edilen Görseller:
- ✅ 5 validation görseli
- ✅ 5 train görseli

### Güven Skorları (Ortalamalar):
**Validation Set:**
- Workplace: %70-84 arası
- Price: %35-83 arası  
- Date: %10-83 arası

**Train Set:**
- Workplace: %71-83 arası
- Price: %23-86 arası
- Date: %52-85 arası

## Renk Kodları:
- 🔴 Kırmızı = date
- 🟢 Yeşil = price
- 🔵 Mavi = workplace
- 🟡 Sarı = Ground Truth (gerçek etiket)

## Önemli Metrikler:

### Eğitim Grafikleri (runs/detect/fatura_modelim2/):
1. **results.png** - Genel eğitim metrikleri (loss, mAP, precision, recall)
2. **confusion_matrix.png** - Sınıf karışıklık matrisi
3. **BoxPR_curve.png** - Precision-Recall eğrisi
4. **BoxF1_curve.png** - F1 skoru eğrisi

### Label Düzeltme Kontrolü:
✅ Etiketler normalize edildi:
  - Task 1 (0-107): date(0), price(1), workplace(2)
  - Task 2 (108-215): price(0)→1, date(1)→0, workplace(2)→2

### Data Augmentation:
✅ Fiş OCR'a özel augmentation aktif:
  - ±3° rotasyon
  - %5 translate
  - %15 scale
  - Işık/renk varyasyonları
  - Random erasing (%20)

## Kontrol Edilmesi Gerekenler:

1. **Görsel Sonuçları İnceleyin:**
   - visualization_results/ klasöründeki görsellere bakın
   - Sarı (ground truth) ve renkli (prediction) box'ları karşılaştırın

2. **Confusion Matrix:**
   - runs/detect/fatura_modelim2/confusion_matrix.png
   - Hangi sınıfların karıştırıldığını gösterir

3. **mAP Skorları:**
   - runs/detect/fatura_modelim2/results.png
   - mAP50 ve mAP50-95 değerlerine bakın
