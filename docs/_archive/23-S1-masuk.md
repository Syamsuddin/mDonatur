# Arsip 23 — S1 Masuk dan Pengaturan (F1, F2)

Diterima 10 Okt 2026. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/masuk_test.dart test/api/klien_api_test.dart` dan `flutter test test/layar/pengaturan_test.dart` → `All tests passed!`, ditambah demo di emulator Pixel_5 Android 13 terhadap server lokal (`../UPDATE_PLAN.md` "Hasil uji 12c slice S1").

## F1 Masuk dan keluar (S1)

- [x] `uji_operator` dengan password benar → token tersimpan di secure storage → `konfigurasi` dipanggil → tab Input tampil. *Uji "password benar → token tersimpan …"; demo: `login 200` → `konfigurasi 200` → tab Input.*
- [x] `login_gagal` → panel berisi `pesan` server; isian Username tetap. *Uji "login_gagal → panel pesan server …".*
- [x] `login_terkunci` → panel berisi `pesan` server. `api_mati` → "Layanan mobile belum diaktifkan di server." *Uji "login_terkunci …" dan "api_mati …".*
- [x] Aplikasi dibuka dengan token yang dijawab 401 → layar Masuk. *Uji "token dijawab 401 → Masuk …".*
- [x] Ada isian di tab Input, lalu permintaan berikutnya dijawab 401 → Masuk tampil di atas kerangka; setelah masuk, isian masih ada. *Uji "Masuk didorong di atas kerangka …" memakai tab tiruan (`test/layar/bantu.dart`), karena layar Input Sumbangan baru ada di S2; uji mutasi membuktikan uji ini merah bila kerangka dibuang.*
- [x] `versi_api` `"0.2.0"` (klien 0.1.0) → layar blokir dengan pesan kontrak §9. *Uji grup "versi kontrak (§9)": saat dibuka, dari `X-Api-Versi` di kerangka, dan setelah login.*
- [x] Keluar saat ada isian belum disimpan → dialog konfirmasi. Setelah Keluar, token terhapus, sedangkan alamat server dan username terakhir tetap. *Uji grup "P7 keluar"; demo: Keluar → Masuk dengan Username terisi, tanpa aksi server.*

## F2 Pengaturan alamat server (S1)

- [x] `http://host/donatur/` disimpan sebagai `http://host/donatur` (build debug), dan aksi dipanggil ke `http://host/donatur/api?aksi=<aksi>`. *Uji "… disimpan tanpa garis miring …"; demo: `http://localhost:8000/` tersimpan sebagai `http://localhost:8000`, lalu login ke alamat itu.*
- [x] Validasi alamat dengan mode rilis menolak `http://…` dan menerima `https://…`. *Uji "mode rilis menolak http …", "mode rilis: alamat http ditolak di isian …", "mode rilis: SERVER_URL http diabaikan".*
- [x] Mengganti alamat saat sudah masuk menghapus token → Masuk. "Pakai alamat bawaan" mengembalikan `SERVER_URL`. *Uji grup "ganti alamat saat sudah masuk"; demo: Pakai alamat bawaan → Masuk, alamat kembali ke `SERVER_URL`, Username/Token "—".*
- [x] Pengaturan menampilkan versi aplikasi, `versiKontrak`, `versi_api`, username, peran, dan kedaluwarsa. *Uji grup "informasi diagnosa" (termasuk `versiAplikasi` = `version` pubspec.yaml); demo: 1.0.0+1, 0.1.0, 0.1.0, `http://localhost:8000`, uji_operator, operator, "Minggu, 11/10/2026 04:12".*

## Semua layar (bagian S1)

- [x] Empat state: Masuk (isian kosong / Masuk nonaktif + indikator / panel galat / tab Input) dan Pengaturan (isian / Simpan nonaktif + indikator / `errorText` / "Alamat server tersimpan.").
- [x] 360×640 dp, `textScaler` 1,3, tanpa luapan: Masuk, Masuk ulang di atas kerangka, layar gagal saat dibuka, layar blokir versi, Pengaturan, dialog Keluar, kerangka.
- [x] Setiap isian punya `labelText` (Username, Password, Alamat Server).
- [x] Galat tampil sesuai docs/14_ERROR_HANDLING.md "Tempat tampil"; isian tetap. Password dikosongkan setelah server menjawab, dan tetap di isian (memori saja) saat jaringan putus agar Kirim ulang langsung bisa ditekan.
