// Layar Cari Donatur (P2.2 docs/06_BUSINESS_PROCESS.md), didorong dari ikon cari di tab Input.
// Ketuk satu hasil → layar ditutup dengan nomor donatur itu, lalu tab Input mengisi nomor dan Cek.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/cari_donatur_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/panel_galat.dart';
import '../widget/state_kosong.dart';

class LayarCariDonatur extends StatefulWidget {
  const LayarCariDonatur({super.key});

  @override
  State<LayarCariDonatur> createState() => _LayarCariDonaturState();
}

class _LayarCariDonaturState extends State<LayarCariDonatur> {
  late final CariDonaturNotifier _notifier = CariDonaturNotifier(SesiScope.baca(context).klien);

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Donatur')),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          final n = _notifier;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(Jarak.tepiLayar),
                child: TextField(
                  controller: n.q,
                  autofocus: true,
                  inputFormatters: [LengthLimitingTextInputFormatter(panjangMaksimalCari)],
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => n.cari(),
                  decoration: InputDecoration(
                    labelText: 'Nama, alamat, atau nomor',
                    errorText: n.galatQ,
                    errorMaxLines: 3,
                  ),
                ),
              ),
              Expanded(child: _Isi(notifier: n)),
            ],
          );
        },
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.notifier});

  final CariDonaturNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final n = notifier;
    const tepi = EdgeInsets.symmetric(horizontal: Jarak.tepiLayar);
    return switch (n.status) {
      StatusCari.kosong =>
        ListView(children: const [StateKosong('Ketik minimal 2 huruf nama, alamat, atau nomor')]),
      StatusCari.memuat => ListView(padding: tepi, children: const [KerangkaMemuat()]),
      StatusCari.gagal => ListView(
          padding: tepi,
          children: [
            PanelGalat(pesan: n.pesanPanel ?? '', labelTombol: 'Coba lagi', padaTombol: n.cari),
          ],
        ),
      StatusCari.sukses when n.hasil.isEmpty =>
        ListView(children: const [StateKosong('Tidak ada donatur yang cocok')]),
      StatusCari.sukses => ListView(
          children: [
            if (n.lebih)
              Padding(
                padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, 0, Jarak.tepiLayar, Jarak.j8),
                child: Text(
                  'Persempit pencarian',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksInfo),
                ),
              ),
            for (final donatur in n.hasil)
              ListTile(
                title: Text(donatur.nama),
                subtitle: Text('${donatur.id} · ${donatur.alamat}'),
                onTap: () => Navigator.of(context).pop(donatur.id),
              ),
          ],
        ),
    };
  }
}
