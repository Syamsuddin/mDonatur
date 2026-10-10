# 11 — COMMANDS

Perintah `flutter` dan `bash scripts/…` dijalankan dari `mDonator/`. Perintah bertanda **(root)** dijalankan dari repo root (`cd ..`).

| Tujuan | Perintah | Lulus bila |
|---|---|---|
| Server dev **(root)** | `php -S localhost:8000 -t public public/index.php` | — |
| Server untuk HP di LAN **(root)** | `php -S 0.0.0.0:8000 -t public public/index.php` | — |
| Akun uji **(root)** | `php tests/akun-uji.php` | — |
| Uji API server **(root)**, lahir di S1 | `php tests/api.php` | mencetak LULUS |
| Regresi web **(root)** | rangkaian di `../CLAUDE.md` bagian "Git and tests" | semua LULUS, HTML 129/129 SAMA |
| Sidik data **(root)** | `php bin/sidik-data.php > tests/_out/sidik-<label>.txt`, lalu `diff` dua label | tanpa selisih |
| Buat proyek Flutter (S0, sekali) | `flutter create --project-name mdonator --org com.kapuhmadani --platforms android .` | lalu hapus `test/widget_test.dart` contoh |
| Dependensi (S0, sekali) | `flutter pub add http flutter_secure_storage intl "flutter_localizations@{sdk: flutter}" "dev:integration_test@{sdk: flutter}"` | `pubspec.lock` terisi |
| Dependensi tampilan (S7, sekali) | `flutter pub add "fl_chart:^1.2.0" "flutter_animate:^4.5.2" "skeletonizer:^3.0.0"` | `pubspec.lock` memuat ketiganya |
| Ambil dependensi | `flutter pub get` | — |
| Analisis statik | `flutter analyze` | `No issues found!` |
| Semua uji | `flutter test` | `All tests passed!` |
| Satu berkas uji | `flutter test test/api/klien_api_test.dart` | `All tests passed!` |
| Emulator | `~/Library/Android/sdk/emulator/emulator -avd Pixel_5-Android_13` | — |
| Teruskan port server ke emulator (ulang setiap emulator menyala) | `adb reverse tcp:8000 tcp:8000` | `adb reverse --list` memuat `tcp:8000` |
| Jalankan | `flutter run -d emulator-5554 --dart-define=SERVER_URL=http://localhost:8000` | — |
| Uji integrasi (opsional) | `flutter test integration_test -d emulator-5554 --dart-define=SERVER_URL=http://localhost:8000 --dart-define=UJI_USERNAME=uji_operator --dart-define=UJI_PASSWORD=<dari ../tests/.akun-uji>` | `All tests passed!` |
| ⚠️ Bersihkan data uji integrasi (hanya DB lokal) | `mysql -u root -p kapuhmad_donatur -e "DELETE s FROM donasi s JOIN donator d ON d.Id = s.IdDonator WHERE d.Nama LIKE 'UJI-MOBILE%'; DELETE FROM donator WHERE Nama LIKE 'UJI-MOBILE%';"` | sidik data sama dengan sebelum uji |
| APK debug (alamat bawaan server produksi, permintaan pemilik 10 Okt 2026) | `flutter build apk --debug --dart-define=SERVER_URL=https://donatur.kapuhmadani.com` | `build/app/outputs/flutter-apk/app-debug.apk` ada. Untuk demo terhadap server lokal, ubah alamat di Pengaturan ke `http://localhost:8000` **sebelum** masuk |
| Cek warna literal | `grep -rn "Color(0x" lib --include=*.dart \| grep -v "^lib/tema.dart"` | keluaran kosong |
| Cek gradien dan huruf | `grep -rnE "LinearGradient\(\|fontFamily:\|TextStyle\(" lib --include=*.dart \| grep -v "^lib/tema.dart"` | keluaran kosong |
| Cek `print` | `grep -rnE "(^\|[^a-zA-Z_])print\(" lib --include=*.dart` | keluaran kosong |
| Cek alamat tertanam | `grep -rnE "https?://" lib --include=*.dart` | keluaran kosong |
| Validasi blueprint | `bash scripts/validate.sh` | `FAIL=0` |
| Meteran token (opsional) | `python3 scripts/token_ledger.py log --route "<rute>"` · rekap: `python3 scripts/token_ledger.py report` | — |

**Migrasi:** tidak ada di klien. Skema DB tidak boleh berubah (docs/02_SCOPE.md).
