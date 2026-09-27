import os
import glob

def fix_label_file(filepath):
    """
    2. task'ten gelen label dosyasını düzeltir.
    Eski sıralama: 0=price, 1=date, 2=workplace
    Yeni sıralama: 0=date, 1=price, 2=workplace
    
    Dönüşüm:
    0 -> 1 (price)
    1 -> 0 (date)
    2 -> 2 (workplace, değişmez)
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed_lines = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        parts = line.split()
        if len(parts) < 5:
            continue
        
        class_id = int(parts[0])
        
        # Sınıf ID'sini dönüştür
        if class_id == 0:
            new_class_id = 1  # price
        elif class_id == 1:
            new_class_id = 0  # date
        else:  # class_id == 2
            new_class_id = 2  # workplace
        
        # Yeni satırı oluştur
        fixed_line = f"{new_class_id} {parts[1]} {parts[2]} {parts[3]} {parts[4]}\n"
        fixed_lines.append(fixed_line)
    
    # Dosyayı yaz
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)
    
    print(f"Düzeltildi: {os.path.basename(filepath)}")


def main():
    dataset_path = r"C:\Users\HP\Desktop\Bitirme Projesi\python_backend\dataset"
    
    # Train klasöründeki dosyaları işle
    print("Train klasörü işleniyor...")
    train_labels_path = os.path.join(dataset_path, "train", "labels")
    train_files = sorted(glob.glob(os.path.join(train_labels_path, "*.txt")))
    
    print(f"Toplam train dosyası: {len(train_files)}")
    print(f"İlk 107 dosya atlanacak (1. task - zaten doğru, index 0-106)")
    print(f"Sonraki 108 dosya düzeltilecek (2. task, index 107-214)\n")
    
    # 2. Task: index 107-214 arası dosyaları düzelt
    for i in range(107, min(215, len(train_files))):
        fix_label_file(train_files[i])
    
    print(f"\nTrain klasöründe {min(215, len(train_files)) - 107} dosya düzeltildi.\n")
    
    # Val klasöründeki dosyaları işle
    print("Val klasörü işleniyor...")
    val_labels_path = os.path.join(dataset_path, "val", "labels")
    val_files = sorted(glob.glob(os.path.join(val_labels_path, "*.txt")))
    
    print(f"Toplam val dosyası: {len(val_files)}")
    print(f"İlk 26 dosya atlanacak (1. task - zaten doğru, index 0-25)")
    print(f"Sonraki 25 dosya düzeltilecek (2. task, index 26-50)\n")
    
    # 2. Task: index 26-50 arası dosyaları düzelt
    for i in range(26, min(51, len(val_files))):
        fix_label_file(val_files[i])
    
    print(f"\nVal klasöründe {min(51, len(val_files)) - 26} dosya düzeltildi.")
    print("\n✅ Tüm label dosyaları başarıyla normalize edildi!")
    print("Artık tüm etiketler aynı sıralamayı kullanıyor:")
    print("  0: date")
    print("  1: price")
    print("  2: workplace")


if __name__ == "__main__":
    main()
