# 22 — CHANGE_POLICY

**Prinsip:** friksi sebanding dengan irreversibilitas.

## Git

- Repo induk lokal, tanpa remote. Pekerjaan di cabang `pembaruan`; `main` berisi baseline produksi web.
- Hanya isi folder `mDonator/` yang dipublikasikan, ke https://github.com/Syamsuddin/mDonatur (publik, keputusan pemilik 11 Okt 2026). Riwayatnya disaring ke folder ini di klon sementara (`git filter-branch --subdirectory-filter mDonator`; `git subtree` tidak ada di git Xcode), lalu digabung dengan `main` repo itu tanpa force push. Repo induk tidak boleh di-push ke repo publik (alasan di `../CLAUDE.md`, bagian Git).
- Commit hanya bila pemilik meminta.
  - Pesan: `Fase 12 S<n>: <ringkasan>`.
  - Diakhiri baris atribusi yang ditetapkan lingkungan kerja.
- Setelah slice selesai, bagian "Hasil uji" di `../UPDATE_PLAN.md` Fase 12 diperbarui (docs/24_DEFINITION_OF_DONE.md).

## Operasi yang butuh gerbang manusia (tanya dulu, tunggu jawaban)

| Operasi | Alasan |
|---|---|
| Mengubah `API_CONTRACT.md`, termasuk minor | Mengikat server dan klien. Alurnya kontrak §9: kontrak dulu, lalu server, lalu klien. Perubahan mayor wajib disetujui pemilik |
| Menambah paket Dart atau plugin di luar docs/09_STACK.md | Batasan dependensi minimal |
| Mengubah `applicationId` setelah APK pernah dibagikan | Tidak bisa diganti tanpa memasang ulang aplikasi di HP |
| Membagikan atau menerbitkan APK | Distribusi ditunda pemilik |
| Push ke GitHub, termasuk repo `mDonatur` | Repo itu publik; isinya terbuka untuk siapa saja |
| Apa pun yang menyentuh server atau DB produksi | Deploy ditunda; data produksi tidak boleh berisiko |
| Menulis ke DB selain DB lokal, atau menghapus data lokal selain baris `UJI-MOBILE …` | DB lokal adalah salinan produksi berisi data pribadi |
| Perubahan skema DB | Terlarang, kecuali migrasi terencana di server |
| Mengubah keputusan K-nomor, atau penyelarasan `../UPDATE_PLAN.md` dan `../CLAUDE.md` di luar "Hasil uji" | Dokumen milik pemilik |

## Rollback

- **Kode:** `git restore` atau `git revert` di repo lokal.
- **DB lokal:** muat ulang dari dump sesuai `../CLAUDE.md` bagian "Running locally", lalu `php tests/akun-uji.php`.
