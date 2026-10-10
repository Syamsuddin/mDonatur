# Arsip 23 — Logo yayasan (permintaan pemilik)

Diterima 10 Okt 2026. Pemilik memberikan logo Yayasan Ibnu Atha'illah (PNG 224×225, bagian putih tembus pandang) dan menyetujui tiga tempat: ikon peluncur, kepala layar Masuk, dan layar memuat awal. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/masuk_test.dart` → `All tests passed!`, suite penuh dan `flutter analyze` bersih, ditambah demo agen di emulator Pixel_5 Android 13 (layar pembuka dan Masuk; layar memuat dengan token hanya lewat uji, karena pemilik menghentikan demo masuk) (`../UPDATE_PLAN.md` "Hasil uji 12c logo yayasan"). Tidak ada perubahan server.

## Logo yayasan

- [x] Ikon peluncur memakai logo di atas latar putih: ikon adaptif untuk API 26+ (logo 66 dp di kanvas 108 dp), PNG untuk API < 26 (logo 40 dp di atas lingkaran putih 46 dp). Menutup [TERBUKA T9] lama di docs/26. *Demo: ikon tampil di layar pembuka sistem Android 13 di emulator; APK per ABI memuat semua PNG ikon.*
- [x] Layar pembuka Android < 12 (`launch_background.xml`, `drawable` dan `drawable-v21`): logo 80 dp di tengah latar putih, juga di mode gelap. Android 12+ memakai layar pembuka sistem dengan ikon peluncur.
- [x] Layar memuat awal (P0, selama token dibaca dan `konfigurasi` dipanggil): logo 80 dp tepat di tengah layar, tanpa AppBar, label `Semantics` "Yayasan Ibnu Atha'illah"; setelah `konfigurasi` 200 → tab Input. *Uji "memuat: logo yayasan di tengah layar tanpa AppBar, lalu tab Input" (360×640 dp × 1,3: kotak logo = 80×80 di (180, 320)).*
- [x] Kepala Masuk: logo 56 dp di atas alas lingkaran putih 64 dp, sebaris dengan nama yayasan dan "mDonator" serta ikon Pengaturan; tombol Masuk tetap terlihat di 360×640 dp × 1,3, juga saat panel pesan P6.3 tampil. *Uji P1 "password benar …" (lebar logo 64, logo di kiri nama, tanpa luapan) dan seluruh uji yang mengetuk Masuk di layar kecil, termasuk `ganti_password_test.dart` P6.3.*

Sisa: berkas logo hanya 224 px, jadi ikon terbesar dan layar pembuka memperbesarnya sampai 1,4×. Bila berkas asli ≥ 1024 px tersedia, ganti `assets/logo_yayasan.png` lalu buat ulang PNG Android ([TERBUKA] di docs/26_UI_CONVENTIONS.md, Logo).
