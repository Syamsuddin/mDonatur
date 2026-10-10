// Layar Rekap, tab 4 (P5 docs/06_BUSINESS_PROCESS.md): segmen periode dan cakupan, panah periode
// dengan judul rentang, lalu ringkasan Total / Transaksi / Donatur, rincian per operator (Semua
// operator), dan rincian per hari (Minggu, Bulan). Semua angka dari server (kontrak §6.9). Rekap
// dimuat setiap kali tab dibuka dan bisa ditarik ke bawah. Empat state: docs/26_UI_CONVENTIONS.md.

import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../state/kerangka_notifier.dart';
import '../state/rekap_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/panel_galat.dart';
import '../widget/state_kosong.dart';

class LayarRekap extends StatefulWidget {
  const LayarRekap({super.key});

  @override
  State<LayarRekap> createState() => _LayarRekapState();
}

class _LayarRekapState extends State<LayarRekap> {
  late final KerangkaNotifier _kerangka = KerangkaScope.baca(context);
  late final RekapNotifier _notifier = RekapNotifier(SesiScope.baca(context));
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

  /// Dimuat saat tab dibuka, bukan saat kerangka dibangun, dan dimuat ulang setiap kali tab dibuka
  /// lagi, karena tab lain bisa menambah atau mengubah sumbangan.
  void _tabBerubah() {
    final aktif = _kerangka.tab == KerangkaNotifier.tabRekap;
    if (aktif && !_aktif) unawaited(_notifier.muat());
    _aktif = aktif;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final n = _notifier;
        final data = n.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, Jarak.tepiLayar, Jarak.tepiLayar, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<Periode>(
                    segments: const [
                      ButtonSegment(value: Periode.hari, label: Text('Hari')),
                      ButtonSegment(value: Periode.minggu, label: Text('Minggu')),
                      ButtonSegment(value: Periode.bulan, label: Text('Bulan')),
                    ],
                    selected: {n.periode},
                    onSelectionChanged: (pilihan) => unawaited(n.pilihPeriode(pilihan.single)),
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                  ),
                  const SizedBox(height: Jarak.j8),
                  SegmentedButton<Cakupan>(
                    segments: const [
                      ButtonSegment(value: Cakupan.saya, label: Text('Input saya')),
                      ButtonSegment(value: Cakupan.semua, label: Text('Semua operator')),
                    ],
                    selected: {n.cakupan},
                    onSelectionChanged: (pilihan) => unawaited(n.pilihCakupan(pilihan.single)),
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            _NavigasiPeriode(
              judul: data == null ? '' : _judul(data),
              padaSebelum: data == null ? null : n.sebelumnya,
              padaSesudah: data?.navigasi.sesudah == null ? null : n.berikutnya,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: n.muat,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: Jarak.j16),
                  children: _isi(n),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Rentang `dari`–`sampai` dari server (P5.2), dengan format tanggal docs/26 §Mikroteks.
  static String _judul(Rekap data) => switch (data.periode) {
        Periode.hari => formatTanggal(data.dari),
        Periode.minggu => formatRentang(data.dari, data.sampai),
        Periode.bulan => formatBulan(data.dari),
      };

  List<Widget> _isi(RekapNotifier n) {
    const tepi = EdgeInsets.symmetric(horizontal: Jarak.tepiLayar);
    final data = n.data;
    if (data != null && data.transaksi == 0) {
      return const [StateKosong('Tidak ada sumbangan pada periode ini')];
    }
    if (data != null) {
      return [
        Padding(padding: tepi, child: _Ringkasan(data)),
        // per_operator hanya diisi server untuk cakupan semua; daftarnya pendek, jadi tampil
        // sebelum rincian per hari yang bisa sampai 31 baris.
        if (data.cakupan == Cakupan.semua && data.perOperator.isNotEmpty) ...[
          const _JudulRincian('Rincian per operator'),
          for (final operator in data.perOperator)
            _BarisRincian(judul: operator.nama, transaksi: operator.transaksi, total: operator.total),
        ],
        if (data.periode != Periode.hari && data.perHari.isNotEmpty) ...[
          const _JudulRincian('Rincian per hari'),
          for (final hari in data.perHari)
            _BarisRincian(judul: formatTanggal(hari.tanggal), transaksi: hari.transaksi, total: hari.total),
        ],
      ];
    }
    if (n.status == StatusRekap.gagal) {
      return [
        Padding(
          padding: tepi,
          child: PanelGalat(
            pesan: n.pesanGalat ?? TeksGalat.umum,
            labelTombol: 'Coba lagi',
            padaTombol: n.muat,
          ),
        ),
      ];
    }
    return const [Padding(padding: tepi, child: KerangkaMemuat())];
  }
}

/// Panah ← dan → mengapit judul rentang. Panah nonaktif selama rekap belum ada, dan → nonaktif
/// bila `navigasi.sesudah` bernilai `null` (P5.2).
class _NavigasiPeriode extends StatelessWidget {
  const _NavigasiPeriode({required this.judul, required this.padaSebelum, required this.padaSesudah});

  final String judul;
  final VoidCallback? padaSebelum;
  final VoidCallback? padaSesudah;

  @override
  Widget build(BuildContext context) {
    // Tepi 4 + celah ikon 12 = tepi layar 16, sejajar dengan segmen di atasnya.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Jarak.j4, vertical: Jarak.j4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Periode sebelumnya',
            onPressed: padaSebelum,
          ),
          Expanded(
            child: Text(judul, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Periode berikutnya',
            onPressed: padaSesudah,
          ),
        ],
      ),
    );
  }
}

/// Total, Transaksi, dan Donatur. Transaksi dan Donatur berlabel terpisah karena donatur adalah
/// banyaknya donatur berbeda, bukan banyaknya transaksi (docs/04_DOMAIN_MODEL.md).
class _Ringkasan extends StatelessWidget {
  const _Ringkasan(this.data);

  final Rekap data;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final lemah = teks.bodyMedium!.copyWith(color: Warna.teksLemah);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Jarak.isiKartu),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: lemah),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(formatRupiah(data.total), style: teks.headlineSmall, maxLines: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Jarak.j8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Angka(label: 'Transaksi', nilai: data.transaksi)),
                const SizedBox(width: Jarak.j8),
                Expanded(child: _Angka(label: 'Donatur', nilai: data.donatur)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka({required this.label, required this.nilai});

  final String label;
  final int nilai;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: teks.bodyMedium!.copyWith(color: Warna.teksLemah)),
          Text(formatRibuan(nilai), style: teks.titleLarge),
        ],
      ),
    );
  }
}

class _JudulRincian extends StatelessWidget {
  const _JudulRincian(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, Jarak.j16, Jarak.tepiLayar, 0),
      child: Text(teks, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksLemah)),
    );
  }
}

/// Satu baris rincian: nama operator atau tanggal, banyaknya transaksi, dan total di kanan. Total
/// paling lebar separuh baris dan hurufnya mengecil bila tidak muat, seperti baris sumbangan.
class _BarisRincian extends StatelessWidget {
  const _BarisRincian({required this.judul, required this.transaksi, required this.total});

  final String judul;
  final int transaksi;
  final int total;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, batas) => ListTile(
        title: Text(judul),
        subtitle: Text('${formatRibuan(transaksi)} transaksi'),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: batas.maxWidth / 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatRupiah(total), style: Theme.of(context).textTheme.bodyLarge, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
