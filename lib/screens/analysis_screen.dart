import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // fl_chart paketini ekledik
import '../services/auth_service.dart';

class AnalizScreen extends StatefulWidget {
  const AnalizScreen({super.key});

  @override
  State<AnalizScreen> createState() => _AnalizScreenState();
}

class _AnalizScreenState extends State<AnalizScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late TabController _tabController;

  // Haftalık veri
  Map<String, dynamic>? _haftalikVeri;
  bool _haftalikYukleniyor = true;

  // Aylık veri
  Map<String, dynamic>? _aylikVeri;
  bool _aylikYukleniyor = true;

  // Görüntülenen ay
  DateTime _secilenAy = DateTime(DateTime.now().year, DateTime.now().month);

  final List<String> _aylar = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _haftalikVeriYukle();
    _aylikVeriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _haftalikVeriYukle() async {
    setState(() => _haftalikYukleniyor = true);
    final veri = await _authService.haftalikAnalizGetir();
    if (mounted) {
      setState(() {
        _haftalikVeri = veri;
        _haftalikYukleniyor = false;
      });
    }
  }

  Future<void> _aylikVeriYukle() async {
    setState(() => _aylikYukleniyor = true);
    final veri = await _authService.aylikAnalizGetir(
      _secilenAy.year,
      _secilenAy.month,
    );
    if (mounted) {
      setState(() {
        _aylikVeri = veri;
        _aylikYukleniyor = false;
      });
    }
  }

  void _oncekiAy() {
    setState(
      () => _secilenAy = DateTime(_secilenAy.year, _secilenAy.month - 1),
    );
    _aylikVeriYukle();
  }

  void _sonrakiAy() {
    setState(
      () => _secilenAy = DateTime(_secilenAy.year, _secilenAy.month + 1),
    );
    _aylikVeriYukle();
  }

  // ─── RENKLER ───
  Color get _birincilRenk => const Color(0xFF8A3460);
  Color get _ikincilRenk => const Color(0xFF5C6BC0);
  Color get _kolayRenk => Colors.green;
  Color get _ortaRenk => Colors.orange;
  Color get _zorRenk => Colors.red;

  // ─────────────────────────────────────────────────────────────
  //  YARDIMCI WİDGETLER
  // ─────────────────────────────────────────────────────────────

  // Özet kart (üst satırdaki küçük kartlar)
  Widget _ozetKart(String baslik, String deger, Color renk, IconData ikon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renk.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 22),
            const SizedBox(height: 6),
            Text(
              deger,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: renk,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // YENİ: Line Chart (Çizgi Grafik) Widget'ı
  Widget _lineChart(Map<String, int> veriler, Color cizgiRengi) {
    final keys = veriler.keys.toList();
    final values = veriler.values.toList();

    // Verileri grafikte göstermek için FlSpot formatına çeviriyoruz
    final spots = List.generate(
      keys.length,
      (index) => FlSpot(index.toDouble(), values[index].toDouble()),
    );

    // Y ekseninin maksimum değerini belirliyoruz ki grafik çok basık durmasın
    final maxYValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = maxYValue > 0
        ? maxYValue * 1.2
        : 5.0; // Üstte biraz boşluk kalsın
    final yInterval = (maxYValue / 4).ceilToDouble() > 0
        ? (maxYValue / 4).ceilToDouble()
        : 1.0;

    return AspectRatio(
      aspectRatio: 1.8, // Grafiğin en-boy oranı
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18.0,
          left: 0,
          top: 10,
          bottom: 0,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false, // Sadece yatay kılavuz çizgileri
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  strokeWidth: 1,
                  dashArray: [5, 5], // Kesik kesik çizgiler
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < keys.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          keys[index], // X eksenindeki metinler (Pzt, 1.Hafta vb.)
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: yInterval,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value == value.toInt().toDouble() && value >= 0) {
                      return Text(
                        value.toInt().toString(), // Y eksenindeki puanlar
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.right,
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false), // Çerçeveyi kaldırdık
            minX: 0,
            maxX: (keys.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true, // Çizgi yumuşak kavisli olsun
                color: cizgiRengi,
                barWidth: 3, // Çizgi kalınlığı
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true, // Noktalar görünsün
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: cizgiRengi,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).cardColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true, // Çizginin altı hafif renkli/gölgeli dolsun
                  color: cizgiRengi.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Zorluk dağılım satırı
  Widget _zorlukDagilimi(int kolay, int orta, int zor) {
    final toplam = kolay + orta + zor;
    if (toplam == 0) {
      return Text(
        'Henüz tamamlanan görev yok.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }

    Widget zorlukSatiri(String etiket, int sayi, Color renk) {
      final oran = sayi / toplam;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                etiket,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: oran,
                  minHeight: 10,
                  backgroundColor: renk.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(renk),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$sayi  (%${(oran * 100).toInt()})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        zorlukSatiri('Kolay', kolay, _kolayRenk),
        zorlukSatiri('Orta', orta, _ortaRenk),
        zorlukSatiri('Zor', zor, _zorRenk),
      ],
    );
  }

  // Bölüm başlığı
  Widget _bolumBasligi(String baslik, IconData ikon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: _birincilRenk),
          const SizedBox(width: 8),
          Text(
            baslik,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // Kart sarmalayıcı
  Widget _kart(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.15),
        ),
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HAFTALIK SEKME
  // ─────────────────────────────────────────────────────────────
  Widget _haftalikSekme() {
    if (_haftalikYukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_haftalikVeri == null) {
      return const Center(child: Text('Veri yüklenemedi.'));
    }

    final veri = _haftalikVeri!;
    final toplamPuan = veri['toplamPuan'] as int;
    final toplamGorev = veri['toplamGorev'] as int;
    final tamamlanan = veri['tamamlanan'] as int;
    final kolay = veri['kolay'] as int;
    final orta = veri['orta'] as int;
    final zor = veri['zor'] as int;
    final enVerimliGun = veri['enVerimliGun'] as String;
    final gunlukPuanlar = Map<String, int>.from(veri['gunlukPuanlar']);
    final tamamlanmaYuzdesi = toplamGorev == 0
        ? 0
        : (tamamlanan / toplamGorev * 100).toInt();

    return RefreshIndicator(
      onRefresh: _haftalikVeriYukle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet kartlar
            Row(
              children: [
                _ozetKart(
                  'Toplam\nPuan',
                  '$toplamPuan',
                  _birincilRenk,
                  Icons.star_rounded,
                ),
                const SizedBox(width: 10),
                _ozetKart(
                  'Tamamlanan',
                  '$tamamlanan/$toplamGorev',
                  _ikincilRenk,
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 10),
                _ozetKart(
                  'Başarı\nOranı',
                  '%$tamamlanmaYuzdesi',
                  Colors.teal,
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Günlük puan grafiği (Değişen kısım)
            _kart(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bolumBasligi(
                    'Günlük Puan Dağılımı',
                    Icons.show_chart,
                  ), // İkon değişti
                  const SizedBox(height: 10),
                  _lineChart(
                    gunlukPuanlar,
                    _birincilRenk,
                  ), // Çizgi grafiği eklendi
                  if (enVerimliGun != '-') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'En verimli gün: $enVerimliGun',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Zorluk dağılımı
            _kart(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bolumBasligi(
                    'Tamamlanan Görev Zorluk Dağılımı',
                    Icons.pie_chart_outline,
                  ),
                  _zorlukDagilimi(kolay, orta, zor),
                ],
              ),
            ),

            // Puan açıklaması
            _kart(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bolumBasligi('Puan Sistemi', Icons.info_outline),
                  _puanAciklamasiSatiri('Kolay görev', 1, _kolayRenk),
                  _puanAciklamasiSatiri('Orta görev', 3, _ortaRenk),
                  _puanAciklamasiSatiri('Zor görev', 5, _zorRenk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _puanAciklamasiSatiri(String etiket, int puan, Color renk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: renk),
            ),
            child: Text(
              etiket,
              style: TextStyle(
                color: renk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+$puan puan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  AYLIK SEKME
  // ─────────────────────────────────────────────────────────────
  Widget _aylikSekme() {
    return Column(
      children: [
        // Ay seçici
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _oncekiAy,
              ),
              Text(
                '${_aylar[_secilenAy.month - 1]} ${_secilenAy.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _sonrakiAy,
              ),
            ],
          ),
        ),

        Expanded(
          child: _aylikYukleniyor
              ? const Center(child: CircularProgressIndicator())
              : _aylikVeri == null
              ? const Center(child: Text('Veri yüklenemedi.'))
              : RefreshIndicator(
                  onRefresh: _aylikVeriYukle,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _aylikIcerik(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _aylikIcerik() {
    final veri = _aylikVeri!;
    final toplamPuan = veri['toplamPuan'] as int;
    final toplamGorev = veri['toplamGorev'] as int;
    final tamamlanan = veri['tamamlanan'] as int;
    final tamamlanmaOrani = (veri['tamamlanmaOrani'] as double).toInt();
    final kolay = veri['kolay'] as int;
    final orta = veri['orta'] as int;
    final zor = veri['zor'] as int;
    final enVerimliHafta = veri['enVerimliHafta'] as String;
    final haftalikPuanlar = Map<String, int>.from(veri['haftalikPuanlar']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Özet kartlar
        Row(
          children: [
            _ozetKart(
              'Toplam\nPuan',
              '$toplamPuan',
              _birincilRenk,
              Icons.star_rounded,
            ),
            const SizedBox(width: 10),
            _ozetKart(
              'Tamamlanan',
              '$tamamlanan/$toplamGorev',
              _ikincilRenk,
              Icons.check_circle_outline,
            ),
            const SizedBox(width: 10),
            _ozetKart(
              'Başarı\nOranı',
              '%$tamamlanmaOrani',
              Colors.teal,
              Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tamamlanma oranı dairesel gösterge
        _kart(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bolumBasligi('Aylık Tamamlanma Oranı', Icons.donut_large),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: tamamlanmaOrani / 100,
                            strokeWidth: 10,
                            backgroundColor: _birincilRenk.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _birincilRenk,
                            ),
                          ),
                        ),
                        Text(
                          '%$tamamlanmaOrani',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _birincilRenk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniSatir(
                          'Toplam görev',
                          '$toplamGorev',
                          Icons.list_alt,
                        ),
                        _miniSatir(
                          'Tamamlanan',
                          '$tamamlanan',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _miniSatir(
                          'Tamamlanmayan',
                          '${toplamGorev - tamamlanan}',
                          Icons.cancel_outlined,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Haftalık puan grafiği (Değişen kısım)
        _kart(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bolumBasligi(
                'Haftalık Puan Dağılımı',
                Icons.show_chart,
              ), // İkon değişti
              const SizedBox(height: 10),
              _lineChart(
                haftalikPuanlar,
                _ikincilRenk,
              ), // Çizgi grafiği eklendi
              if (enVerimliHafta != '-') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En verimli hafta: $enVerimliHafta',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Zorluk dağılımı
        _kart(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bolumBasligi(
                'Tamamlanan Görev Zorluk Dağılımı',
                Icons.pie_chart_outline,
              ),
              _zorlukDagilimi(kolay, orta, zor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniSatir(String etiket, String deger, IconData ikon, [Color? renk]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ikon,
            size: 14,
            color:
                renk ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Text(
            deger,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: renk ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz'),
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),

        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.view_week), text: 'Haftalık'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Aylık'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_haftalikSekme(), _aylikSekme()],
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
    );
  }
}
