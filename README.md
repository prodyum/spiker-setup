# Spiker Kurulum Paketleri

Bu repo, Spiker uygulamasının herkese açık Windows kurulum paketini yayınlar.

Spiker, Windows için Türkçe SAPI5 sesidir. Kurulumdan sonra ekran okuyucular ve SAPI5 destekleyen uygulamalar içinde `Spiker` sesini seçerek kullanabilirsiniz.

## Hızlı Kurulum

En kolay yöntem:

1. `Windows + R` tuşlarına basın.
2. Açılan Çalıştır penceresine şu komutu yapıştırın.
3. Enter'a basın ve açılan Spiker kurulum penceresini takip edin.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$h=@{'User-Agent'='spiker-install'}; $sha=(irm -UseBasicParsing -Headers $h 'https://api.github.com/repos/hasan-ozdemir/spiker-packages/branches/main').commit.sha; irm -UseBasicParsing -Headers $h ('https://raw.githubusercontent.com/hasan-ozdemir/spiker-packages/' + $sha + '/spiker-install.ps1') | iex"
```

Bu komut, önce GitHub API üzerinden `main` dalının son commit SHA'sını alır, sonra `spiker-install.ps1` scriptini o SHA üzerinden indirip çalıştırır. Bu yöntem GitHub raw branch cache'ine takılmadan son push edilen scripti kullanmak içindir. Script Windows PowerShell 5.1 ve yönetici izni gerektirir; gerekirse kendini bu oturumda yeniden başlatır ve Windows izin penceresini açar. İzin verdikten sonra en son yayınlanan sıkıştırılmış `spiker-setup.exe` dosyası Windows geçici klasöründeki `spiker-setup` klasörüne indirilir.

Kurulum paketi arada 7-Zip penceresi göstermeden sessizce açılır ve Spiker kurulum asistanı başlar. Kurulum asistanı açıldığında PowerShell penceresi otomatik gizlenir. Kurulum asistanı kapandığında geçici `spiker-setup` klasörü içindeki dosyalarla birlikte silinir.

## Elle İndirme

Komut kullanmak istemezseniz:

1. Bu repodaki Releases bölümünü açın.
2. En son release içindeki `spiker-setup.exe` dosyasını indirin.
3. Dosyayı çalıştırın ve kurulum penceresini takip edin.

Güncel release:

https://github.com/hasan-ozdemir/spiker-packages/releases/latest

## Kurulumdan Sonra

Kurulum tamamlandığında Spiker, Windows'a SAPI5 sesi olarak eklenir. Kullandığınız ekran okuyucu veya konuşma uygulamasının ses ayarlarından `Spiker` sesini seçebilirsiniz.

Kurulum paketi `C:\prodyum\spiker` altına kurulur. Mevcut ayarlar korunur; güncelleme sırasında `spiker.ini` ve `logs` klasörü silinmez.

## Güvenlik Notu

`spiker-install.ps1` yalnızca bu repodaki en son release içindeki `spiker-setup.exe` dosyasını indirir. İndirme HTTPS üzerinden yapılır; GitHub release asset digest bilgisi varsa SHA256 doğrulaması da yapılır. Script, sıkıştırılmış dış paketin değil gerçek Spiker kurulum asistanının çıkış sonucunu kontrol eder; kullanıcı isteğiyle kapatma normal kabul edilir, gerçek kurulum hataları bildirilir. İndirme tamamlanana kadar geçici `.download` dosyası kullanılır; kurulum asistanı kapandıktan sonra geçici kurulum dosyaları silinir.

## Yayın Akışı

Özel `hasan-ozdemir/spiker` reposunda `main` dalına yapılan her push yeni `spiker-setup.exe` paketini üretir. Bu public repo sadece en son kurulumu yayınlar; yeni paket yayınlandıktan sonra eski release'ler ve tag'ler temizlenir.
