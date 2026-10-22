# 23 — ACCEPTANCE_CRITERIA

Kriteria per fitur aktif. Alur rinci: docs/06_BUSINESS_PROCESS.md. Pola antarmuka: docs/26_UI_CONVENTIONS.md. Perintah: docs/11_COMMANDS.md. Gerbang umum: docs/24_DEFINITION_OF_DONE.md. Setiap fitur juga mensyaratkan bagian server slicenya LULUS (`php tests/api.php` di repo root, docs/03_ROADMAP.md).

## Semua layar (diperiksa di setiap slice)

- [ ] Layar ber-data menampilkan empat state sesuai tabel di docs/26_UI_CONVENTIONS.md.
- [ ] Dirender di 360×640 dp dengan `textScaler` 1,3 tanpa overflow.
- [ ] Setiap isian punya label. Nominal dan lencana bintang punya label `Semantics`.
- [ ] Galat ditampilkan sesuai tabel "Tempat tampil" di docs/14_ERROR_HANDLING.md, dan isian tidak hilang.

Verifikasi: `flutter test test/layar/` → `All tests passed!`. Perintah "Cek warna literal", "Cek gradien dan huruf", "Cek `print`", dan "Cek alamat tertanam" → keluaran kosong.

F1 dan F2 (S1) sudah diterima: docs/_archive/23-S1-masuk.md. F3 dan F4 (S2): docs/_archive/23-S2-input-sumbangan.md. F5 (S3): docs/_archive/23-S3-tambah-donatur.md. F6 (S4): docs/_archive/23-S4-input-saya.md. F7 (S5): docs/_archive/23-S5-rekap.md. F8 (S6): docs/_archive/23-S6-ganti-password.md. Logo yayasan (permintaan pemilik): docs/_archive/23-logo-yayasan.md. Tampilan arah C (S7): docs/_archive/23-S7-desain-dasbor.md. Keluar memberi tahu server (kontrak 0.2.0, permintaan pemilik): docs/_archive/23-logout.md.

Fitur aktif: S8 di bawah. Fitur baru menambah bloknya di sini.

## S8 — Admin: Note dan hapus sumbangan (kontrak 0.3.0, K23)

Diminta pemilik 12 Okt 2026 (`../UPDATE_PLAN.md` Fase 15). Kontrak 0.2.0 → 0.3.0 disetujui pemilik; server lebih dulu, lalu klien (kontrak §9).

### Note di Input Sumbangan (F4, P2.3a)

- [x] Centang Note hanya tampil bila `konfigurasi.boleh_atur_note: true`; operator, dan admin yang tidak dibolehkan server, tidak melihatnya. *Uji `test/layar/input_sumbangan_test.dart` grup "Note (admin, K23)": dua uji pertama.*
- [x] Bawaan tercentang (y) → isi `tambahdonasi` sama persis dengan sebelum 0.3.0 (tanpa `note`); dikosongkan → `note: "n"`; setelah tersimpan centang kembali y; jam kartu hasil tebal bila `note_n`. *Uji "bawaan tercentang (y) …".*
- [x] Note n ikut pada "Ya, simpan" setelah 409 (kunci baru); centang terkunci selama menyimpan; mengubah centang setelah galat jaringan menghapus Kirim ulang. *Dua uji berikutnya di grup yang sama.*
- [x] Muat satu layar Pixel 5 untuk admin seperti operator, dan tanpa luapan di 360×640 dp × 1,3 dengan `errorText`. *`test/layar/input_sumbangan_muat_test.dart` (operator dan admin) dan uji 360 di grup Note.*

### Hapus di Input Saya (F6, P4.6)

- [x] Ikon hapus (`delete_outline`, `teksBahaya`, target ≥ 48 dp) hanya pada baris `boleh_hapus: true`; baris operator tanpa ikon hapus. *Uji `test/layar/input_saya_test.dart` grup "hapus (admin, K23)" dan uji "boleh_ubah false …".*
- [x] Ketuk → satu POST `hapusdonasi` `{id}` dengan kunci UUID, tanpa dialog dan tanpa membuka lembar Ubah; daftar, total, dan strip tab Input dimuat ulang. *Uji "ketuk → hapusdonasi langsung tanpa dialog …".*
- [x] Selama menghapus: indikator di baris itu, hapus lain nonaktif, baris tetap sampai daftar baru tiba. *Uji "selama menghapus …".*
- [x] Galat: jaringan → Kirim ulang (kunci dan isi sama); 500 → Coba lagi (kunci sama); 403 → pesan tanpa tombol, ketuk lagi memakai kunci baru; 404 → pesan dan daftar dimuat ulang; panel hilang saat daftar dimuat ulang. *Lima uji galat di grup yang sama.*

### Server dan kontrak

- [x] `konfigurasi.boleh_atur_note` (admin true, operator false); `note` dari operator diabaikan (juga nilai tidak sah); dari admin `"n"` → Note n bertanda `note_n` dan tidak masuk `ringkasan_hari_ini`, nilai selain `"y"`/`"n"` → 422 `rincian.note`; `boleh_hapus` (admin true, operator false). *`php tests/api.php` bagian "konfigurasi", "Note (K23)", dan "donasisaya".*
- [x] `hapusdonasi`: tanpa token 401, GET 405, tanpa kunci 400, operator 403 (juga untuk id yang tidak ada), id tidak sah 404, admin menghapus sumbangan siapa pun dari tanggal mana pun, kunci sama diputar ulang, kunci sama isi lain 409, sudah terhapus 404; tidak masuk `audit.log` maupun log aktivitas. *`php tests/api.php` bagian "hapusdonasi" dan "Audit dan log"; sidik data akhir sama dengan awal.*
- [x] `versiKontrak`, `X-Api-Versi`, `konfigurasi.versi_api`, dan manifest = 0.3.0; tabel aksi §6 = enum `Aksi`. *`test/api/kontrak_test.dart`, `test/api/klien_api_test.dart` grup "Note di tambahdonasi dan hapusdonasi".*
- [ ] Demo emulator terhadap server lokal: admin menginput sumbangan Note n untuk donatur `UJI-MOBILE …`, lalu menghapusnya dari Input Saya.
