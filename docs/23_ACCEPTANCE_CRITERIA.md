# 23 — ACCEPTANCE_CRITERIA

Kriteria per fitur aktif. Alur rinci: docs/06_BUSINESS_PROCESS.md. Pola antarmuka: docs/26_UI_CONVENTIONS.md. Perintah: docs/11_COMMANDS.md. Gerbang umum: docs/24_DEFINITION_OF_DONE.md. Setiap fitur juga mensyaratkan bagian server slicenya LULUS (`php tests/api.php` di repo root, docs/03_ROADMAP.md).

## Semua layar (diperiksa di setiap slice)

- [ ] Layar ber-data menampilkan empat state sesuai tabel di docs/26_UI_CONVENTIONS.md.
- [ ] Dirender di 360×640 dp dengan `textScaler` 1,3 tanpa overflow.
- [ ] Setiap isian punya label. Nominal dan lencana bintang punya label `Semantics`.
- [ ] Galat ditampilkan sesuai tabel "Tempat tampil" di docs/14_ERROR_HANDLING.md, dan isian tidak hilang.

Verifikasi: `flutter test test/layar/` → `All tests passed!`. Perintah "Cek warna literal", "Cek `print`", dan "Cek alamat tertanam" → keluaran kosong.

F1 dan F2 (S1) sudah diterima: docs/_archive/23-S1-masuk.md. F3 dan F4 (S2): docs/_archive/23-S2-input-sumbangan.md. F5 (S3): docs/_archive/23-S3-tambah-donatur.md. F6 (S4): docs/_archive/23-S4-input-saya.md. F7 (S5): docs/_archive/23-S5-rekap.md.

## F8 Ganti password dan APK debug (S6)

- [ ] 200 → token tersimpan diganti token baru, dan permintaan berikutnya membawa token baru.
- [ ] 422 → `errorText` pada `lama`/`baru`/`ulang` sesuai `rincian`. 409 `fitur_belum_tersedia` → panel berisi `pesan`.
- [ ] `GalatJaringan` setelah mengirim → token dihapus → Masuk dengan pesan P6.3.
- [ ] Perintah "APK debug" menghasilkan `app-debug.apk`, dan alur masuk → input → konfirmasi → rekap berjalan di emulator terhadap server lokal.

Verifikasi: `flutter test test/layar/ganti_password_test.dart` → `All tests passed!`, lalu perintah "APK debug".
