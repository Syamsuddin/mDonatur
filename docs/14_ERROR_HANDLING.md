# 14 — ERROR_HANDLING

Arti setiap kode dan tindakan yang diharapkan ada di `API_CONTRACT.md` §8 (rumahnya). Dokumen ini menetapkan cara klien mewujudkannya.

## Jenis galat di klien (`lib/api/galat_api.dart`)

| Kelas | Kapan | Isi |
|---|---|---|
| `GalatApi` | Jawaban `ok: false`, atau jawaban bukan JSON | `status`, `kode` (kosong bila bukan JSON), `pesan`, `rincian`, `alasan`, `donatur`, `sisaDetik`, `idDonatur` |
| `GalatJaringan` | Timeout (batasnya di kontrak §2), tanpa jaringan, atau koneksi putus | — |
| `GalatVersi` | `X-Api-Versi` atau `versi_api` tidak cocok dengan `versiKontrak` (aturan kontrak §9) | versi server |

**Aturan penanganan**

- `KlienApi` hanya mengembalikan model atau melempar salah satu dari tiga kelas di atas.
- Notifier menangkap galat dan mengubah status layar menjadi gagal. Galat tidak pernah diteruskan ke framework.
- Kode yang tidak dikenal ditangani menurut status HTTP-nya (kontrak §5).

## Tempat tampil

| Kode / jenis | Ditampilkan sebagai | Isian |
|---|---|---|
| `tidak_valid` | `errorText` pada isian yang namanya ada di `rincian`. Kunci tanpa isian yang cocok → panel galat | tetap |
| `perlu_konfirmasi` | Dialog konfirmasi (docs/06_BUSINESS_PROCESS.md P2.6) | tetap |
| `donatur_sudah_ada` | Panel info: nomor yang ada + aksi "Input sumbangan untuk nomor ini" | tetap |
| `login_gagal`, `login_terkunci`, `tidak_berhak`, `tidak_ada`, `fitur_belum_tersedia` | Panel galat di atas tombol aksi, berisi `pesan` server | tetap |
| `token_tidak_sah`, `token_kedaluwarsa`, `akun_nonaktif` | Layar Masuk didorong di atas kerangka, dengan `pesan` server | tetap (di memori) |
| `api_mati` | Panel galat: "Layanan mobile belum diaktifkan di server." | tetap |
| `galat_server`, kode tak dikenal berstatus 5xx | Panel galat dengan pesan umum dan tombol Coba lagi | tetap |
| Bug klien: `permintaan_salah`, `aksi_tidak_ada`, `metode_salah`, `kunci_ulang_bentrok`, `terlalu_besar`, `tipe_tidak_didukung` | Panel galat dengan pesan umum; `debugPrint` kode dan aksi (build debug saja) | tetap |
| `GalatJaringan` | Panel galat. Untuk POST tombolnya **Kirim ulang** (kunci sama); untuk GET **Coba lagi** | tetap |
| `GalatVersi` | Layar blokir penuh dengan pesan kontrak §9; hanya Pengaturan dan Keluar yang aktif | — |

**Pemetaan `rincian` ke isian**

| Kunci `rincian` | Isian |
|---|---|
| `id_donatur`; `id` pada aksi `donatur` (kontrak §6.3) | Nomor Donator |
| `jumlah` / `sumbangan` | Sumbangan / Sumbangan Pertama |
| `nama`, `alamat`, `no_hp`, `keterangan` | Isian Tambah Donatur yang sesuai |
| `lama`, `baru`, `ulang` | Isian Ganti Password yang sesuai |
| `username`, `password` | Isian Masuk |
| `q` | Isian Cari Donatur |
| `tanggal` | Pilihan tanggal Input Saya |

## Teks milik klien

| Situasi | Teks |
|---|---|
| `GalatJaringan` pada POST | "Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Kirim ulang." |
| `GalatJaringan` pada GET | "Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Coba lagi." |
| Pesan umum (500, bug klien, jawaban bukan JSON) | "Terjadi kesalahan. Coba lagi; bila berulang, hubungi admin." |

Selain tiga teks di atas, klien menampilkan `pesan` server apa adanya, sebagai teks polos.

## Larangan

- Mengulang POST otomatis, atau membuat kunci baru saat Kirim ulang.
- Mengosongkan isian karena galat.
- Merender HTML dari server.
- Menampilkan jejak tumpukan (stack trace).
- Menelan galat tanpa mengubah status layar.
- Mencatat token, password, atau data donatur (docs/15_OBSERVABILITY.md).
