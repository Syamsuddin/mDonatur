# 03 — ROADMAP

Fase berupa **vertical slice** (keputusan 10 Okt 2026, menggantikan urutan lapisan 12a/12b/12c). Setiap slice punya dua bagian:

- **Bagian server** dikerjakan dulu di repo root, mengikuti `../UPDATE_PLAN.md` Fase 12 dan `../CLAUDE.md`. Gerbangnya: `php tests/api.php` LULUS, HTML web 129/129 SAMA, dan semua uji lama LULUS.
- **Bagian klien** dikerjakan sesudahnya, di folder ini.

Slice selesai bila dapat didemokan di emulator terhadap server lokal.

| Slice | Tujuan yang bisa didemokan | Prasyarat server (repo root) | Klien (folder ini) | Fitur |
|---|---|---|---|---|
| S0 | Proyek Flutter berjalan; klien API lulus uji kepatuhan kontrak tanpa server | — | `flutter create`, dependensi, `tema.dart`, `lib/api/*`, `util/*`, `test/api/*`, kerangka 4 tab kosong | dasar |
| S1 | Masuk, keluar, dan pengaturan alamat server | token, `api.php`, aturan `.htaccess`, aksi `login` dan `konfigurasi` | layar Masuk dan Pengaturan, `Sesi`, cek versi, alur 401 | F1, F2 |
| S2 | Input sumbangan dari awal sampai tersimpan, termasuk konfirmasi | logika bersama donasi, aksi `donatur`, `caridonatur`, dan `tambahdonasi`, kirim ulang aman | layar Input Sumbangan dan Cari Donatur | F3, F4 |
| S3 | Tambah donatur | logika bersama donatur, aksi `tambahdonatur` | layar Tambah Donatur | F5 |
| S4 | Input Saya dan ubah nominal | aksi `donasisaya` dan `ubahdonasi` | layar Input Saya dan lembar Ubah | F6 |
| S5 | Rekap | logika bersama rekap, aksi `rekap` | layar Rekap | F7 |
| S6 | Ganti password dan APK debug | aksi `gantipassword` | layar Ganti Password, ikon sementara, `flutter build apk --debug` | F8 |
| S7 | Tampilan arah C "Dasbor Yayasan" di semua layar (keputusan pemilik 10 Okt 2026) | — (tanpa bagian server) | token docs/26 baru di `tema.dart`, huruf di `assets/huruf/`, latar dasbor, tombol utama, kartu, grafik Rekap, gerak, kerangka memuat berkilau | F1–F8 (tampilan) |
| S8 | Admin memilih Note di Input Sumbangan dan menghapus sumbangan dari Input Saya tanpa konfirmasi (permintaan pemilik 12 Okt 2026, K23) | kontrak 0.3.0: `konfigurasi.boleh_atur_note`, `note` di `tambahdonasi`, `boleh_hapus` di `donasisaya`, aksi `hapusdonasi` (`../UPDATE_PLAN.md` Fase 15) | centang Note, jam tebal di kartu hasil Note n, ikon hapus di baris sumbangan, panel galat hapus | F4, F6 (admin) |

Kriteria terima per fitur ada di docs/23_ACCEPTANCE_CRITERIA.md.

[TERBUKA] `../UPDATE_PLAN.md` Fase 12 masih menulis langkah 12a/12b/12c dan layar "Beranda". Penyelarasannya ke S0–S6 dan layar awal Input Sumbangan menunggu permintaan pemilik.
