# CLAUDE.md

File ini selalu aktif. Untuk hal di luar ini → buka INDEX.md.

## Proyek
mDonator — aplikasi Android (Flutter) untuk operator aplikasi Donatur: input sumbangan, tambah donatur, Input Saya, dan rekap. Aturan bisnisnya di server lewat `API_CONTRACT.md`. Detail: docs/00_EXECUTIVE_SUMMARY.md. Scope: docs/02_SCOPE.md. Kode di folder ini = paket ini; berkas di luar `mDonator/` mengikuti `../CLAUDE.md` dan `../UPDATE_PLAN.md`.

## Prinsip kerja agen (non-negotiable)
1. Friksi sebanding irreversibilitas.
2. Lapisan deterministik (validasi, constraint, tes) di bawah penalaran.
3. Human-in-the-loop untuk high-stakes (kontrak, dependensi, data, keamanan, rilis).
4. Jangan refactor keputusan yang disengaja diam-diam.
5. Hormati scope (docs/02). Out-of-scope → berhenti & tanya.

## Stack  (sumber: docs/09)
Flutter 3.47.5 / Dart 3.13.4, Android; `http`, `flutter_secure_storage`, `intl`, `flutter_localizations`; tampilan `fl_chart`, `flutter_animate`, `skeletonizer`; huruf Plus Jakarta Sans + Outfit dibundel; state `ChangeNotifier`. Terlarang: WebView, paket state/router, dio/codegen, telemetri, pustaka UI lain, `google_fonts`, `http://` di rilis, paket baru tanpa gerbang 22.

## Struktur & konvensi  (sumber: docs/12)
- `lib/layar` → `lib/state` (`*Notifier`) → `lib/api/` (HTTP hanya di sini; nama field JSON hanya di `model.dart`).
- Warna/ukuran/jarak hanya di `lib/tema.dart`; format rupiah/tanggal hanya di `lib/util/`; kata domain bahasa Indonesia sesuai kontrak.

## Perintah penting  (sumber: docs/11)
- `flutter analyze` → `No issues found!` · `flutter test` → `All tests passed!`
- `adb reverse tcp:8000 tcp:8000` lalu `flutter run -d emulator-5554 --dart-define=SERVER_URL=http://localhost:8000` (server dari `..`: `php -S localhost:8000 -t public public/index.php`)
- Migrasi: tidak ada, skema DB ⚠️ tidak boleh berubah · prasyarat server per slice: `php tests/api.php` LULUS di `..`

## Guardrail inti  (penuh: docs/20, 21, 22)
- JANGAN menyalin aturan K5/K6/K9/Note/bintang/saran/rekap ke Dart; tampilkan hasil server.
- JANGAN menyimpan data donatur/password di perangkat atau mencetak token/PII ke log.
- JANGAN mengulang POST otomatis; Kirim ulang = kunci sama, Simpan baru = kunci baru.
- JANGAN memakai jam HP untuk "hari ini"; pakai `konfigurasi.hari_ini`.
- JANGAN menyentuh server/DB produksi, menulis ke DB non-lokal, atau commit tanpa diminta.

## Antarmuka  (sumber: docs/26_UI_CONVENTIONS.md)
Arah C "Dasbor Yayasan": kepala gradien hijau berpola bintang, angka kuning, lembar berkartu, grafik Rekap, gerak singkat; layar awal Input Sumbangan, 4 tab. Larangan: nilai di luar token, `ColorScheme.fromSeed`, gradien di luar token, emoji, gerak yang mengabaikan Hapus animasi, grafik yang menjumlah di Dart.

## Kontrak API  (sumber: docs/27_API_CONTRACT.md + API_CONTRACT.md)
Peran paket: frontend · Kontrak: `API_CONTRACT.md` v0.2.0 (tanpa openapi.yaml). KONTRAK menang — aksi/payload hanya dari sana; ubah kontrak = gerbang manusia + bump versi.

## Alur per-task  (penuh: docs/17, 19)
Baca INDEX.md → muat dokumen relevan → konfirmasi scope → vertical slice → tes (docs/13) → DoD (docs/24).

## Definisi selesai (ringkas; penuh: docs/24)
Kriteria docs/23 terpenuhi, analyze + test bersih, cek grep kosong, uji server LULUS, demo emulator, `../UPDATE_PLAN.md` "Hasil uji" diperbarui.

## Untuk apa pun di luar ini → INDEX.md
