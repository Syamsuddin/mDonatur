# 01 — PRD

## Fitur

| # | Fitur | Prioritas | Padanan web |
|---|---|---|---|
| F1 | Masuk dan keluar dengan token | MVP | `login`, `logout` |
| F2 | Pengaturan alamat server (termasuk subfolder) | MVP | — |
| F3 | Cek donatur per nomor; cari donatur lewat nomor, nama, atau alamat | MVP | `search2`, pencarian `tampildonatur` |
| F4 | Input sumbangan: saran Jumlah, nominal cepat, konfirmasi K5/K9 dari server, konfirmasi lokal untuk nominal < Rp 1.000, kirim ulang aman, strip total hari ini; bagi admin centang Note y/n (S8, K23) | MVP | `tambahdonasi` (Note n: `tambahdonasiy`) |
| F5 | Tambah donatur beserta sumbangan pertama: peringatan nama mirip, duplikat persis, K9 | MVP | `tambahdonatur` |
| F6 | Input Saya (daftar per tanggal dan total) dan ubah nominal sesuai `boleh_ubah` (K6); bagi admin hapus sumbangan tanpa konfirmasi sesuai `boleh_hapus` (S8, K23) | MVP | `tampildonasi` (miliknya), `ubahdonasi`, `hapusdonasi` |
| F7 | Rekap Hari / Minggu (Senin–Minggu) / Bulan × Input saya / Semua operator | MVP | `rekapoperator`, `rekapalloperator`, `rekapbulanan` |
| F8 | Ganti password | MVP | `gantipassword` |
| N1 | Pindai QR kartu donatur | Nanti | — |
| N2 | Kirim bukti sumbangan lewat tautan `wa.me` | Nanti | — |
| N3 | Versi iOS | Nanti | — |

Alur rinci tiap fitur ada di docs/06_BUSINESS_PROCESS.md.

## User story MVP

- **F1.** Sebagai operator, saya ingin masuk sekali di awal hari kerja agar bisa langsung menginput tanpa login berulang.
- **F2.** Sebagai pengelola, saya ingin mengisi alamat server di aplikasi agar aplikasi bisa dipakai di instalasi mana pun, termasuk subfolder.
- **F3.** Sebagai operator, saya ingin melihat nama, alamat, bintang, dan riwayat tahun ini setelah mengetik nomor agar yakin donaturnya benar. Bila donatur lupa nomornya, saya ingin mencarinya lewat nama.
- **F4.** Sebagai operator, saya ingin menyimpan sumbangan dengan ketukan sesedikit mungkin, dan diperingatkan bila donatur sudah menyumbang hari ini atau nominalnya janggal, agar tidak salah catat.
- **F5.** Sebagai operator, saya ingin mendaftarkan donatur baru beserta sumbangan pertamanya, dan diperingatkan bila nama yang mirip sudah ada, agar tidak ada data ganda.
- **F6.** Sebagai operator, saya ingin melihat semua input saya hari ini beserta totalnya untuk serah terima uang, dan memperbaiki nominal yang salah ketik.
- **F4 dan F6 untuk admin (S8, K23).** Sebagai admin, saya ingin memilih Note saat menginput, dan menghapus sumbangan yang salah langsung dari Input Saya tanpa ditanya lagi.
- **F7.** Sebagai operator, saya ingin melihat total harian, mingguan, dan bulanan, milik saya maupun semua operator. Rincian per hari dan per operator juga tampil sebagai grafik (S7).
- **F8.** Sebagai operator, saya ingin mengganti password dari HP.

## Kebutuhan non-fungsional

- **Jaringan seluler lemah.** Isian tidak hilang saat galat, dan kirim ulang tidak menggandakan data (docs/14_ERROR_HANDLING.md).
- **Ergonomi.** Bisa dipakai satu tangan, dengan keypad angka untuk nomor dan nominal. Target sentuh, lebar minimum, dan skala huruf mengikuti docs/26_UI_CONVENTIONS.md.
- **Data di perangkat.** Data donatur tidak tersimpan di perangkat (docs/21_SECURITY_RULES.md).
- **Kecepatan.** Aksi baca API ≤ 1 detik di server lokal, termasuk `rekap` bulan dengan cakupan semua. Ini tanggung jawab server, tetapi diukur dari aplikasi.
