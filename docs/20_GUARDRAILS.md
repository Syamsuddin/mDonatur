# 20 — GUARDRAILS

JANGAN:

1. **Menyalin aturan bisnis ke Dart.** Ini mencakup K5, K6, K9, Note, bintang, saran, rekap, dan validasi isi. Klien menampilkan hasil server. Satu-satunya pengecualian tercatat adalah konfirmasi lokal nominal < Rp 1.000 (docs/06_BUSINESS_PROCESS.md P2.4).
2. **Memakai aksi, field, atau header di luar `API_CONTRACT.md`,** atau menambah aksi tanpa mengubah kontrak lebih dulu (docs/27_API_CONTRACT.md).
3. **Mengirim `id_user`, `note`, `tanggal`, atau `waktu`** dari klien.
4. **Menyimpan data donatur atau password di perangkat,** baik di berkas, cache, `shared_preferences`, maupun log (docs/21_SECURITY_RULES.md).
5. **Memakai `print()`,** atau mencetak token, password, isi permintaan, atau data donatur ke log.
6. **Menambah paket Dart atau plugin** di luar docs/09_STACK.md tanpa gerbang docs/22_CHANGE_POLICY.md.
7. **Memakai jam HP untuk "hari ini".** Selalu pakai `konfigurasi.hari_ini`.
8. **Mengulang POST otomatis,** atau membuat kunci kirim ulang baru saat Kirim ulang.
9. **Menanam alamat server di `lib/`,** atau mengizinkan `http://` dan cleartext di build rilis.
10. **Menulis warna, ukuran, huruf, gradien, gerak, atau ikon di luar token docs/26_UI_CONVENTIONS.md,** atau menjumlah dan menyaring data di Dart untuk grafik.
11. **Mengubah dari tugas klien:** markup atau CSS web, skema DB, atau kode server. Pekerjaan server mengikuti `../UPDATE_PLAN.md` Fase 12 di repo root.
12. **Menghubungkan aplikasi atau uji ke server produksi atau DB non-lokal.** Uji integrasi hanya boleh menulis ke donatur `UJI-MOBILE …` (docs/13_TESTING.md).
13. **Menyalin password akun uji** (`../tests/.akun-uji`) ke berkas di `mDonator/`.
14. **Commit tanpa diminta pemilik,** atau meng-commit kunci tanda tangan APK (`*.jks`, `*.keystore`, `key.properties`).
