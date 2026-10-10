# 10 — DEV_ENV

## Prasyarat

- Flutter, Android SDK, AVD, dan JDK sesuai docs/09_STACK.md (sudah terpasang di mesin pengembangan).
- Server Donatur di repo root (`..`) bisa dijalankan, dengan DB lokal `kapuhmad_donatur`. DB ini salinan produksi yang berisi data pribadi; petunjuknya di `../CLAUDE.md`.

## Setup sekali

1. **Server (repo root)**
   - `.env` menunjuk DB lokal.
   - Isi `APP_KEY` dengan 64 karakter heksadesimal, mis. hasil `php -r 'echo bin2hex(random_bytes(32)), PHP_EOL;'`. Tanpa `APP_KEY`, API menjawab 503 `api_mati`.
2. **Akun uji (repo root)**
   - `php tests/akun-uji.php` membuat `uji_operator` dan `uji_admin`. Password-nya di `../tests/.akun-uji`.
   - Password ini **jangan** disalin ke berkas mana pun di `mDonator/`. Uji integrasi membacanya dari `--dart-define`.
3. **Proyek Flutter (slice S0)**
   - Jalankan perintah "Buat proyek" lalu "Dependensi" di docs/11_COMMANDS.md.
   - Atur manifest Android sesuai docs/21_SECURITY_RULES.md (bagian Transport dan Perangkat).

## Harian

Jalankan berurutan: server dev di repo root → emulator → `adb reverse tcp:8000 tcp:8000` → `flutter run`. Semua perintahnya di docs/11_COMMANDS.md.

## Variabel build (`--dart-define`)

| Nama | Isi | Nilai |
|---|---|---|
| `SERVER_URL` | Alamat dasar server = `APP_URL` server, tanpa garis miring akhir | emulator dan HP fisik lewat USB `http://localhost:8000`, sama dengan `APP_URL` di `../.env` (`localhost` di perangkat diteruskan ke mesin oleh `adb reverse tcp:8000 tcp:8000`) · HP fisik di LAN `http://<IP-mesin>:8000` (server mendengar `0.0.0.0`) · APK debug dan rilis `https://donatur.kapuhmadani.com` (APK debug sejak S6, permintaan pemilik 10 Okt 2026; API baru ada di sana setelah server Fase 12 dideploy, dan deploy ditunda). `flutter run` dan uji integrasi tetap memakai server lokal, karena keduanya menulis data |
| `UJI_USERNAME`, `UJI_PASSWORD` | Akun untuk uji integrasi saja | dari `../tests/.akun-uji` |

Alamat yang disimpan di Pengaturan menang atas `SERVER_URL` (docs/06_BUSINESS_PROCESS.md P0).

## Kunci `.env` server yang dipakai API

Hanya nama; nilainya di `../.env`:

- `APP_URL`, `APP_TIMEZONE`
- `APP_KEY`, `API_TOKEN_HOURS`
- `LOGIN_MAX_ATTEMPTS`, `LOGIN_LOCK_MINUTES`
- `NOMINAL_KONFIRMASI`
