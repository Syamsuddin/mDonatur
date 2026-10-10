// Lembar bawah Ubah Sumbangan (P4.3–P4.5 docs/06_BUSINESS_PROCESS.md), dibuka dari baris Input Saya
// yang boleh_ubah. Hanya nominal yang bisa diubah; tidak ada aksi hapus. Pada 200 lembar ditutup
// dengan nilai true, lalu Input Saya memuat ulang daftarnya. Tempat tampil galat:
// docs/14_ERROR_HANDLING.md (panel di atas tombol, isian tetap).

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../state/input_sumbangan_notifier.dart' show StatusSimpan;
import '../state/sesi.dart';
import '../state/ubah_sumbangan_notifier.dart';
import '../tema.dart';
import '../util/tanggal.dart';
import '../widget/baris_sumbangan.dart' show namaDonaturTerhapus;
import '../widget/dialog_konfirmasi.dart';
import '../widget/isian_angka.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/panel_galat.dart';
import '../widget/tombol_utama.dart';

/// `jumlah` paling besar 2.147.483.647 (kontrak §6.8): paling banyak 10 digit.
const _digitJumlah = 10;

/// `true` bila nominal tersimpan. [padaTidakAda] dipanggil saat server menjawab 404 `tidak_ada`.
Future<bool> tampilkanLembarUbah(
  BuildContext context, {
  required DateTime tanggal,
  required BarisDonasiSaya baris,
  VoidCallback? padaTidakAda,
}) async {
  final tersimpan = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Ditutup lewat Batal atau ketuk di luar lembar; selama menyimpan keduanya ditahan (PopScope).
    enableDrag: false,
    builder: (_) => LayarUbahSumbangan(tanggal: tanggal, baris: baris, padaTidakAda: padaTidakAda),
  );
  return tersimpan ?? false;
}

class LayarUbahSumbangan extends StatefulWidget {
  const LayarUbahSumbangan({
    super.key,
    required this.tanggal,
    required this.baris,
    this.padaTidakAda,
  });

  final DateTime tanggal;
  final BarisDonasiSaya baris;
  final VoidCallback? padaTidakAda;

  @override
  State<LayarUbahSumbangan> createState() => _LayarUbahSumbanganState();
}

class _LayarUbahSumbanganState extends State<LayarUbahSumbangan> {
  late final UbahSumbanganNotifier _notifier = UbahSumbanganNotifier(
    SesiScope.baca(context),
    widget.baris,
    padaTidakAda: widget.padaTidakAda,
  )..addListener(_tutupBilaTersimpan);
  var _ditutup = false;

  @override
  void initState() {
    super.initState();
    // Keyboard langsung terbuka dengan Jumlah lama terpilih, untuk memperbaiki salah ketik.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifier.fokusJumlah.requestFocus();
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  /// P4.3: pada 200, lembar ditutup dan Input Saya memuat ulang daftar.
  void _tutupBilaTersimpan() {
    if (_notifier.hasil == null || _ditutup) return;
    _ditutup = true;
    Navigator.of(context).pop(true);
  }

  Future<bool> _tanya({String? judul, String? nama, required List<String> isi}) =>
      tampilkanDialogKonfirmasi(context, judul: judul, nama: nama, isi: isi);

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final n = _notifier;
        final b = n.baris;
        final memuat = n.statusSimpan == StatusSimpan.memuat;
        return PopScope(
          canPop: n.bisaDitutup,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ubah Sumbangan', style: teks.titleLarge),
                  const SizedBox(height: Jarak.j4),
                  Text(
                    '${formatTanggal(widget.tanggal)} ${formatJam(b.waktu)}\n'
                    '${b.idDonatur} · ${b.namaDonatur ?? namaDonaturTerhapus}',
                    style: teks.bodyMedium!.copyWith(color: Warna.teksLemah),
                  ),
                  const SizedBox(height: Jarak.antarIsian),
                  IsianAngka(
                    label: 'Sumbangan',
                    controller: n.jumlah,
                    focusNode: n.fokusJumlah,
                    errorText: n.galatJumlah,
                    maksDigit: _digitJumlah,
                    enabled: !n.isianTerkunci,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => n.simpan(_tanya),
                  ),
                  if (n.statusSimpan == StatusSimpan.gagal && n.pesanSimpan != null) ...[
                    const SizedBox(height: Jarak.j8),
                    PanelGalat(
                      pesan: n.pesanSimpan!,
                      labelTombol: switch (n.tombolSimpan) {
                        TombolPanel.tidakAda => null,
                        TombolPanel.cobaLagi => 'Coba lagi',
                        TombolPanel.kirimUlang => 'Kirim ulang',
                      },
                      padaTombol: () => n.kirimUlang(_tanya),
                    ),
                  ],
                  const SizedBox(height: Jarak.antarIsian),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: memuat ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: Jarak.antarTombol),
                      TombolUtama(
                        onPressed: n.bisaSimpan ? () => n.simpan(_tanya) : null,
                        child: memuat ? const IndikatorTombol() : const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
