// Kerangka: AppBar + NavigationBar 4 tab + IndexedStack (docs/08_ARCHITECTURE.md, docs/26_UI_CONVENTIONS.md).
// IndexedStack menjaga isian setiap tab tetap ada saat berpindah tab.

import 'package:flutter/material.dart';

import '../tema.dart';

class LayarKerangka extends StatefulWidget {
  const LayarKerangka({super.key});

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

  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_daftarTab[_tab].judul)),
      body: IndexedStack(
        index: _tab,
        children: [for (final _ in _daftarTab) const SizedBox.expand()],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Warna.garis, width: Bentuk.garisPemisah)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (indeks) => setState(() => _tab = indeks),
          destinations: [
            for (final tab in _daftarTab)
              NavigationDestination(icon: Icon(tab.ikon), label: tab.label),
          ],
        ),
      ),
    );
  }
}
