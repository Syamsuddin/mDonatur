// Grafik Rekap (docs/26_UI_CONVENTIONS.md §Inventaris), satu-satunya pemakai fl_chart. Grafik hanya
// menggambar angka jawaban `rekap`: tidak ada penjumlahan atau penyaringan di Dart. Tanggal yang tidak
// ada di `per_hari` bernilai 0, karena kontrak §6.9 hanya mengirim hari yang ada sumbangannya. Angka
// pastinya tetap terbaca di baris rincian di bawah grafik.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api/model.dart';
import '../tema.dart';
import '../util/tanggal.dart';

/// Warna baris ke-[urutan] `per_operator`: palet grafik, kecuali "User lama" (`id_user: null`).
Color warnaOperator(RekapOperator operator, int urutan) =>
    operator.idUser == null ? Warna.teksLemah : Warna.grafik(urutan);

/// Grafik area per hari (Minggu, Bulan): sumbu x dari `dari` sampai `sampai`, garis berhenti di
/// `hari_ini` server.
class GrafikPerHari extends StatelessWidget {
  const GrafikPerHari({super.key, required this.rekap, required this.hariIni});

  final Rekap rekap;
  final DateTime hariIni;

  @override
  Widget build(BuildContext context) {
    final r = rekap;
    final perTanggal = {for (final hari in r.perHari) hari.tanggal: hari.total};
    final akhir = r.sampai.isAfter(hariIni) ? hariIni : r.sampai;
    final titik = <FlSpot>[
      for (var i = 0, t = r.dari; !t.isAfter(akhir); i++, t = t.add(const Duration(days: 1)))
        FlSpot(i.toDouble(), (perTanggal[t] ?? 0).toDouble()),
    ];
    if (titik.isEmpty) return const SizedBox.shrink();
    final pekan = r.periode == Periode.minggu;
    // Titik hari ini hanya ada bila periodenya memuat hari_ini; titik itu selalu yang terakhir.
    final iHariIni = akhir == hariIni ? titik.length - 1 : -1;
    final puncak = titik.map((t) => t.y).reduce(math.max);
    final kecil = Theme.of(context).textTheme.labelMedium!;
    return Semantics(
      container: true,
      label: 'Grafik rincian per hari',
      child: ExcludeSemantics(
        child: SizedBox(
          height: Bentuk.tinggiGrafik,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: r.sampai.difference(r.dari).inDays.toDouble(),
              minY: 0,
              // Ruang di atas puncak agar titik dan garis tidak terpotong tepi.
              maxY: puncak <= 0 ? 1 : puncak * 1.2,
              lineTouchData: const LineTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Warna.garisLembut, strokeWidth: Bentuk.garisPemisah),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: Jarak.j24,
                    interval: pekan ? 1 : 7,
                    getTitlesWidget: (nilai, meta) {
                      final i = nilai.round();
                      final tanggal = r.dari.add(Duration(days: i));
                      final kini = i == iHariIni;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          labelSumbuGrafik(tanggal, pekan: pekan),
                          style: kecil.copyWith(color: kini ? Warna.primer : Warna.teksLemah),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: titik,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: Warna.primer,
                  barWidth: Bentuk.garisGrafik,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(show: true, gradient: Gradien.areaGrafik),
                  dotData: FlDotData(
                    checkToShowDot: (titik, _) => titik.x.round() == iHariIni,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: Bentuk.titikHariIni,
                      color: Warna.primer,
                      strokeWidth: Bentuk.cincinHariIni,
                      strokeColor: Warna.kuningLembut,
                    ),
                  ),
                ),
              ],
            ),
            duration: Gerak.aktif(context) ? Gerak.grafik : Duration.zero,
            curve: Gerak.kurva,
          ),
        ),
      ),
    );
  }
}

/// Donat per operator (cakupan Semua operator): satu bagian per baris `per_operator`, urut server.
class DonatOperator extends StatelessWidget {
  const DonatOperator({super.key, required this.perOperator});

  final List<RekapOperator> perOperator;

  @override
  Widget build(BuildContext context) {
    const jari = Bentuk.donat / 2;
    return Semantics(
      container: true,
      label: 'Grafik rincian per operator',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: Bentuk.donat,
          child: PieChart(
            PieChartData(
              sections: [
                for (final (i, operator) in perOperator.indexed)
                  PieChartSectionData(
                    value: operator.total.toDouble(),
                    color: warnaOperator(operator, i),
                    radius: jari * (1 - Bentuk.lubangDonat),
                    showTitle: false,
                  ),
              ],
              centerSpaceRadius: jari * Bentuk.lubangDonat,
              sectionsSpace: Bentuk.garisFokus,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(enabled: false),
            ),
            duration: Gerak.aktif(context) ? Gerak.grafik : Duration.zero,
            curve: Gerak.kurva,
          ),
        ),
      ),
    );
  }
}

/// Titik legenda 12 dp, sebagai `leading` baris rincian per operator.
class TitikLegenda extends StatelessWidget {
  const TitikLegenda(this.warna, {super.key});

  final Color warna;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: Bentuk.titikLegenda,
      child: DecoratedBox(decoration: BoxDecoration(color: warna, shape: BoxShape.circle)),
    );
  }
}
