# 05 — USER_ROLE

Semua hak **ditegakkan server** (kontrak §3, §6). Klien hanya menyembunyikan aksi yang tidak berlaku. Bila perilaku klien dan server berbeda, server yang benar.

## Peran

| `user.Keterangan` di server | Peran di jawaban API | Bisa memakai mDonator |
|---|---|---|
| `admin` (huruf besar-kecil bebas) | `admin` | Ya; fiturnya sama dengan operator (K11) |
| `Operator` (huruf besar-kecil bebas) | `operator` | Ya |
| lainnya, mis. `Nonaktif` | — | Tidak. `login` menjawab `login_gagal`; token yang sudah ada menjawab `akun_nonaktif` |

Peran terbaru diambil dari `konfigurasi.pengguna.peran`, yang dipanggil saat aplikasi dibuka dan saat resume. Klien tidak menyimpan peran secara permanen.

## Matriks akses

| Kapabilitas | Operator | Admin | Perilaku klien |
|---|:-:|:-:|---|
| Cek dan cari donatur | ✓ | ✓ | — |
| Input sumbangan | ✓ | ✓ | Tidak pernah mengirim Note; server selalu mencatat `Note='y'` |
| Tambah donatur beserta sumbangan pertama | ✓ | ✓ | — |
| Lihat Input Saya | ✓ milik sendiri | ✓ milik sendiri | — |
| Ubah nominal | ✓ milik sendiri, hari ini (K6) | ✓ milik sendiri, tanggal apa pun [ASUMSI A19] | Ubah hanya bisa diketuk pada baris `boleh_ubah: true` |
| Lihat baris Note n | ✗ (server tidak mengirimnya) | ✓ | Baris `note_n: true` ditampilkan dengan tanggal/jam tebal, tanpa label |
| Ubah Note, hapus donasi, Input Khusus | ✗ | ✗ | Tidak ada di UI |
| Rekap saya dan rekap semua operator | ✓ | ✓ | — |
| Ganti password sendiri | ✓ | ✓ | — |

Visibilitas diuji dengan akun `uji_operator` dan `uji_admin` (docs/10_DEV_ENV.md).
