// Layar Input Sumbangan, tab 1 dan layar awal (P2 docs/06_BUSINESS_PROCESS.md). Urutannya mengikuti
// langkah P2: ringkasan hari ini di kepala dasbor, lalu di lembar isi Nomor Donator + Cari + Cek, hasil
// Cek, Sumbangan (sebaris dengan centang Note bagi admin, K23), nominal cepat. Simpan dan panel galatnya
// tetap di bawah, supaya kartu donatur yang panjang tidak mendorongnya keluar layar. Ringkasan dilipat
// selama keyboard terbuka. Empat state Cek, Simpan, dan ringkasan: docs/26_UI_CONVENTIONS.md.

import 'package:flutter/material.dart';

import '../state/input_sumbangan_notifier.dart';
import '../state/kerangka_notifier.dart';
import '../state/sesi.dart';
import '../util/rupiah.dart';
import '../tema.dart';
import '../widget/dialog_konfirmasi.dart';
import '../widget/isian_angka.dart';
import '../widget/kartu_donatur.dart';
import '../widget/kartu_hasil.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/latar_dasbor.dart';
import '../widget/nominal_cepat.dart';
import '../widget/panel_galat.dart';
import '../widget/state_kosong.dart';
import '../widget/strip_hari_ini.dart';
import '../widget/tombol_utama.dart';
import 'cari_donatur.dart';

/// Nomor donatur 1–32767 (kontrak §6.3): paling banyak 5 digit.
const _digitNomor = 5;

/// `jumlah` paling besar 2.147.483.647 (kontrak §6.5): paling banyak 10 digit.
const _digitJumlah = 10;

class LayarInputSumbangan extends StatefulWidget {
  const LayarInputSumbangan({super.key});

  @override
  State<LayarInputSumbangan> createState() => _LayarInputSumbanganState();
}

class _LayarInputSumbanganState extends State<LayarInputSumbangan> {
  late final KerangkaNotifier _kerangka = KerangkaScope.baca(context);
  late final InputSumbanganNotifier _notifier = InputSumbanganNotifier(SesiScope.baca(context))
    ..addListener(_kembaliKeAtas);
  late final _berubah = Listenable.merge([_notifier, _notifier.jumlah]);
  final _gulir = ScrollController();
  Object? _hasilTerakhir;

  /// Tab Donatur memakai notifier ini lewat kerangka: Cek nomor dan strip hari ini (P3).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kerangka.daftarkanInput(_notifier);
  }

  @override
  void dispose() {
    _kerangka.lepasInput(_notifier);
    _notifier.dispose();
    _gulir.dispose();
    super.dispose();
  }

  /// Setelah tersimpan, layar kembali ke atas (tanpa animasi) agar Nomor Donator dan kartu hasil
  /// terlihat, walaupun Simpan ditekan saat formulir tergulir.
  void _kembaliKeAtas() {
    final hasil = _notifier.hasil;
    if (hasil == null || identical(hasil, _hasilTerakhir)) return;
    _hasilTerakhir = hasil;
    if (_gulir.hasClients) _gulir.jumpTo(0);
  }

  Future<bool> _tanya({String? judul, String? nama, required List<String> isi}) =>
      tampilkanDialogKonfirmasi(context, judul: judul, nama: nama, isi: isi);

  Future<void> _bukaCari() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const LayarCariDonatur()),
    );
    if (id != null && mounted) await _notifier.pilihDonatur(id);
  }

  @override
  Widget build(BuildContext context) {
    final nominal = [
      for (final nilai in SesiScope.of(context).konfigurasi?.nominalUmum ?? const <int>[])
        if (nilai <= batasNominalCepat) nilai,
    ];
    return ListenableBuilder(
      listenable: _berubah,
      builder: (context, _) {
        final n = _notifier;
        final terkunci = n.isianTerkunci;
        final simpanMemuat = n.statusSimpan == StatusSimpan.memuat;
        return LatarDasbor(
          kepala: _Ringkasan(notifier: n),
          lipatSaatKeyboard: true,
          isi: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  controller: _gulir,
                  padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, Jarak.j12, Jarak.tepiLayar, Jarak.j8),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: IsianAngka(
                            label: 'Nomor Donator',
                            controller: n.nomor,
                            focusNode: n.fokusNomor,
                            errorText: n.galatNomor,
                            maksDigit: _digitNomor,
                            enabled: !terkunci,
                            padat: true,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => n.cek(),
                          ),
                        ),
                        const SizedBox(width: Jarak.j4),
                        IconButton(
                          icon: const Icon(Icons.search),
                          color: Warna.primer,
                          tooltip: 'Cari Donatur',
                          onPressed: terkunci ? null : _bukaCari,
                        ),
                        const SizedBox(width: Jarak.j4),
                        OutlinedButton(
                          style: GayaTombol.cek,
                          onPressed: n.bisaCek ? n.cek : null,
                          child: n.statusCek == StatusCek.memuat
                              ? const IndikatorTombol()
                              : const Text('Cek'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Jarak.antarIsianRapat),
                    if (n.statusCek == StatusCek.gagal && n.pesanCek != null) ...[
                      PanelGalat(
                        pesan: n.pesanCek!,
                        labelTombol: n.tombolCek == TombolPanel.cobaLagi ? 'Coba lagi' : null,
                        padaTombol: n.bisaCek ? n.cek : null,
                      ),
                      const SizedBox(height: Jarak.antarIsianRapat),
                    ],
                    if (n.donatur case final donatur?) ...[
                      KartuDonatur(key: ObjectKey(donatur), donatur: donatur),
                      const SizedBox(height: Jarak.antarIsianRapat),
                    ] else if (n.hasil case final hasil?) ...[
                      KartuHasil(
                        key: ObjectKey(hasil),
                        pesan: 'Data Sumbangan Berhasil Disimpan',
                        judul: hasil.namaDonatur ?? '(donatur terhapus)',
                        jumlah: hasil.jumlah,
                        waktu: hasil.waktu,
                        noteN: hasil.noteN,
                      ),
                      const SizedBox(height: Jarak.antarIsianRapat),
                    ] else if (n.statusCek == StatusCek.kosong)
                      const StateKosong('Ketik nomor donatur lalu tekan Cek', ikon: Icons.add_card),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: IsianAngka(
                            label: 'Sumbangan',
                            controller: n.jumlah,
                            focusNode: n.fokusJumlah,
                            errorText: n.galatJumlah,
                            maksDigit: _digitJumlah,
                            enabled: !terkunci,
                            padat: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => n.simpan(_tanya),
                          ),
                        ),
                        // Sebaris dengan Sumbangan, supaya layar Input tetap muat tanpa digulir.
                        if (n.bolehAturNote) ...[
                          const SizedBox(width: Jarak.j4),
                          _PilihanNote(nilai: n.noteY, padaUbah: terkunci ? null : n.aturNote),
                        ],
                      ],
                    ),
                    const SizedBox(height: Jarak.j8),
                    NominalCepat(
                      nominal: nominal,
                      terpilih: bacaAngka(n.jumlah.text),
                      padaPilih: terkunci ? null : n.pilihNominal,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar, vertical: Jarak.j8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (n.statusSimpan == StatusSimpan.gagal && n.pesanSimpan != null) ...[
                      PanelGalat(
                        pesan: n.pesanSimpan!,
                        labelTombol: switch (n.tombolSimpan) {
                          TombolPanel.tidakAda => null,
                          TombolPanel.cobaLagi => 'Coba lagi',
                          TombolPanel.kirimUlang => 'Kirim ulang',
                        },
                        padaTombol: () => n.kirimUlang(_tanya),
                      ),
                      const SizedBox(height: Jarak.j8),
                    ],
                    TombolUtama(
                      onPressed: n.bisaSimpan ? () => n.simpan(_tanya) : null,
                      child: simpanMemuat ? const IndikatorTombol() : const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Centang Note bagi admin (K23): tercentang = Note y (bawaan), kosong = Note n. Label ikut bisa diketuk.
class _PilihanNote extends StatelessWidget {
  const _PilihanNote({required this.nilai, required this.padaUbah});

  final bool nilai;
  final ValueChanged<bool>? padaUbah;

  @override
  Widget build(BuildContext context) {
    final ubah = padaUbah;
    return MergeSemantics(
      child: InkWell(
        onTap: ubah == null ? null : () => ubah(!nilai),
        borderRadius: BorderRadius.circular(Bentuk.radiusIsian),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Bentuk.targetSentuh),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: nilai, onChanged: ubah == null ? null : (v) => ubah(v ?? true)),
              Text('Note', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: Jarak.j8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isi kepala tab Input: ringkasan hari ini, kerangka memuat di kepala, atau panel galat dengan Coba lagi.
class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.notifier});

  final InputSumbanganNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final n = notifier;
    return switch (n.statusStrip) {
      StatusStrip.sukses => StripHariIni(total: n.totalHariIni, transaksi: n.transaksiHariIni),
      StatusStrip.memuat => const KerangkaMemuat.kepala(),
      StatusStrip.gagal => PanelGalat(
          pesan: teksGalat(n.galatStrip ?? const Object(), post: false),
          labelTombol: 'Coba lagi',
          padaTombol: n.muatStrip,
        ),
    };
  }
}
