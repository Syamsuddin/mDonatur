# 04 — DOMAIN_MODEL

Bentuk field setiap entitas ada di `API_CONTRACT.md` §6. Dokumen ini hanya memuat makna istilah.

## Glosarium

| Istilah | Makna |
|---|---|
| Donatur / Donator | Penyumbang terdaftar |
| Nomor Donator / Nomor Register | Nomor donatur yang diketik operator (1–32767). Label "Nomor Donator" dipakai di isian, "Nomor Register" di kartu hasil tambah donatur |
| Sumbangan / Donasi | Satu catatan pemberian |
| Jumlah / Nominal | Rupiah bulat tanpa desimal |
| Operator | Pengguna berperan operator. Kata ini juga dipakai untuk siapa pun yang menginput (rekap "per operator") |
| Input Saya | Sumbangan yang diinput pengguna yang sedang masuk, pada satu tanggal |
| Transaksi | Banyaknya baris sumbangan |
| Donatur (dalam rekap) | Banyaknya donatur **berbeda**. Jangan disamakan dengan transaksi. |
| Bintang | Tingkat donatur 0–5, dari rata-rata bulanan sumbangan pada **tahun kalender lalu**. Ambangnya di kontrak §6.3 |
| Riwayat | Sumbangan donatur pada **tahun kalender berjalan** |
| Saran Jumlah | Rata-rata sumbangan donatur dalam **12 bulan bergulir**, bila tepat salah satu Nominal Umum. Ketiga jendela waktu ini (bintang, riwayat, saran) berbeda dan tidak boleh disatukan. |
| Nominal Umum | Daftar `konfigurasi.nominal_umum` dari server, dipakai sebagai tombol nominal cepat |
| Konfirmasi K5 | Server meminta konfirmasi karena donatur sudah tercatat menyumbang hari ini |
| Konfirmasi K9 | Server meminta konfirmasi karena nominal di atas `nominal_konfirmasi` |
| Konfirmasi nominal kecil | Konfirmasi lokal klien untuk Jumlah < Rp 1.000 (T16). Bukan aturan server |
| Note n | Penanda internal khusus admin (`note_n: true`). Operator tidak pernah menerimanya |
| Hari ini | `konfigurasi.hari_ini`, yaitu tanggal server dalam WITA. Bukan jam HP |
| Minggu (pekan) | Senin–Minggu (K14). Label "Minggu ini" berarti pekan, bukan hari Minggu |
| User lama | Baris rekap "User lama (sudah dihapus)": sumbangan milik user yang sudah terhapus |
| Donatur terhapus | Sumbangan yang `nama_donatur`-nya `null` (K7) |
| Kunci kirim ulang | Header `Idempotency-Key`. Kunci baru dibuat setiap kali Simpan ditekan; kunci yang sama dipakai saat Kirim ulang (kontrak §7) |
| Strip hari ini | Baris "Total input hari ini (N×): Rp …" beserta 6 input terakhir, di layar Input Sumbangan |

## Entitas dan relasi konseptual

| Entitas (kelas Dart di `lib/api/model.dart`) | Arti | Relasi |
|---|---|---|
| `Pengguna` | Akun yang sedang masuk | memiliki satu `Sesi` |
| `Sesi` | Token dan kedaluwarsanya | milik `Pengguna` |
| `Konfigurasi` | Versi API, hari ini, nominal umum, batas K9 | dibaca saat aplikasi dibuka dan saat resume |
| `DonaturRingkas` / `DonaturDetail` | Hasil cari / hasil Cek | `DonaturDetail` memuat riwayat `Sumbangan` |
| `Sumbangan` | Satu sumbangan | → satu Donatur (bisa sudah terhapus); diinput oleh satu Pengguna (implisit: pengguna token) |
| `RingkasanHariIni` | Total, transaksi, dan 6 input terakhir milik pengguna hari ini | agregat `Sumbangan` |
| `Rekap` | Agregat satu periode: per hari dan per operator | agregat `Sumbangan` |
| `GalatApi` | Jawaban galat: status, kode, pesan, rincian | lihat docs/14_ERROR_HANDLING.md |

Skema fisik database adalah milik server; lihat docs/07_DATA_MODEL.md.
