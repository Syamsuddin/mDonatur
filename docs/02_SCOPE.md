# 02 — SCOPE

## Di dalam scope

- Aplikasi Android Flutter di `mDonator/` untuk fitur F1–F8 (docs/01_PRD.md), bagi peran operator dan admin.
- Konsumsi 10 aksi `API_CONTRACT.md` v0.1.0. Klien API dan model ditulis tangan.
- Uji klien (unit, widget, kepatuhan kontrak, dan integrasi opsional ke server lokal), serta APK debug.
- Tampilan arah C "Dasbor Yayasan" (docs/26_UI_CONVENTIONS.md, S7), termasuk grafik rincian per hari dan per operator di tab Rekap. Grafik ini menggambar jawaban `rekap` yang sama dengan rinciannya (keputusan pemilik 10 Okt 2026).

## Di luar scope

Keputusan K11 dan K15, serta `../UPDATE_PLAN.md` §10.

1. **Hapus donasi** dari mobile. Hapus tetap dilakukan di web.
2. **Input Khusus dan atribut Note.** Note tidak bisa dibuat atau diubah dari mobile. Operator tidak pernah melihat baris Note n.
3. **Ubah atau hapus donatur**, serta Kelola Pengguna.
4. **Daftar sumbangan lengkap**, halaman grafik web (`grafik*`), dan rekap tahunan. Grafik rincian di tab Rekap bukan fitur ini, sebab tidak menambah data maupun aksi.
5. **Mode offline.** Waktu dicap oleh jam server, sehingga tanpa sinyal tidak ada input. Isian tetap di layar sampai dikirim.
6. **Aplikasi untuk donatur:** riwayat pribadi, notifikasi, maupun pembayaran.
7. **Perubahan skema database**, termasuk tabel baru untuk token atau perangkat.
8. **Distribusi APK** (Play Store atau dibagikan ke HP operator) dan langkah apa pun di server produksi.
9. **Kode server.** API, logika bersama, dan uji server dikerjakan di repo root mengikuti `../UPDATE_PLAN.md` Fase 12. Paket ini hanya mencatat prasyaratnya (docs/03_ROADMAP.md).
10. **Fitur Nanti** (N1–N3). Semuanya baru dikerjakan setelah MVP diterima dan pemilik meminta.

Permintaan di luar daftar "di dalam scope" → berhenti dan tanya pemilik.

## Asumsi dan batasan

- Hanya Android (K19). iOS menyusul dari kode yang sama.
- "Hari ini" selalu `konfigurasi.hari_ini` dari server, bukan jam HP.
- Klien terikat pada kontrak versi yang dipin di `docs/_MANIFEST.json` (`split.contract_version`).
- Pekerjaan hanya lokal: server `php -S` dan emulator. Server dan DB produksi tidak disentuh.
