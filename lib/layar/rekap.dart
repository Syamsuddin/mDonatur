// Layar Rekap, tab 4 (P5 docs/06_BUSINESS_PROCESS.md): segmen periode dan cakupan serta panah periode
// dengan judul rentang di kepala dasbor; di lembar isi kartu ringkasan Total / Transaksi / Donatur,
// kartu rincian per operator dengan donat (Semua operator), dan kartu rincian per hari dengan grafik
// (Minggu, Bulan). Semua angka dari server (kontrak §6.9); grafik hanya menggambarnya. Rekap dimuat
// setiap kali tab dibuka dan bisa ditarik ke bawah. Empat state: docs/26_UI_CONVENTIONS.md.

import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../state/kerangka_notifier.dart';
import '../state/rekap_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import '../widget/grafik_rekap.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/latar_dasbor.dart';
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
    final hariIni = SesiScope.of(context).konfigurasi?.hariIni;
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final n = _notifier;
        final data = n.data;
        return LatarDasbor(
          kepala: Column(
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
              _NavigasiPeriode(
                judul: data == null ? '' : _judul(data),
                padaSebelum: data == null ? null : n.sebelumnya,
                padaSesudah: data?.navigasi.sesudah == null ? null : n.berikutnya,
              ),
            ],
          ),
          isi: RefreshIndicator(
            onRefresh: n.muat,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              children: _isi(n, hariIni),
            ),
          ),
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

  List<Widget> _isi(RekapNotifier n, DateTime? hariIni) {
    final data = n.data;
    if (data != null && data.transaksi == 0) {
      return const [StateKosong('Tidak ada sumbangan pada periode ini', ikon: Icons.bar_chart)];
    }
    if (data != null) {
      return [
        _Ringkasan(data),
        // per_operator hanya diisi server untuk cakupan semua; daftarnya pendek, jadi tampil
        // sebelum rincian per hari yang bisa sampai 31 baris.
        if (data.cakupan == Cakupan.semua && data.perOperator.isNotEmpty) ...[
          const SizedBox(height: Jarak.antarKartu),
          _KartuRincian(
            judul: 'Rincian per operator',
            grafik: Center(child: DonatOperator(perOperator: data.perOperator)),
            baris: [
              for (final (i, operator) in data.perOperator.indexed)
                _BarisRincian(
                  judul: operator.nama,
                  transaksi: operator.transaksi,
                  total: operator.total,
                  warna: warnaOperator(operator, i),
                ),
            ],
          ),
        ],
        if (data.periode != Periode.hari && data.perHari.isNotEmpty) ...[
          const SizedBox(height: Jarak.antarKartu),
          _KartuRincian(
            judul: 'Rincian per hari',
            grafik: hariIni == null ? null : GrafikPerHari(rekap: data, hariIni: hariIni),
            baris: [
              for (final hari in data.perHari)
                _BarisRincian(
                  judul: formatTanggal(hari.tanggal),
                  transaksi: hari.transaksi,
                  total: hari.total,
                ),
            ],
          ),
        ],
      ];
    }
    if (n.status == StatusRekap.gagal) {
      return [
        PanelGalat(
          pesan: n.pesanGalat ?? TeksGalat.umum,
          labelTombol: 'Coba lagi',
          padaTombol: n.muat,
        ),
      ];
    }
    return const [KerangkaMemuat()];
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
    final gaya = Theme.of(context).textTheme.bodyLarge!.copyWith(color: Warna.diAtasPrimer);
    return Padding(
      padding: const EdgeInsets.only(top: Jarak.j4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: Warna.diAtasPrimer,
            disabledColor: Warna.diAtasPrimerNonaktif,
            tooltip: 'Periode sebelumnya',
            onPressed: padaSebelum,
          ),
          Expanded(child: Text(judul, textAlign: TextAlign.center, style: gaya)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: Warna.diAtasPrimer,
            disabledColor: Warna.diAtasPrimerNonaktif,
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
                    child: Text(
                      formatRupiah(data.total),
                      style: teks.headlineSmall!.copyWith(color: Warna.primer),
                      maxLines: 1,
                    ),
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

/// Kartu rincian: judul, grafik (bila ada), lalu baris rincian bergaris pemisah.
class _KartuRincian extends StatelessWidget {
  const _KartuRincian({required this.judul, required this.grafik, required this.baris});

  final String judul;
  final Widget? grafik;
  final List<Widget> baris;

  @override
  Widget build(BuildContext context) {
    final grafik = this.grafik;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.isiKartu, Jarak.isiKartu, Jarak.isiKartu, 0),
            child: Text(judul, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (grafik != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Jarak.isiKartu, Jarak.j16, Jarak.isiKartu, Jarak.j8),
              child: grafik,
            ),
          for (final (i, b) in baris.indexed) ...[
            if (i > 0) const Divider(height: Bentuk.garisPemisah),
            b,
          ],
        ],
      ),
    );
  }
}

/// Satu baris rincian: nama operator atau tanggal, banyaknya transaksi, dan total di kanan. Total
/// paling lebar separuh baris dan hurufnya mengecil bila tidak muat, seperti baris sumbangan. Baris
/// operator diawali titik legenda berwarna sama dengan bagiannya di donat.
class _BarisRincian extends StatelessWidget {
  const _BarisRincian({required this.judul, required this.transaksi, required this.total, this.warna});

  final String judul;
  final int transaksi;
  final int total;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final warna = this.warna;
    final gaya = Theme.of(context).textTheme.bodyLarge!.merge(Huruf.tebal);
    return LayoutBuilder(
      builder: (context, batas) => ListTile(
        leading: warna == null ? null : TitikLegenda(warna),
        minLeadingWidth: Bentuk.titikLegenda,
        title: Text(judul),
        subtitle: Text('${formatRibuan(transaksi)} transaksi'),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: batas.maxWidth / 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatRupiah(total), style: gaya, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
