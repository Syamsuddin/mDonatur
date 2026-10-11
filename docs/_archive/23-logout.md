# Arsip 23 — Keluar memberi tahu server (`logout`, kontrak 0.2.0)

Diminta pemilik 11 Okt 2026 (`../UPDATE_PLAN.md` Fase 14, K20/K21), diterima 11 Okt 2026. Kontrak naik 0.1.0 → 0.2.0 (aksi baru `logout`, §6.11), server lebih dulu, lalu klien (kontrak §9). Bukti: `php tests/api.php` LULUS (bagian "logout"), `flutter test` → `All tests passed!`, `flutter analyze` → `No issues found!`. Hasil lengkap, termasuk demo, di `../UPDATE_PLAN.md` Fase 14.

## Keluar (P7) dan aksi `logout`

- [x] Keluar menghapus token dan state lebih dulu, lalu mengirim satu POST `logout` berisi `{}` dengan `Bearer` token lama, tanpa `Idempotency-Key`. *Uji `test/api/klien_api_test.dart` "logout (kontrak §6.11)" dan `test/layar/masuk_test.dart` "P7 keluar": `server.aksi` = konfigurasi lalu logout, `Authorization` token lama, secure storage tanpa token.*
- [x] Masuk tampil tanpa menunggu jawaban `logout`. *Uji "Masuk tampil tanpa menunggu jawaban logout": jawaban server ditahan, layar Masuk sudah tampil dan token sudah terhapus.*
- [x] Galat `logout` diabaikan: jaringan putus, 500, 401, dan 404 dari server 0.1.0 tidak memunculkan pesan, tidak memicu alur 401 (`padaTidakSah`), dan tidak membuka layar versi (`padaGalatVersi`). Tidak ada kiriman ulang. *Empat uji "logout gagal (…)" dan uji klien 401/versi/jaringan.*
- [x] Server: logout tercatat di log aktivitas (media `mobile`, perangkat "Aplikasi mDonator"); token yang dipakai dicabut (aksi apa pun → 401 `token_tidak_sah`); token lain milik pengguna yang sama tetap berlaku; tanpa token → 401; GET → 405. *`php tests/api.php` bagian "logout".*
