// Layar Input Saya, tab 3 (P4 docs/06_BUSINESS_PROCESS.md): pilihan tanggal dan ringkasan (total dan
// transaksi) di kepala dasbor, lalu daftar sumbangan milik pengguna pada tanggal itu di dalam kartu. Daftar dimuat setiap kali tab dibuka dan
// bisa ditarik ke bawah; baris boleh_ubah membuka lembar Ubah, dan ikon hapus pada baris boleh_hapus (admin,
// K23) langsung menghapus tanpa dialog. Empat state: docs/26_UI_CONVENTIONS.md.

import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../state/input_saya_notifier.dart';
import '../state/kerangka_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import '../widget/baris_sumbangan.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/latar_dasbor.dart';
import '../widget/panel_galat.dart';
import '../widget/state_kosong.dart';
import 'ubah_sumbangan.dart';

class LayarInputSaya extends StatefulWidget {
  const LayarInputSaya({super.key});

  @override
  State<LayarInputSaya> createState() => _LayarInputSayaState();
}

class _LayarInputSayaState extends State<LayarInputSaya> {
  late final KerangkaNotifier _kerangka = KerangkaScope.baca(context);
  late final InputSayaNotifier _notifier =
      InputSayaNotifier(SesiScope.baca(context), padaHariIni: _kerangka.terimaHariIni);
  var _aktif = false;

  @override
  void initState() {
    super.initState();
    _kerangka.addListener(_tabBerubah);
    _tabBerubah();
  }

  @override
  void dispose() {
    _kerangka.removeListener(_tabBerubah);
    _notifier.dispose();
    super.dispose();
  }

  /// P4.1: dimuat saat tab dibuka, bukan saat kerangka dibangun, dan dimuat ulang setiap kali tab
  /// dibuka lagi, karena tab lain bisa menambah sumbangan.
  void _tabBerubah() {
    final aktif = _kerangka.tab == KerangkaNotifier.tabInputSaya;
    if (aktif && !_aktif) unawaited(_notifier.muat());
    _aktif = aktif;
  }

  /// Date picker sampai `hari_ini` server, bukan jam HP (P4.1).
  Future<void> _pilihTanggal() async {
    final hariIni = _notifier.hariIni;
    final tanggal = _notifier.tanggal;
    if (hariIni == null || tanggal == null) return;
    final pilihan = await showDatePicker(
      context: context,
      initialDate: tanggal.isAfter(hariIni) ? hariIni : tanggal,
      firstDate: tanggalPertamaInputSaya,
      lastDate: hariIni,
      currentDate: hariIni,
    );
    if (pilihan != null && mounted) await _notifier.pilihTanggal(pilihan);
  }

  Future<void> _ubah(DateTime tanggal, BarisDonasiSaya baris) async {
    final tersimpan = await tampilkanLembarUbah(
      context,
      tanggal: tanggal,
      baris: baris,
      padaTidakAda: () => unawaited(_notifier.muat()),
    );
    if (tersimpan && mounted) await _notifier.muat();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final n = _notifier;
        final data = n.data;
        return LatarDasbor(
          kepala: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PilihanTanggal(
                tanggal: n.tanggal,
                errorText: n.galatTanggal,
                padaKetuk: n.hariIni == null ? null : _pilihTanggal,
              ),
              if (data != null && data.daftar.isNotEmpty) ...[
                const SizedBox(height: Jarak.j12),
                _Ringkasan(total: data.total, transaksi: data.transaksi),
              ],
            ],
          ),
          isi: RefreshIndicator(
            onRefresh: n.muat,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              children: [
                if (n.pesanHapus case final pesan?) ...[
                  PanelGalat(
                    pesan: pesan,
                    labelTombol: switch (n.tombolHapus) {
                      TombolPanel.tidakAda => null,
                      TombolPanel.cobaLagi => 'Coba lagi',
                      TombolPanel.kirimUlang => 'Kirim ulang',
                    },
                    padaTombol: n.kirimUlangHapus,
                  ),
                  const SizedBox(height: Jarak.antarKartu),
                ],
                ..._isi(n),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _isi(InputSayaNotifier n) {
    final data = n.data;
    if (data != null && data.daftar.isEmpty) {
      return const [StateKosong('Belum ada input pada tanggal ini', ikon: Icons.receipt_long)];
    }
    if (data != null) {
      return [
        Card(
          child: Column(
            children: [
              for (final (i, baris) in data.daftar.indexed) ...[
                if (i > 0) const Divider(height: Bentuk.garisPemisah),
                BarisSumbangan(
                  baris: baris,
                  padaUbah: () => _ubah(data.tanggal, baris),
                  menghapus: n.idDihapus == baris.id,
                  padaHapus: n.idDihapus == null ? () => n.hapus(baris) : null,
                ),
              ],
            ],
          ),
        ),
      ];
    }
    if (n.status == StatusInputSaya.gagal) {
      return [
        if (n.pesanGalat case final pesan?)
          PanelGalat(pesan: pesan, labelTombol: 'Coba lagi', padaTombol: n.muat),
      ];
    }
    return const [KerangkaMemuat()];
  }
}

/// Pilihan tanggal: isian kepala baca-saja berlabel "Tanggal" yang membuka date picker. `rincian.tanggal`
/// 422 tampil sebagai errorText-nya (docs/14_ERROR_HANDLING.md).
class _PilihanTanggal extends StatelessWidget {
  const _PilihanTanggal({required this.tanggal, required this.errorText, required this.padaKetuk});

  final DateTime? tanggal;
  final String? errorText;
  final VoidCallback? padaKetuk;

  @override
  Widget build(BuildContext context) {
    final tanggal = this.tanggal;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: padaKetuk,
        borderRadius: BorderRadius.circular(Bentuk.radiusIsian),
        child: InputDecorator(
          decoration: dekorasiIsianKepala(
            label: 'Tanggal',
            errorText: errorText,
            enabled: padaKetuk != null,
            suffixIcon: const Icon(Icons.calendar_month, color: Warna.primer),
          ),
          child: Text(
            tanggal == null ? '' : formatTanggal(tanggal),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Total dan banyaknya sumbangan `Note='y'` pada tanggal itu (kontrak §6.7), di kepala: label putih dan
/// nominal besar aksen. Total paling lebar separuh baris dan hurufnya mengecil bila tidak muat.
class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.total, required this.transaksi});

  final int total;
  final int transaksi;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total $transaksi transaksi',
              style: teks.bodyMedium!.copyWith(color: Warna.diAtasPrimer),
            ),
          ),
          const SizedBox(width: Jarak.j8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatRupiah(total),
                  style: teks.displaySmall!.copyWith(color: Warna.aksen),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
