# 05 — USER_ROLE

Semua hak **ditegakkan server** (kontrak §3, §6). Klien hanya menyembunyikan aksi yang tidak berlaku. Bila perilaku klien dan server berbeda, server yang benar.

## Peran

| `user.Keterangan` di server | Peran di jawaban API | Bisa memakai mDonator |
|---|---|---|
| `admin` (huruf besar-kecil bebas) | `admin` | Ya; fitur operator (K11), ditambah pilihan Note dan hapus sumbangan (K23) |
| `Operator` (huruf besar-kecil bebas) | `operator` | Ya |
| lainnya, mis. `Nonaktif` | — | Tidak. `login` menjawab `login_gagal`; token yang sudah ada menjawab `akun_nonaktif` |

Peran terbaru diambil dari `konfigurasi.pengguna.peran`, yang dipanggil saat aplikasi dibuka dan saat resume. Klien tidak menyimpan peran secara permanen.

## Matriks akses

| Kapabilitas | Operator | Admin | Perilaku klien |
|---|:-:|:-:|---|
| Cek dan cari donatur | ✓ | ✓ | — |
| Input sumbangan | ✓ | ✓ | Mengirim `note: "n"` hanya bila admin mengosongkan centang Note; tanpa itu `Note='y'` |
| Pilih Note (y/n) saat input | ✗ (server mengabaikan `note`) | ✓ (K23) | Centang Note hanya tampil bila `konfigurasi.boleh_atur_note: true`; bawaan tercentang (y), kembali y setelah tersimpan |
| Tambah donatur beserta sumbangan pertama | ✓ | ✓ | — |
| Lihat Input Saya | ✓ milik sendiri | ✓ milik sendiri | — |
| Ubah nominal | ✓ milik sendiri, hari ini (K6) | ✓ milik sendiri, tanggal apa pun [ASUMSI A19] | Ubah hanya bisa diketuk pada baris `boleh_ubah: true` |
| Lihat baris Note n | ✗ (server tidak mengirimnya) | ✓ | Baris `note_n: true` ditampilkan dengan tanggal/jam tebal, tanpa label |
| Hapus sumbangan | ✗ (403) | ✓ milik siapa pun, tanggal apa pun (K23); di Input Saya hanya baris miliknya | Ikon hapus hanya pada baris `boleh_hapus: true`; dikirim tanpa dialog konfirmasi; tidak dicatat di log (K21a) |
| Ubah Note sumbangan yang sudah ada, Input Khusus | ✗ | ✗ | Tidak ada di UI |
| Rekap saya dan rekap semua operator | ✓ | ✓ | — |
| Ganti password sendiri | ✓ | ✓ | — |

Visibilitas diuji dengan akun `uji_operator` dan `uji_admin` (docs/10_DEV_ENV.md).
