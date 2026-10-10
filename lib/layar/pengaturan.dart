// Pengaturan (P7 docs/06_BUSINESS_PROCESS.md): Alamat Server, Simpan, Pakai alamat bawaan, dan
// informasi diagnosa (docs/15_OBSERVABILITY.md). Alamat yang berganti saat sudah masuk menghapus
// token, lalu Sesi membuka layar Masuk.

import 'package:flutter/material.dart';

import '../api/klien_api.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../util/tanggal.dart';
import '../widget/kerangka_memuat.dart';

class LayarPengaturan extends StatefulWidget {
  const LayarPengaturan({super.key});

  @override
  State<LayarPengaturan> createState() => _LayarPengaturanState();
}

class _LayarPengaturanState extends State<LayarPengaturan> {
  late final _alamat = TextEditingController(text: SesiScope.baca(context).alamatServer);
  var _menyimpan = false;
  String? _galat;
  String? _sukses;

  @override
  void dispose() {
    _alamat.dispose();
    super.dispose();
  }

  /// [alamat] `null` = Pakai alamat bawaan.
  Future<void> _simpan(String? alamat) async {
    final sesi = SesiScope.baca(context);
    setState(() {
      _menyimpan = true;
      _galat = null;
      _sukses = null;
    });
    final galat = await sesi.ubahAlamat(alamat);
    if (!mounted) return;
    setState(() {
      _menyimpan = false;
      _galat = galat;
      if (galat == null) {
        _alamat.text = sesi.alamatServer;
        _sukses = 'Alamat server tersimpan.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sesi = SesiScope.of(context);
    final pengguna = sesi.konfigurasi?.pengguna;
    final kedaluwarsa = sesi.kedaluwarsa;
    final teks = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(Jarak.tepiLayar),
        children: [
          TextField(
            controller: _alamat,
            enabled: !_menyimpan,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _simpan(_alamat.text),
            decoration: InputDecoration(labelText: 'Alamat Server', errorText: _galat),
          ),
          if (_sukses case final pesan?) ...[
            const SizedBox(height: Jarak.j8),
            Semantics(
              liveRegion: true,
              child: Text(pesan, style: teks.bodyMedium!.copyWith(color: Warna.teksSukses)),
            ),
          ],
          const SizedBox(height: Jarak.antarIsian),
          FilledButton(
            onPressed: _menyimpan ? null : () => _simpan(_alamat.text),
            child: _menyimpan ? const IndikatorTombol() : const Text('Simpan'),
          ),
          const SizedBox(height: Jarak.antarTombol),
          TextButton(
            onPressed: _menyimpan || sesi.alamatBawaan.isEmpty ? null : () => _simpan(null),
            child: const Text('Pakai alamat bawaan'),
          ),
          const SizedBox(height: Jarak.j24),
          const Divider(height: Bentuk.garisPemisah),
          const SizedBox(height: Jarak.j8),
          _Info('Versi aplikasi', versiAplikasi),
          _Info('Versi kontrak', versiKontrak),
          _Info('Versi API server', sesi.versiServer),
          _Info('Alamat server', sesi.alamatServer.isEmpty ? null : sesi.alamatServer),
          _Info('Username', pengguna?.username),
          _Info('Peran', pengguna?.peran),
          _Info('Token berlaku sampai', kedaluwarsa == null ? null : formatWaktuIso(kedaluwarsa)),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.nilai);

  final String label;
  final String? nilai;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Jarak.j8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: teks.bodyMedium!.copyWith(color: Warna.teksLemah)),
          Text(nilai ?? '—', style: teks.bodyLarge),
        ],
      ),
    );
  }
}
