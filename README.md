# Yatırımım App 🚀

Yatırımım App, yatırım portföyünüzdeki TEFAS yatırım fonlarını, BIST hisse senetlerini ve döviz varlıklarınızı tek bir ekrandan, **canlı ve gerçek verilerle** takip etmenizi sağlayan modern ve premium tasarımlı bir finans uygulamasıdır.

## 🌟 Özellikler
- **Gerçek Veri Entegrasyonu:** Fon fiyatları TEFAS üzerinden, hisse senetleri ve kurlar Yahoo Finance üzerinden eşzamanlı olarak çekilir.
- **Glassmorphism Tasarım:** Göz yormayan koyu çinko (zinc) arka planlar üzerine şık, transparan ve oval bileşenlerle (GradientCard) modern bir görünüm sunar.
- **Fon Vakti Hesaplayıcısı:** Hedefinize göre fonların T+1, T+2 vb. valör sürelerini dikkate alarak satış emirlerinizi ne zaman vermeniz gerektiğini hesaplar.
- **Arka Plan Alarmları:** Uygulama kapalı olsa bile belirlediğiniz hedeflerde (Fiyat X'in üstüne çıkarsa / altına inerse) size bildirim yollar.
- **Güvenlik (Çevresel Değişkenler):** API yapılandırmaları güvenli bir şekilde `.env` dosyasıyla yönetilir.
- **Portföy Geçmişi Grafiği:** Günlük toplam bakiyenizi arka planda hesaplayıp kaydederek Özet ekranında gerçekçi bir kar/zarar grafiği çıkarır.

## 📸 Ekran Görüntüleri
*(Buraya daha sonra uygulamanızın ekran görüntülerini ekleyebilirsiniz)*

## 📲 Uygulamayı İndir (APK)
Eğer kaynak kodlarla uğraşmadan uygulamayı doğrudan Android cihazınıza kurup denemek isterseniz, derlenmiş kurulum dosyasına buradan ulaşabilirsiniz:

**[📥 Yatırımım App APK İndir](apk/YatirimimApp.apk)**

*(Not: Dışarıdan APK kurarken telefonunuzda "Bilinmeyen Kaynaklara İzin Ver" seçeneğinin açık olması gerekebilir.)*

## 🛠️ Kurulum Talimatları (Geliştiriciler İçin)

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları takip edin:

1. **Repoyu Klonlayın:**
   ```bash
   git clone https://github.com/KULLANICI_ADINIZ/yatirimim-app.git
   cd yatirimim-app
   ```

2. **Gerekli Paketleri Yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Çevresel Değişkenleri Ayarlayın:**
   Proje kök dizininde bulunan `.env.example` dosyasının ismini `.env` olarak değiştirin (veya yeni bir `.env` dosyası oluşturun) ve içerisine gerekli API uç noktalarını girin:
   ```env
   TEFAS_API_URL=https://www.tefas.gov.tr/api/funds/fonFiyatBilgiGetir
   YAHOO_FINANCE_API_URL=https://query1.finance.yahoo.com/v8/finance/chart/
   ```

4. **Uygulamayı Çalıştırın:**
   ```bash
   flutter run
   ```

## 🏗️ Kullanılan Teknolojiler
- **Flutter & Dart**
- **Hive:** Yerel (Local) veri tabanı ve önbellek mekanizması.
- **Workmanager:** Arka planda çalışan periyodik bildirim işleyicisi (Background Tasks).
- **Flutter Local Notifications:** Telefon bildirimleri ve alarm kurma.
- **FL Chart:** Özet (Dashboard) sayfasındaki dinamik ve yumuşak portföy grafiği.
- **Flutter Dotenv:** API ve anahtarların yönetimi.

## 📜 Lisans
Bu proje [MIT Lisansı](LICENSE) altında sunulmaktadır.
