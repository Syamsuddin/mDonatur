# 00 — EXECUTIVE_SUMMARY

**Masalah.** Operator Yayasan Ibnu Atha'illah (Kapuh Madani, Kandangan) mencatat sumbangan lewat aplikasi web Donatur yang dirancang untuk desktop: lebar tata letaknya tetap 1000 px, sehingga di HP sempit dan lambat dipakai. Input datang bergelombang, yaitu Minggu pagi serta Kamis/Jumat malam. Puncaknya 192 transaksi dalam sehari, dan satu operator pernah menginput 132 transaksi dalam sehari.

**Solusi.** mDonator adalah aplikasi Android (Flutter) untuk tugas operator yang paling sering:

- input sumbangan;
- tambah donatur;
- Input Saya, yaitu daftar dan ubah nominal milik sendiri;
- rekap;
- ganti password.

Semua aturan bisnis tetap di server Donatur dan diakses lewat API JSON (`API_CONTRACT.md`), sehingga web dan aplikasi selalu memakai aturan yang sama.

**Metrik sukses** [ASUMSI A1]

1. ≥ 80% sumbangan baru dalam 3 bulan setelah aplikasi dipakai tercatat lewat mDonator, diukur dari porsi baris `"via":"mobile"` di `storage/logs/audit.log` server.
2. Satu input sumbangan (nomor diketik → Simpan) selesai ≤ 15 detik di jaringan seluler, untuk donatur tanpa konfirmasi.

**Pengguna sasaran.** Akun peran operator dan admin aplikasi Donatur (4 akun di produksi). Pemilik produk adalah pengelola aplikasi Donatur.

**Status.** Fase 12 di `../UPDATE_PLAN.md`, belum dikerjakan. Paket ini adalah blueprint sisi klien. Server ada di repo root (`..`) dan diatur oleh `../UPDATE_PLAN.md` Fase 12. Pekerjaan hanya lokal: deploy server dan distribusi APK ditunda pemilik (9 Okt 2026).
