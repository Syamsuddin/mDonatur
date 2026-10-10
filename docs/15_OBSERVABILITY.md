# 15 — OBSERVABILITY

## Klien

- **Tanpa telemetri jarak jauh**, tanpa analytics, dan tanpa crash reporting (A3).
- **Log hanya `debugPrint`**, yang tidak tercetak di build rilis. Formatnya `[api] <METODE> <aksi> <status> <ms>ms`, ditambah `kode` bila galat. Log tidak pernah memuat token, password, isi permintaan, atau data donatur (nama, alamat, No HP).
- **Diagnosa di layar Pengaturan:** versi aplikasi, versi kontrak klien (`versiKontrak`), `versi_api` server, alamat server, username, peran, dan kedaluwarsa token.

## Server (di repo root, hanya dibaca)

| Berkas | Isi | Dipakai untuk |
|---|---|---|
| `../storage/logs/php-error.log` | Galat PHP. Galat API dijawab 500 JSON tanpa jejak | Diagnosa `galat_server` |
| `../storage/logs/audit.log` | Satu baris JSON per tambah atau ubah; dari mobile ada `"via":"mobile"` | Metrik sukses (docs/00_EXECUTIVE_SUMMARY.md) |
| `../storage/cache/login-*.json` | Penghitung penguncian login, dipakai bersama web | Diagnosa `login_terkunci` |

[TERBUKA] Cara menghitung metrik "≥ 80% lewat mobile" baru dirumuskan setelah deploy. Dasarnya perbandingan baris tambah sumbangan yang ber-`"via":"mobile"` dengan semua baris tambah di `audit.log`.
