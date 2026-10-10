// Kerangka: AppBar + NavigationBar 4 tab + IndexedStack (docs/08_ARCHITECTURE.md, docs/26_UI_CONVENTIONS.md).
// IndexedStack menjaga isian setiap tab tetap ada saat berpindah tab, juga saat layar Masuk
// didorong di atasnya karena 401. Menu ⋮: Pengaturan dan Keluar (P7 docs/06_BUSINESS_PROCESS.md).
// Tab aktif dan pesan antartab ada di KerangkaNotifier. Tab 1 Input Sumbangan sejak S2, tab 2
// Tambah Donatur sejak S3, tab 3 Input Saya sejak S4, tab 4 Rekap sejak S5 (docs/03_ROADMAP.md).

import 'package:flutter/material.dart';

import '../state/kerangka_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../widget/dialog_konfirmasi.dart';
import 'input_saya.dart';
import 'input_sumbangan.dart';
import 'pengaturan.dart';
import 'rekap.dart';
import 'tambah_donatur.dart';

enum _Menu { pengaturan, keluar }

class LayarKerangka extends StatefulWidget {
  const LayarKerangka({super.key, this.isiTab});

  /// Isi keempat tab, urut seperti label tab. Tanpa nilai, tab berisi layar yang sudah ada.
  final List<Widget>? isiTab;

  @override
  State<LayarKerangka> createState() => _LayarKerangkaState();
}

class _LayarKerangkaState extends State<LayarKerangka> {
  static const _daftarTab = [
    (judul: 'Input Sumbangan', label: 'Input', ikon: Icons.add_card),
    (judul: 'Tambah Donatur', label: 'Donatur', ikon: Icons.person_add_alt_1),
    (judul: 'Input Saya', label: 'Input Saya', ikon: Icons.receipt_long),
    (judul: 'Rekap', label: 'Rekap', ikon: Icons.bar_chart),
  ];

  final _kerangka = KerangkaNotifier();

  @override
  void dispose() {
    _kerangka.dispose();
    super.dispose();
  }

  Future<void> _pilihMenu(_Menu menu) async {
    final sesi = SesiScope.baca(context);
    switch (menu) {
      case _Menu.pengaturan:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LayarPengaturan()),
        );
      case _Menu.keluar:
        final keluar = !sesi.adaIsianBelumDisimpan ||
            await tampilkanDialogKonfirmasi(
              context,
              isi: const ['Isian yang belum disimpan akan hilang. Keluar?'],
              tombolTidak: 'Batal',
              tombolYa: 'Keluar',
            );
        if (keluar) await sesi.keluar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isiTab = widget.isiTab ??
        const [LayarInputSumbangan(), LayarTambahDonatur(), LayarInputSaya(), LayarRekap()];
    return KerangkaScope(
      kerangka: _kerangka,
      child: ListenableBuilder(
        listenable: _kerangka,
        builder: (context, _) => _bangun(isiTab, _kerangka.tab),
      ),
    );
  }

  Widget _bangun(List<Widget> isiTab, int aktif) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_daftarTab[aktif].judul),
        actions: [
          PopupMenuButton<_Menu>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: _pilihMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Menu.pengaturan, child: Text('Pengaturan')),
              PopupMenuItem(value: _Menu.keluar, child: Text('Keluar')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: aktif, children: isiTab),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Warna.garis, width: Bentuk.garisPemisah)),
        ),
        child: NavigationBar(
          selectedIndex: aktif,
          onDestinationSelected: _kerangka.pilihTab,
          destinations: [
            for (final tab in _daftarTab)
              NavigationDestination(icon: Icon(tab.ikon), label: tab.label),
          ],
        ),
      ),
    );
  }
}
