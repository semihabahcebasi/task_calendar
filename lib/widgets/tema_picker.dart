import 'package:flutter/material.dart';

const Map<String, List<String>> temaListesi = {
  'anime': [
    'anime3',
    'anime4',
    'anime5',
    'anime6',
    'anime7',
    'anime8',
    'anime9',
    'anime10',
  ],
  'soft': [
    'soft1',
    'soft2',
    'soft3',
    'soft4',
    'soft5',
    'soft6',
    'soft7',
    'soft8',
    'soft9',
    'soft10',
  ],
};

class TemaPicker extends StatefulWidget {
  final String? secilenKategori;
  final String? secilenTema;
  final Function(String kategori, String temaId) onTemaSec;

  const TemaPicker({
    super.key,
    required this.secilenKategori,
    required this.secilenTema,
    required this.onTemaSec,
  });

  @override
  State<TemaPicker> createState() => _TemaPickerState();
}

class _TemaPickerState extends State<TemaPicker> {
  String _aktifKategori = 'anime';

  @override
  void initState() {
    super.initState();
    if (widget.secilenKategori != null) {
      _aktifKategori = widget.secilenKategori!;
    }

    // Picker açılınca aktif kategorinin tüm görsellerini cache'le
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kategoriCachele(_aktifKategori);
    });
  }

  // Bir kategorideki tüm görselleri arka planda cache'e al
  void _kategoriCachele(String kategori) {
    if (!mounted) return;
    final temalar = temaListesi[kategori] ?? [];
    for (final tema in temalar) {
      precacheImage(AssetImage('assets/temalar/$kategori/$tema.png'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kategori butonları
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: temaListesi.keys.map((kategori) {
            final aktif = kategori == _aktifKategori;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _aktifKategori = kategori);
                  // Kategoriye geçildiğinde görsellerini hemen cache'le
                  _kategoriCachele(kategori);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: aktif ? Colors.indigo : Colors.grey[300],
                  foregroundColor: aktif ? Colors.white : Colors.black,
                ),
                child: Text(kategori.toUpperCase()),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Tema grid'i
        SizedBox(
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: temaListesi[_aktifKategori]!.length,
            itemBuilder: (context, index) {
              final tema = temaListesi[_aktifKategori]![index];
              final secili =
                  tema == widget.secilenTema &&
                  _aktifKategori == widget.secilenKategori;

              return GestureDetector(
                onTap: () => widget.onTemaSec(_aktifKategori, tema),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: secili ? Colors.blue : Colors.transparent,
                      width: 3,
                    ),
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/temalar/$_aktifKategori/$tema.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
