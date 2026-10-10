# Arsip 23 — S6 Ganti password dan APK debug (F8)

Diterima 10 Okt 2026. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/ganti_password_test.dart` → `All tests passed!` (10 uji; suite penuh 268 uji), `flutter analyze` → `No issues found!`, ditambah demo agen di emulator Pixel_5 Android 13 terhadap server lokal (`../UPDATE_PLAN.md` "Hasil uji 12c slice S6"). Bagian server slice ini (aksi `gantipassword`) selesai di 12b dan tidak diubah; `php tests/api.php` LULUS 158 cek pada percobaan pertama.

## F8 Ganti password dan APK debug (S6)

- [x] 200 → token tersimpan diganti token baru, dan permintaan berikutnya membawa token baru. *Uji "200 → token tersimpan diganti …": POST `{lama, baru, ulang}` dengan `Bearer` token lama dan tanpa `Idempotency-Key` (kontrak §6.10); secure storage berisi tepat token baru, kedaluwarsa baru, dan username terakhir; pesan "Password berhasil diganti." (`teksSukses`) dan ketiga isian kosong; setelah kembali, permintaan berikutnya membawa `Bearer` token baru. Demo: ganti ke password sementara lalu kembali ke semula; ganti kedua hanya berhasil karena membawa token baru, dan aplikasi yang dibuka ulang masuk langsung dengan token itu.*
- [x] 422 → `errorText` pada `lama`/`baru`/`ulang` sesuai `rincian`. 409 `fitur_belum_tersedia` → panel berisi `pesan`. *Uji "422 → errorText …" untuk ketiga kunci (galat sebelumnya hilang, token tetap, isian dikosongkan sesuai docs/21); kunci tanpa isian → panel; uji 409 → panel `teksBahaya` tanpa Coba lagi, token tetap. Demo: password baru "pendek" → "Password baru minimal 8 karakter." di bawah Password Baru.*
- [x] `GalatJaringan` setelah mengirim → token dihapus → Masuk dengan pesan P6.3. *Uji "P6.3 putus setelah mengirim …": satu kiriman tanpa kirim ulang; token dan kedaluwarsa terhapus, username terakhir tetap; Masuk dengan pesan P6.3 didorong di atas kerangka seperti alur 401 dan layar Ganti Password ditutup; setelah masuk, kembali ke tab dengan isian tab utuh.*
- [x] Perintah "APK debug" menghasilkan `app-debug.apk` beralamat bawaan `https://donatur.kapuhmadani.com`. Setelah alamat di Pengaturan diubah ke `http://localhost:8000` (sebelum masuk), alur masuk → input → konfirmasi → rekap berjalan di emulator terhadap server lokal. *`kernel_blob.bin` APK memuat alamat produksi dan tidak memuat `localhost:8000`; Pengaturan pada data aplikasi bersih menampilkan alamat produksi. Tidak ada permintaan ke produksi: tanpa token aplikasi tidak memanggil server sebelum masuk, dan alamat diganti sebelum masuk. Demo: masuk `uji_operator` → donatur 1234 Rp 50.000 → donatur yang sama lagi → dialog K5 "sudah tercatat menyumbang 1 kali hari ini" → Ya, simpan → Rekap Hari Rp 100.000, 2 transaksi, 1 donatur.*

Cabang lain P6 yang juga teruji: memuat (Simpan nonaktif + indikator, isian terkunci); 429 `login_terkunci` → panel berisi pesan server; 500 → pesan umum + Coba lagi, isian tetap dan Coba lagi mengirim isi yang sama; 401 → Masuk didorong, setelah masuk kembali ke Ganti Password yang kosong. Menu ⋮ berurutan Ganti Password, Pengaturan, Keluar (`test/layar/kerangka_test.dart`).

## Semua layar (bagian S6)

- [x] Empat state Ganti Password: isian / Simpan nonaktif + indikator / `errorText` atau panel / pesan sukses.
- [x] 360×640 dp, `textScaler` 1,3, tanpa luapan: layar kosong, sukses, tiga `errorText`, dan panel 409.
- [x] Setiap isian berlabel (Password Lama, Password Baru, Ulangi Password Baru), tersamar, tanpa saran keyboard dan tanpa autofill.
- [x] Galat tampil sesuai docs/14_ERROR_HANDLING.md "Tempat tampil".

Ikon peluncur sementara (docs/26): "mD" Roboto Bold putih di atas `primer`, ikon adaptif (latar warna + depan PNG 108 dp) untuk API 26+ dan PNG persegi radius 8 dp untuk API 24–25; tampil di layar pembuka Android 13.

Uji mutasi: layar Ganti Password yang tidak menutup dirinya setelah putus koneksi membuat uji P6.3 merah.
