// Baris sumbangan (docs/26_UI_CONVENTIONS.md §Inventaris): ListTile di dalam Card berisi jam (tebal bila
// note_n), "nomor · nama", jumlah tebal di kanan, ikon edit primer bila boleh_ubah, dan tombol ikon hapus
// teksBahaya bila boleh_hapus (admin, K23). Baris tanpa boleh_ubah tidak bisa diketuk (P4.4
// docs/06_BUSINESS_PROCESS.md). Jumlah paling lebar separuh baris; huruf mengecil bila tidak muat,
// seperti strip hari ini, sehingga nama tetap punya tempat.

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import 'kerangka_memuat.dart';

/// Nama untuk sumbangan yang donaturnya sudah terhapus (`nama_donatur: null`, P4.2).
const namaDonaturTerhapus = '(donatur terhapus)';

class BarisSumbangan extends StatelessWidget {
  const BarisSumbangan({
    super.key,
    required this.baris,
    required this.padaUbah,
    this.padaHapus,
    this.menghapus = false,
  });

  final BarisDonasiSaya baris;

  /// Dipanggil saat baris diketuk; diabaikan bila `boleh_ubah` bernilai false.
  final VoidCallback padaUbah;

  /// Tombol hapus (hanya bila `boleh_hapus`); `null` = nonaktif, mis. selama hapus lain berjalan.
  final VoidCallback? padaHapus;

  /// Baris ini sedang dihapus: tombol hapus berisi indikator.
  final bool menghapus;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final gayaJam = baris.noteN ? teks.bodyMedium!.merge(Huruf.penandaNote) : teks.bodyMedium;
    return LayoutBuilder(
      builder: (context, batas) => ListTile(
        leading: Text(formatJam(baris.waktu), style: gayaJam),
        title: Text('${baris.idDonatur} · ${baris.namaDonatur ?? namaDonaturTerhapus}'),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: batas.maxWidth / 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatRupiah(baris.jumlah), style: teks.bodyLarge!.merge(Huruf.tebal), maxLines: 1),
                ),
              ),
              if (baris.bolehUbah) ...[
                const SizedBox(width: Jarak.j8),
                const Tooltip(message: 'Ubah', child: Icon(Icons.edit)),
              ],
              if (baris.bolehHapus)
                IconButton(
                  icon: menghapus ? const IndikatorTombol() : const Icon(Icons.delete_outline),
                  color: Warna.teksBahaya,
                  tooltip: 'Hapus',
                  onPressed: menghapus ? null : padaHapus,
                ),
            ],
          ),
        ),
        onTap: baris.bolehUbah ? padaUbah : null,
      ),
    );
  }
}
