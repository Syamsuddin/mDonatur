# Arsip 23 — S5 Rekap (F7)

Diterima 10 Okt 2026. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/rekap_test.dart` → `All tests passed!` (14 uji; suite penuh 258 uji), ditambah demo agen di emulator Pixel_5 Android 13 terhadap server lokal (`../UPDATE_PLAN.md` "Hasil uji 12c slice S5"). Bagian server slice ini (aksi `rekap`) selesai di 12b dan tidak diubah. Percobaan pertama `php tests/api.php` GAGAL 1 dari 158 cek ("sumbangan pertama tersimpan bersama donaturnya", bagian `tambahdonatur`, bukan `rekap`); percobaan kedua tanpa perubahan apa pun LULUS 158 cek. Audit untuk percobaan pertama mencatat donatur 7833 dengan tepat satu sumbangan Rp 25.000 oleh `uji_operator`, Note y, dan sidik data sama di awal dan akhir. Penyebab cek itu kadang gagal belum diketahui.

## F7 Rekap (S5)

- [x] Bawaan: `periode=hari`, `cakupan=saya`, tanggal `hari_ini`. Mengganti segmen memanggil `rekap` dengan tanggal yang sama. *Uji "saat tab dibuka: hari, saya, tanggal hari_ini; …": sebelum tab dibuka tidak ada `rekap`; membuka tab mengirim tepat `{aksi: rekap, periode: hari, cakupan: saya}` tanpa `tanggal` (= hari ini menurut server, seperti Input Saya), segmen Hari dan Input saya terpilih, judul "Senin, 12/10/2026". Uji "mengganti segmen memanggil rekap dengan tanggal yang sama": Minggu tanpa `tanggal`; ← → `tanggal=2026-10-05`; lalu Hari, Semua operator, dan Bulan masing-masing mengirim `tanggal=2026-10-05`; segmen yang sudah terpilih diketuk lagi tidak memanggil apa-apa.*
- [x] Panah → nonaktif bila `navigasi.sesudah` `null`. Panah ← memuat `navigasi.sebelum`. *Uji "panah ← memuat navigasi.sebelum; → …": hari ini → nonaktif dan ketukannya tanpa permintaan; ← → `tanggal=2026-10-11` dan → aktif; → → `tanggal=2026-10-12` dan nonaktif lagi; Bulan ← → `tanggal=2026-09-01`, "September 2026". Selama memuat kedua panah nonaktif.*
- [x] Label "Transaksi" dan "Donatur" terpisah. *Uji pertama: di kartu ringkasan "Total" Rp 27.000.000, "Transaksi" 146, "Donatur" 139 (contoh kontrak), dengan `Semantics` gabungan "Total\nRp 27.000.000", "Transaksi\n146", "Donatur\n139".*
- [x] Rincian per operator hanya tampil untuk Semua operator; baris `id_user: null` tampil sebagai "User lama (sudah dihapus)". *Uji "Semua operator: rincian per operator …": baris operator1 (80 transaksi, Rp 15.000.000), operator2, dan "User lama (sudah dihapus)" (1 transaksi, Rp 50.000) dalam urutan server; kembali ke Input saya → `cakupan=saya` dan rincian per operator hilang.*
- [x] `transaksi` = 0 → "Tidak ada sumbangan pada periode ini". *Uji "transaksi 0 → …": tanpa kartu dan tanpa baris; judul dan panah tetap bisa dipakai; juga untuk Semua operator.*

Cabang lain P5 yang juga teruji: rincian per hari hanya untuk Minggu dan Bulan (Hari tanpa rincian), dan untuk Semua operator rincian per operator tampil di atas rincian per hari; judul rentang "Senin, 12/10/2026 – Minggu, 18/10/2026" dan bulan "Oktober 2026"; galat jaringan → panel + Coba lagi → rekap; 500 → pesan umum; 422 `tidak_valid` → isi `rincian` di panel (layar ini tidak punya isian untuk periode/tanggal/cakupan); 401 → Masuk, setelah masuk rekap dimuat ulang dengan token; tab dibuka lagi → dimuat ulang dengan pilihan yang sama; tarik ke bawah → dimuat ulang; jawaban pilihan lama yang datang belakangan dibuang; `hari_ini` berganti saat resume → rekap hari baru dimuat.

## Semua layar (bagian S5)

- [x] Empat state Rekap: "Tidak ada sumbangan pada periode ini" / kerangka kartu (`KerangkaMemuat`) / panel galat + Coba lagi / ringkasan + rincian.
- [x] 360×640 dp, `textScaler` 1,3, tanpa luapan: Bulan × Semua operator dengan 31 baris per hari dan 9 baris operator bernama panjang, semua bernilai Rp 2.000.000.000, transaksi 12.345; judul rentang pekan terlipat; panel galat. Nominal di kartu mengecil bila tidak muat; nominal baris paling lebar separuh baris.
- [x] Layar ini tanpa isian. Nominal berupa teks "Rp …"; panah punya tooltip "Periode sebelumnya" / "Periode berikutnya".
- [x] Galat tampil sesuai docs/14_ERROR_HANDLING.md "Tempat tampil".

Uji mutasi: tanggal yang direset saat segmen diganti, panah → yang aktif walau `sesudah` null, jawaban lama yang tidak dibuang, dan Donatur yang menampilkan angka transaksi masing-masing membuat uji yang sesuai merah.
