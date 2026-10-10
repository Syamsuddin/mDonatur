# Arsip 23 — S3 Tambah donatur (F5)

Diterima 10 Okt 2026. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/tambah_donatur_test.dart` → `All tests passed!` (21 uji; suite penuh 217 uji), ditambah demo di emulator Pixel_5 Android 13 terhadap server lokal (`../UPDATE_PLAN.md` "Hasil uji 12c slice S3"). Bagian server slice ini (logika bersama donatur, aksi `tambahdonatur`) selesai di 12b; `php tests/api.php` LULUS 158 cek sebelum klien dimulai, setelah donasi demo S2 di DB lokal dihapus atas keputusan pemilik.

## F5 Tambah donatur (S3)

- [x] Mengetik Nama "Fulan" huruf demi huruf → `caridonatur` dipanggil sekali, 500 ms setelah ketikan terakhir. Hasil tampil sebagai "Nama mirip". *Uji "Nama diketik huruf demi huruf → caridonatur sekali, 500 ms setelah ketikan terakhir" (tidak ada panggilan pada 499 ms, satu panggilan `q=Fulan` pada 500 ms; judul `teksPeringatan`, "Persempit pencarian" `teksInfo`) dan "Nama satu huruf → tanpa caridonatur; hasil kosong → tanpa peringatan". Isian Nama memakai `CariDonaturNotifier` S2, sehingga aturan jeda tidak disalin. Demo: daftar nama mirip muncul di emulator.*
- [x] Ketuk nama mirip → tab Input, nomor terisi, Cek otomatis; isian Tambah Donatur tetap. *Uji "ketuk nama mirip → tab Input …" (lewat `KerangkaNotifier.inputSumbanganUntuk`); uji mutasi tanpa pindah tab membuatnya merah. Demo: ketuk "Abdul Aziz" → tab Input, 7756 terisi, kartu donatur tampil (log: `caridonatur` lalu `donatur`).*
- [x] 201 → kartu hasil dengan Nomor Register (32/40, tebal); isian kosong; strip di tab Input diperbarui. *Uji "201 → kartu Nomor Register (32/40 tebal) …": isi permintaan sama dengan kontrak §6.6, `Idempotency-Key` UUID, gaya 32/40 w700, kelima isian kosong, strip tab Input "11× Rp 1.650.000" dari `ringkasan_hari_ini` tanpa `donasisaya` ulang; uji mutasi tanpa meneruskan ringkasan membuatnya merah. Demo: kartu "Data Donatur Berhasil Disimpan · Nomor Register 7822 · Rp 10.000 · 14:17 WITA", isian kosong.*
- [x] 409 `donatur_sudah_ada` → nomor yang ada tampil bersama aksi "Input sumbangan untuk nomor ini". *Uji "409 donatur_sudah_ada → …" (panel "Data Donator Sudah Ada!\nNomor Register: 7759", tombol → tab Input dengan 7759 di-Cek, isian Tambah Donatur tetap) dan "isian diubah setelah donatur_sudah_ada → panel hilang".*
- [x] 422 dengan `rincian.nama` → `errorText` di Nama Donator; isian lain tetap. *Uji "422 rincian.nama …" (pesan emoji kontrak §6.6; galat hilang saat Nama diubah) dan "422 semua isian sekaligus …" (lima kunci ke lima isian; kunci tanpa isian → panel).*
- [x] Sumbangan Pertama 500 → dialog lokal. *Uji "Sumbangan Pertama 500 → dialog lokal; Tidak → tanpa permintaan; Ya → terkirim" dan "Sumbangan Pertama 1.000 tidak memakai dialog lokal".*

Cabang lain P3 yang juga teruji: 409 `perlu_konfirmasi` K9 (dialog alasan + nama yang diketik; Ya → `konfirmasi: true` dengan kunci baru; Tidak → tanpa kiriman kedua), timeout → Kirim ulang dengan kunci dan isi sama, isian diubah → Kirim ulang hilang, 500 → pesan umum + Coba lagi dengan kunci sama, 401 → Masuk di atas kerangka lalu isian tetap, dan dialog Keluar untuk isian Tambah Donatur.

## Semua layar (bagian S3)

- [x] Empat state Tambah Donatur: formulir kosong / Simpan nonaktif + indikator, isian terkunci / `errorText` per isian atau panel / kartu Nomor Register. Nama mirip: tanpa daftar / hasil sebelumnya tetap selama mencari / panel + Coba lagi / daftar.
- [x] 360×640 dp, `textScaler` 1,3, tanpa luapan: 20 nama mirip panjang dengan "Persempit pencarian", isian panjang, panel `donatur_sudah_ada` dengan tombol panjang, dan kartu hasil Rp 2.000.000.000; kerangka dengan tab Donatur sungguhan.
- [x] Setiap isian punya `labelText` (Nama Donator, Alamat, Nomor Handphone, Keterangan, Sumbangan Pertama). Nominal di kartu hasil berupa teks "Rp …".
- [x] Galat tampil sesuai docs/14_ERROR_HANDLING.md "Tempat tampil"; isian tetap. `donatur_sudah_ada` memakai Panel galat dari inventaris (docs/14 menulis "Panel info"; menunggu konfirmasi pemilik, `_MANIFEST.json` open_questions).
