import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Register',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
          primary: const Color(0xFF0D9488),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4BF),
          brightness: Brightness.dark,
          primary: const Color(0xFF2DD4BF),
          surface: const Color(0xFF141B26),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<List<dynamic>> baseProducts = [
    ["মিল্ক কেক", 72], ["মাফিন কেক", 48], ["ডপস ১০", 24], ["লুপস ৫", 48],
    ["লেক্সাস ৫", 48], ["লেক্সাস ১০", 24], ["লেক্সাস ফ্যামিলি", 1], ["মেরি ফ্যামিলি", 12],
    ["মিল্ক ৫", 48], ["ঘি ৫", 48], ["ঘি ১০", 24], ["ঘি ফ্যামিলি", 8],
    ["চকোলেট ১০", 48], ["এনার্জি ৫", 48], ["এনার্জি ১০", 24], ["এনার্জি ফ্যামিলি", 8],
    ["৪ পিসের নুডলস", 1], ["৮ পিসের নুডলস", 1], ["পাতা নুডলস", 12],
    ["১৫ গ্রাম মরিচ গুড়া", 1], ["৫০ গ্রাম মরিচ গুড়া", 1], ["১৫ গ্রাম হলুদ গুড়া", 1],
    ["৫০ গ্রাম হলুদ গুড়া", 1], ["হলুদ গুড়া ৫ কেজি", 1], ["মরিচ গুড়া ৫ কেজি", 1],
    ["মাংসের মশলা", 1], ["মুরগির মশলা", 1], ["গরু মাংসের মশলা", 1], ["মাছের মশলা", 1],
    ["১৫ গ্রাম জিরার গুরা", 1], ["৫০ গ্রাম জিরার গুরা", 1], ["বিরিয়ানি মশলা ৪০ গ্রাম", 1],
    ["সরিষ তেল ৮০ গ্রাম", 1], ["সরিষ তেল ২০০ গ্রাম", 1], ["ঘি টোস্ট মিনি", 96],
    ["ড্রাই কেক মিনি", 48], ["কোকোনাট ২০ টাকা", 8], ["কোকোনাট ফ্যামিলি", 24],
    ["৫ টাকা চানাচুর", 1], ["৩০ টাকা চানাচুর", 1], ["৫০ টাকা চানাচুর", 1],
    ["লাচ্ছা সেমাই", 1], ["ভার্মিচিলি সেমাই", 1], ["বালিশ সেমাই", 1], ["এগ নুডলস্", 24],
    ["তেঁতুল চাটনী", 1], ["১৫ গ্রাম চা", 1], ["৫০০ গ্রাম চা", 1], ["রোস্টের মশলা", 1]
  ];

  List<List<dynamic>> customProducts = [];
  Map<String, dynamic> deletedProducts = {};
  Map<String, dynamic> perCarton = {};
  Map<String, dynamic> sellPrices = {};
  Map<String, dynamic> dealerPrices = {};
  Map<String, dynamic> profitMargin = {};
  List<dynamic> logs = [];
  List<dynamic> marketEntries = [];
  List<dynamic> hisabPersons = [];
  bool autoNextProduct = true;

  // Form Controllers
  int selectedProductIdx = 0;
  final TextEditingController ctnController = TextEditingController();
  final TextEditingController pcsController = TextEditingController();
  final TextEditingController dealerRateController = TextEditingController();
  String entryDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Market Tab Controllers
  String marketDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int marketOutIdx = 0;
  final TextEditingController mb1 = TextEditingController();
  final TextEditingController mb2 = TextEditingController();
  final TextEditingController mbr = TextEditingController();
  bool mbAutoNext = true;

  // Market Return
  int? marketFerotIdx;
  final TextEditingController mf1 = TextEditingController();
  final TextEditingController mf2 = TextEditingController();
  final TextEditingController mfr = TextEditingController();
  bool showMarketSheet = false;

  // Stock Filter
  int stockMode = 0; // 0=Ekhon, 1=Tarikh obdhi, 2=Lenden
  String stockD1 = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String stockD2 = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String stockQuery = "";

  // Calc Tab
  int calcProductIdx = 0;
  int calcMode = -1; // -1 = Biyog, 1 = Jog
  final TextEditingController ca1 = TextEditingController();
  final TextEditingController ca2 = TextEditingController();
  final TextEditingController cb1 = TextEditingController();
  final TextEditingController cb2 = TextEditingController();

  // Summary Filter
  String sumD1 = "";
  String sumD2 = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('stk1');
    if (dataStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(dataStr);
        setState(() {
          customProducts = List<List<dynamic>>.from(data['custom'] ?? []);
          deletedProducts = Map<String, dynamic>.from(data['del'] ?? {});
          perCarton = Map<String, dynamic>.from(data['per'] ?? {});
          sellPrices = Map<String, dynamic>.from(data['pr'] ?? {});
          dealerPrices = Map<String, dynamic>.from(data['cp'] ?? {});
          profitMargin = Map<String, dynamic>.from(data['lv'] ?? {});
          logs = List<dynamic>.from(data['log'] ?? []);
          marketEntries = List<dynamic>.from(data['mk'] ?? []);
          hisabPersons = List<dynamic>.from(data['hp'] ?? []);
          autoNextProduct = data['nx'] ?? true;
        });
      } catch (_) {}
    }
    _setInitialProduct();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'custom': customProducts,
      'del': deletedProducts,
      'per': perCarton,
      'pr': sellPrices,
      'cp': dealerPrices,
      'lv': profitMargin,
      'log': logs,
      'mk': marketEntries,
      'hp': hisabPersons,
      'nx': autoNextProduct,
    };
    await prefs.setString('stk1', jsonEncode(data));
  }

  List<List<dynamic>> get allProducts => [...baseProducts, ...customProducts];

  List<int> get activeProductIndices {
    List<int> list = [];
    for (int i = 0; i < allProducts.length; i++) {
      if (deletedProducts[i.toString()] != true) {
        list.add(i);
      }
    }
    return list;
  }

  void _setInitialProduct() {
    final active = activeProductIndices;
    if (active.isNotEmpty) {
      if (!active.contains(selectedProductIdx)) selectedProductIdx = active.first;
      if (!active.contains(marketOutIdx)) marketOutIdx = active.first;
      if (!active.contains(calcProductIdx)) calcProductIdx = active.first;
      _updateDealerRateField();
      _updateMarketRateField();
    }
  }

  int getPcsPerCtn(int i) {
    if (perCarton.containsKey(i.toString())) return (perCarton[i.toString()] as num).toInt();
    if (i < allProducts.length) return (allProducts[i][1] as num).toInt();
    return 1;
  }

  double getSellPrice(int i) => (sellPrices[i.toString()] as num?)?.toDouble() ?? 0.0;
  double getDealerPrice(int i) => (dealerPrices[i.toString()] as num?)?.toDouble() ?? 0.0;
  double getProfitMargin(int i) => (profitMargin[i.toString()] as num?)?.toDouble() ?? 0.0;

  double getAvgCost(int i, [String? maxDate]) {
    double q = 0, v = 0;
    for (var e in logs) {
      if (e['i'] != i || e['t'] == 'out' || (maxDate != null && maxDate.isNotEmpty && e['d'].toString().compareTo(maxDate) > 0)) continue;
      double cp = (e['cp'] != null && (e['cp'] as num) > 0) ? (e['cp'] as num).toDouble() : getDealerPrice(i);
      int k = getPcsPerCtn(i);
      double qq = ((e['c'] ?? 0) as num).toDouble() * k + ((e['p'] ?? 0) as num).toDouble();
      q += qq;
      v += qq * cp;
    }
    return q > 0 ? (v / q) : getDealerPrice(i);
  }

  int getStock(int i) {
    int k = getPcsPerCtn(i);
    int totalIn = 0;
    for (var e in logs) {
      if (e['i'] == i) {
        totalIn += (((e['c'] ?? 0) as num).toInt() * k + ((e['p'] ?? 0) as num).toInt());
      }
    }
    int totalOut = 0;
    for (var r in marketEntries) {
      if (r['i'] == i) {
        int g = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt());
        int f = (((r['fc'] ?? 0) as num).toInt() * k + ((r['fp'] ?? 0) as num).toInt());
        totalOut += (g - f);
      }
    }
    return totalIn - totalOut;
  }

  String formatQty(int totalPcs, int k) {
    int u = totalPcs.abs();
    int c = u ~/ k;
    int p = u % k;
    return "${totalPcs < 0 ? '-' : ''}$c ctn $p pcs";
  }

  String money(num v) => NumberFormat("#,##0", "en_IN").format(v.round());
  String moneyDecimal(num v) => NumberFormat("#,##0.00", "en_IN").format(v);

  void _updateDealerRateField() {
    double cp = getDealerPrice(selectedProductIdx);
    dealerRateController.text = cp > 0 ? cp.toString() : "";
  }

  void _updateMarketRateField() {
    double pr = getSellPrice(marketOutIdx);
    mbr.text = pr > 0 ? pr.toString() : "";
  }

  void _stepProduct(int step) {
    final active = activeProductIndices;
    if (active.isEmpty) return;
    int cur = active.indexOf(selectedProductIdx);
    if (cur == -1) cur = 0;
    int next = (cur + step).clamp(0, active.length - 1);
    setState(() {
      selectedProductIdx = active[next];
      _updateDealerRateField();
    });
  }

  // Save stock intake
  void _saveEntry() {
    double c = double.tryParse(ctnController.text) ?? 0;
    double p = double.tryParse(pcsController.text) ?? 0;
    if (c == 0 && p == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কার্টুন অথবা পিস লিখুন!')));
      return;
    }
    double? cp = double.tryParse(dealerRateController.text);
    if (cp != null && cp > 0) {
      dealerPrices[selectedProductIdx.toString()] = cp;
    }

    final entry = {
      'id': DateTime.now().microsecondsSinceEpoch,
      'd': entryDate,
      't': 'open',
      'i': selectedProductIdx,
      'c': c,
      'p': p,
      'cp': cp ?? getDealerPrice(selectedProductIdx),
    };

    setState(() {
      logs.add(entry);
      ctnController.clear();
      pcsController.clear();
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save hoyeche ✓'), backgroundColor: Color(0xFF0D9488), duration: Duration(seconds: 1)),
    );

    if (autoNextProduct) _stepProduct(1);
  }

  // Product Selection with Search & Long Press Delete
  void _openProductPicker({required Function(int) onSelect}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final active = activeProductIndices.where((idx) {
              final name = allProducts[idx][0].toString().toLowerCase();
              return query.isEmpty || name.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('পণ্য তালিকা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Text('💡 ট্যাপ করলে সিলেক্ট হবে · চেপে ধরে রাখলে (Long Press) ডিলিট অপশন আসবে',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '🔍 পণ্য খুঁজুন...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: active.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final i = active[index];
                        final name = allProducts[i][0];
                        final pcs = getPcsPerCtn(i);
                        final pr = getSellPrice(i);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            onSelect(i);
                            Navigator.pop(context);
                          },
                          onLongPress: () {
                            HapticFeedback.vibrate();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete korben?'),
                                content: Text("আপনি কি নিশ্চিত '$name' তালিকা থেকে ডিলিট করতে চান?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('না')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        deletedProducts[i.toString()] = true;
                                      });
                                      _saveData();
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      _setInitialProduct();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name ডিলিট হয়েছে ✓")));
                                    },
                                    child: const Text('হ্যাঁ, ডিলিট', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${i + 1}. $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text("১ কার্টুন = $pcs পিস ${pr > 0 ? '· $pr tk' : ''}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.teal),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Pcs/Ctn Rate Settings Modal
  void _openPcsCtnModal(int i) {
    final kCtrl = TextEditingController(text: getPcsPerCtn(i).toString());
    final dCtrl = TextEditingController(text: getSellPrice(i) > 0 ? getSellPrice(i).toString() : "");
    final pCtrl = TextEditingController(text: (getPcsPerCtn(i) > 0 && getSellPrice(i) > 0) ? (getSellPrice(i) / getPcsPerCtn(i)).toStringAsFixed(2) : "");
    final lvCtrl = TextEditingController(text: getProfitMargin(i) > 0 ? getProfitMargin(i).toString() : "");
    final cpCtrl = TextEditingController(text: getDealerPrice(i) > 0 ? getDealerPrice(i).toString() : "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(allProducts[i][0], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: kCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '১ কার্টুনে কত পিস?')),
              TextField(controller: dCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '১ কার্টুনের বিক্রি দাম (tk)')),
              TextField(controller: lvCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'লাভ % (বিক্রি দাম থেকে %)')),
              TextField(controller: cpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ক্রয় দর / ডিলার রেট (tk)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              int? kVal = int.tryParse(kCtrl.text);
              if (kVal != null && kVal > 0) perCarton[i.toString()] = kVal;
              sellPrices[i.toString()] = double.tryParse(dCtrl.text) ?? 0.0;
              dealerPrices[i.toString()] = double.tryParse(cpCtrl.text) ?? 0.0;
              profitMargin[i.toString()] = double.tryParse(lvCtrl.text) ?? 0.0;
              _saveData();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Product Details Modal
  void _openDetailsModal(int i) {
    int k = getPcsPerCtn(i);
    int totalIn = 0;
    for (var e in logs.where((x) => x['i'] == i)) {
      totalIn += (((e['c'] ?? 0) as num).toInt() * k + ((e['p'] ?? 0) as num).toInt());
    }
    int gTotal = 0, fTotal = 0;
    double sVal = 0;
    for (var r in marketEntries.where((x) => x['i'] == i)) {
      int g = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt());
      int f = (((r['fc'] ?? 0) as num).toInt() * k + ((r['fp'] ?? 0) as num).toInt());
      gTotal += g;
      fTotal += f;
      double rVal = (r['r'] as num?)?.toDouble() ?? 0.0;
      sVal += ((g - f) / k) * rVal;
    }
    int netSold = gTotal - fTotal;
    int current = totalIn - netSold;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(allProducts[i][0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text("১ কার্টুন = $k পিস | দাম: ${getSellPrice(i)} tk | ক্রয়দর: ${getDealerPrice(i)} tk", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Divider(height: 20),
            Text("স্টক যোগ (প্রথম): ${formatQty(totalIn, k)}"),
            Text("মার্কেটে গেল: ${formatQty(gTotal, k)}"),
            Text("ফেরত: ${formatQty(fTotal, k)}"),
            Text("বিক্রি: ${formatQty(netSold, k)} = ${moneyDecimal(sVal)} tk", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            Text("এখন আছে: ${formatQty(current, k)} ($current pcs)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
            const SizedBox(height: 10),
            const Text("ইতিহাস (লগ):", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: [
                  ...logs.where((x) => x['i'] == i).map((e) => ListTile(
                        dense: true,
                        title: Text("${e['d']} - প্রথম স্টক"),
                        subtitle: Text("${e['c']} ctn ${e['p']} pcs"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() => logs.remove(e));
                            _saveData();
                            Navigator.pop(ctx);
                          },
                        ),
                      )),
                  ...marketEntries.where((x) => x['i'] == i).map((r) => ListTile(
                        dense: true,
                        title: Text("${r['d']} - মার্কেট"),
                        subtitle: Text("গেল: ${r['gc']}c ${r['gp']}p | ফেরত: ${r['fc']}c ${r['fp']}p"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() => marketEntries.remove(r));
                            _saveData();
                            Navigator.pop(ctx);
                          },
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Backup & Restore
  void _showBackupDialog() {
    final textCtrl = TextEditingController(text: jsonEncode({
      'custom': customProducts,
      'del': deletedProducts,
      'per': perCarton,
      'pr': sellPrices,
      'cp': dealerPrices,
      'lv': profitMargin,
      'log': logs,
      'mk': marketEntries,
      'hp': hisabPersons,
      'nx': autoNextProduct,
    }));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ব্যাকআপ ও রিস্টোর (JSON)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('আপনার আগের ওয়েব অ্যাপের ব্যাকআপ JSON কোড এখানে পেস্ট করে Restore চাপলেই সব হিসাব চলে আসবে:'),
            const SizedBox(height: 8),
            TextField(controller: textCtrl, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textCtrl.text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ব্যাকআপ কপি হয়েছে ✓')));
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              try {
                final Map<String, dynamic> data = jsonDecode(textCtrl.text);
                setState(() {
                  customProducts = List<List<dynamic>>.from(data['custom'] ?? []);
                  deletedProducts = Map<String, dynamic>.from(data['del'] ?? {});
                  perCarton = Map<String, dynamic>.from(data['per'] ?? {});
                  sellPrices = Map<String, dynamic>.from(data['pr'] ?? {});
                  dealerPrices = Map<String, dynamic>.from(data['cp'] ?? {});
                  profitMargin = Map<String, dynamic>.from(data['lv'] ?? {});
                  logs = List<dynamic>.from(data['log'] ?? []);
                  marketEntries = List<dynamic>.from(data['mk'] ?? []);
                  hisabPersons = List<dynamic>.from(data['hp'] ?? []);
                  autoNextProduct = data['nx'] ?? true;
                });
                _saveData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রিস্টোর সফল হয়েছে ✓')));
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সঠিক JSON দিন!')));
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Stock Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(text: 'Entry'),
            Tab(text: 'Stock'),
            Tab(text: 'Market'),
            Tab(text: 'Calc'),
            Tab(text: 'Khata'),
            Tab(text: 'Product'),
            Tab(text: 'Hisab'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntryTab(),
          _buildStockTab(),
          _buildMarketTab(),
          _buildCalcTab(),
          _buildKhataTab(),
          _buildProductTab(),
          _buildHisabTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  // 1. Entry Tab
  Widget _buildEntryTab() {
    int k = getPcsPerCtn(selectedProductIdx);
    int currentPcs = getStock(selectedProductIdx);
    double cInput = double.tryParse(ctnController.text) ?? 0;
    double pInput = double.tryParse(pcsController.text) ?? 0;
    int addPcs = (cInput * k + pInput).toInt();
    int afterPcs = currentPcs + addPcs;
    String name = allProducts[selectedProductIdx][0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('তারিখ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextFormField(
                    readOnly: true,
                    initialValue: entryDate,
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('পণ্য নির্বাচন', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton.filledTonal(onPressed: () => _stepProduct(-1), icon: const Icon(Icons.arrow_back_ios_new, size: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openProductPicker(onSelect: (i) {
                            setState(() {
                              selectedProductIdx = i;
                              _updateDealerRateField();
                            });
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.teal), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("${selectedProductIdx + 1}. $name", style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                const Icon(Icons.arrow_drop_down, color: Colors.teal),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(onPressed: () => _stepProduct(1), icon: const Icon(Icons.arrow_forward_ios, size: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _openDetailsModal(selectedProductIdx), child: const Text('Details'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton(onPressed: () => _openPcsCtnModal(selectedProductIdx), child: const Text('Pcs/Ctn'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: ctnController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'CTN', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: pcsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'PCS', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: dealerRateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'ক্রয় দর / ডিলার রেট (১ ctn = ___ tk)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "এখন স্টক: ${formatQty(currentPcs, k)}${addPcs > 0 ? ' → পরে: ${formatQty(afterPcs, k)}' : ''} (১ ctn = $k pcs)",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save করলে পরের পণ্যতে যাবে', style: TextStyle(fontSize: 14)),
                    value: autoNextProduct,
                    onChanged: (v) {
                      setState(() => autoNextProduct = v ?? true);
                      _saveData();
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _saveEntry,
                      child: const Text('Save koro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Stock Tab
  Widget _buildStockTab() {
    final active = activeProductIndices.where((i) {
      final nm = allProducts[i][0].toString().toLowerCase();
      return stockQuery.isEmpty || nm.contains(stockQuery.toLowerCase());
    }).toList();

    double totalVal = 0;
    for (var i in active) {
      int totPcs = getStock(i);
      int k = getPcsPerCtn(i);
      double ac = getAvgCost(i, stockMode == 1 ? stockD2 : null);
      if (totPcs > 0) totalVal += (totPcs / k) * ac;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: ChoiceChip(label: const Text('এখন'), selected: stockMode == 0, onSelected: (_) => setState(() => stockMode = 0))),
                  const SizedBox(width: 6),
                  Expanded(child: ChoiceChip(label: const Text('তারিখ অব্দি'), selected: stockMode == 1, onSelected: (_) => setState(() => stockMode = 1))),
                  const SizedBox(width: 6),
                  Expanded(child: ChoiceChip(label: const Text('লেনদেন'), selected: stockMode == 2, onSelected: (_) => setState(() => stockMode = 2))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(hintText: '🔍 Product খুঁজুন...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                onChanged: (v) => setState(() => stockQuery = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final i = active[idx];
              final name = allProducts[i][0];
              final k = getPcsPerCtn(i);
              final totalPcs = getStock(i);
              final ac = getAvgCost(i);
              final pr = getSellPrice(i);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text("১ ctn = $k pcs | ক্রয়দর: ${ac > 0 ? '${moneyDecimal(ac)} tk' : 'নাই'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text("বিক্রি দর: ${pr > 0 ? '${moneyDecimal(pr)} tk' : 'নাই'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton(onPressed: () => _openDetailsModal(i), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)), child: const Text('Details', style: TextStyle(fontSize: 12))),
                                const SizedBox(width: 8),
                                OutlinedButton(onPressed: () => _openPcsCtnModal(i), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)), child: const Text('Pcs/Ctn set', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(totalPcs <= 0 ? "Stock nai" : formatQty(totalPcs, k), style: TextStyle(fontWeight: FontWeight.bold, color: totalPcs <= 0 ? Colors.red : Colors.teal)),
                          Text("$totalPcs pcs", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (ac > 0 && totalPcs > 0) Text("${money((totalPcs / k) * ac)} tk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.teal.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("মোট স্টক দাম (ক্রয়দর):", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${money(totalVal)} tk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.teal)),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Market Tab
  Widget _buildMarketTab() {
    final todayMarket = marketEntries.where((r) => r['d'] == marketDate).toList();
    double totalMarketTk = 0;
    for (var r in todayMarket) {
      int i = r['i'];
      int k = getPcsPerCtn(i);
      int net = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt()) -
          (((r['fc'] ?? 0) as num).toInt() * k + ((r['fp'] ?? 0) as num).toInt());
      double rVal = (r['r'] as num?)?.toDouble() ?? 0.0;
      totalMarketTk += (net / k) * rVal;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                readOnly: true,
                initialValue: marketDate,
                decoration: const InputDecoration(labelText: 'মার্কেট তারিখ', suffixIcon: Icon(Icons.calendar_today, size: 18), border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 1. Bahir Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('১. বাহির (মাল গেল)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _openProductPicker(onSelect: (i) {
                      setState(() {
                        marketOutIdx = i;
                        _updateMarketRateField();
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("${marketOutIdx + 1}. ${allProducts[marketOutIdx][0]}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: mb1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CTN', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: mb2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PCS', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: mbr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'দর/ctn', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        double c = double.tryParse(mb1.text) ?? 0;
                        double p = double.tryParse(mb2.text) ?? 0;
                        if (c == 0 && p == 0) return;
                        double rate = double.tryParse(mbr.text) ?? getSellPrice(marketOutIdx);

                        var r = marketEntries.firstWhere((x) => x['d'] == marketDate && x['i'] == marketOutIdx, orElse: () => null);
                        if (r == null) {
                          r = {
                            'id': DateTime.now().microsecondsSinceEpoch,
                            'd': marketDate,
                            'i': marketOutIdx,
                            'gc': c,
                            'gp': p,
                            'fc': 0.0,
                            'fp': 0.0,
                            'r': rate,
                          };
                          marketEntries.add(r);
                        } else {
                          r['gc'] = (r['gc'] as num).toDouble() + c;
                          r['gp'] = (r['gp'] as num).toDouble() + p;
                          r['r'] = rate;
                        }
                        _saveData();
                        setState(() {
                          mb1.clear();
                          mb2.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বাহিরে যোগ হয়েছে ✓')));
                      },
                      child: const Text('+ বাহির এ যোগ করো'),
                    ),
                  ),
                  if (todayMarket.isNotEmpty) ...[
                    const Divider(height: 20),
                    const Text('আজকের বাহির তালিকা:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...todayMarket.map((r) {
                      int i = r['i'];
                      int k = getPcsPerCtn(i);
                      int g = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt());
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(allProducts[i][0]),
                        subtitle: Text("গেল: ${formatQty(g, k)}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() => marketEntries.remove(r));
                            _saveData();
                          },
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Ferot Section
          if (todayMarket.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('২. ফেরত', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: marketFerotIdx ?? todayMarket.first['i'],
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                      items: todayMarket.map<DropdownMenuItem<int>>((r) {
                        return DropdownMenuItem<int>(value: r['i'], child: Text(allProducts[r['i']][0]));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          marketFerotIdx = v;
                          var r = todayMarket.firstWhere((x) => x['i'] == v);
                          mf1.text = r['fc'] > 0 ? r['fc'].toString() : "";
                          mf2.text = r['fp'] > 0 ? r['fp'].toString() : "";
                          mfr.text = r['r'] > 0 ? r['r'].toString() : "";
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: mf1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ফেরত CTN', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: mf2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ফেরত PCS', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: mfr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'দর/ctn', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        int currentI = marketFerotIdx ?? todayMarket.first['i'];
                        var r = todayMarket.firstWhere((x) => x['i'] == currentI);
                        r['fc'] = double.tryParse(mf1.text) ?? 0.0;
                        r['fp'] = double.tryParse(mf2.text) ?? 0.0;
                        r['r'] = double.tryParse(mfr.text) ?? (r['r'] ?? 0.0);
                        _saveData();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ফেরত সেভ হয়েছে ✓')));
                      },
                      child: const Text('ফেরত আপডেট করো'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Total Sheet Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
              onPressed: () => setState(() => showMarketSheet = !showMarketSheet),
              child: Text(showMarketSheet ? 'মার্কেট শিট লুকান' : 'Finish: পুরা Market Sheet দেখুন'),
            ),
          ),
          if (showMarketSheet) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...todayMarket.map((r) {
                      int i = r['i'];
                      int k = getPcsPerCtn(i);
                      int g = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt());
                      int f = (((r['fc'] ?? 0) as num).toInt() * k + ((r['fp'] ?? 0) as num).toInt());
                      int net = g - f;
                      double val = (net / k) * ((r['r'] as num?)?.toDouble() ?? 0.0);
                      return ListTile(
                        dense: true,
                        title: Text(allProducts[i][0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("গেল: ${formatQty(g, k)} | ফেরত: ${formatQty(f, k)} | বিক্রি: ${formatQty(net, k)}"),
                        trailing: Text("${moneyDecimal(val)} tk", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("মোট বিক্রি:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("${money(totalMarketTk)} tk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.teal)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // 4. Calc Tab
  Widget _buildCalcTab() {
    int k = getPcsPerCtn(calcProductIdx);
    double pr = getSellPrice(calcProductIdx);
    int a1 = int.tryParse(ca1.text) ?? 0;
    int a2 = int.tryParse(ca2.text) ?? 0;
    int b1 = int.tryParse(cb1.text) ?? 0;
    int b2 = int.tryParse(cb2.text) ?? 0;
    int totalA = a1 * k + a2;
    int totalB = b1 * k + b2;
    int res = totalA + (calcMode * totalB);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('পণ্য নির্বাচন', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openProductPicker(onSelect: (i) => setState(() => calcProductIdx = i)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.teal), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${calcProductIdx + 1}. ${allProducts[calcProductIdx][0]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("১ ctn = $k pcs | দাম: ${moneyDecimal(pr)} tk", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 14),
              const Text('প্রথম সংখ্যা:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextField(controller: ca1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CTN', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: ca2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PCS', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ChoiceChip(label: const Text('− বিয়োগ'), selected: calcMode == -1, onSelected: (_) => setState(() => calcMode = -1))),
                  const SizedBox(width: 10),
                  Expanded(child: ChoiceChip(label: const Text('+ যোগ'), selected: calcMode == 1, onSelected: (_) => setState(() => calcMode = 1))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: cb1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CTN', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: cb2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PCS', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(formatQty(res, k), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: res < 0 ? Colors.red : Colors.teal)),
                    Text("মোট $res পিস", style: const TextStyle(color: Colors.grey)),
                    if (pr > 0) Text("দাম: ${moneyDecimal((res / k) * pr)} tk", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Khata Tab
  Widget _buildKhataTab() {
    final allEntries = [
      ...logs.map((e) => {'k': 'l', 'e': e}),
      ...marketEntries.map((r) => {'k': 'm', 'e': r})
    ];
    allEntries.sort((a, b) => (b['e']['d'].toString()).compareTo(a['e']['d'].toString()));
    final display = allEntries.take(150).toList();

    return display.isEmpty
        ? const Center(child: Text("কোনো এন্ট্রি নেই"))
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, idx) {
              final item = display[idx];
              final isLog = item['k'] == 'l';
              final e = item['e'];
              final pName = allProducts[e['i']][0];

              return Card(
                child: ListTile(
                  title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: isLog
                      ? Text("${e['d']} · প্রথম স্টক\n${e['c']} ctn ${e['p']} pcs")
                      : Text("${e['d']} · মার্কেট\nগেল: ${e['gc']}c ${e['gp']}p | ফেরত: ${e['fc']}c ${e['fp']}p"),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (isLog) logs.remove(e);
                        else marketEntries.remove(e);
                      });
                      _saveData();
                    },
                  ),
                ),
              );
            },
          );
  }

  // 6. Product Tab
  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('পণ্য দর ও লাভ সেটআপ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openProductPicker(onSelect: (i) => _openPcsCtnModal(i)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.teal), borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("যেকোনো পণ্যে ট্যাপ করে দর ঠিক করুন"),
                          Icon(Icons.edit, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ব্যাকআপ ও রিস্টোর', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.backup),
                      label: const Text('ব্যাকআপ কপি ও রিস্টোর পেস্ট'),
                      onPressed: _showBackupDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Hisab Tab
  Widget _buildHisabTab() {
    double totalJ = 0, totalK = 0;
    for (var p in hisabPersons) {
      for (var t in p['t'] ?? []) {
        if (t['ty'] == 'j') totalJ += (t['a'] as num).toDouble();
        if (t['ty'] == 'k') totalK += (t['a'] as num).toDouble();
      }
    }
    double netBaki = totalJ - totalK;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('+ Add'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  final nameCtrl = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('নতুন ব্যক্তি যোগ করুন'),
                      content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ব্যক্তির নাম')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ')),
                        ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setState(() {
                              hisabPersons.add({
                                'id': DateTime.now().microsecondsSinceEpoch,
                                'n': nameCtrl.text.trim(),
                                't': [],
                              });
                            });
                            _saveData();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Text("মোট বাকি: ${money(netBaki)} tk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: netBaki >= 0 ? Colors.teal : Colors.red)),
            ],
          ),
        ),
        Expanded(
          child: hisabPersons.isEmpty
              ? const Center(child: Text("কোনো ব্যক্তি নেই"))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: hisabPersons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, idx) {
                    final p = hisabPersons[idx];
                    double j = 0, k = 0;
                    for (var t in p['t'] ?? []) {
                      if (t['ty'] == 'j') j += (t['a'] as num).toDouble();
                      if (t['ty'] == 'k') k += (t['a'] as num).toDouble();
                    }
                    double b = j - k;

                    return Card(
                      child: ListTile(
                        title: Text(p['n'] ?? "(নাম নাই)", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("জমা: ${money(j)} | খরচ: ${money(k)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${money(b)} tk", style: TextStyle(fontWeight: FontWeight.bold, color: b >= 0 ? Colors.teal : Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() => hisabPersons.remove(p));
                                _saveData();
                              },
                            ),
                          ],
                        ),
                        onTap: () => _openPersonLedger(p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPersonLedger(Map<String, dynamic> p) {
    String pType = 'j';
    final aCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLedgerState) {
          final txs = List<Map<String, dynamic>>.from(p['t'] ?? []);
          double j = 0, k = 0;
          for (var t in txs) {
            if (t['ty'] == 'j') j += (t['a'] as num).toDouble();
            if (t['ty'] == 'k') k += (t['a'] as num).toDouble();
          }
          double b = j - k;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['n'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Text("জমা: ${money(j)} · খরচ: ${money(k)} | বাকি: ${money(b)} tk", style: TextStyle(fontWeight: FontWeight.bold, color: b >= 0 ? Colors.teal : Colors.red)),
                const Divider(),
                Row(
                  children: [
                    ChoiceChip(label: const Text('+ জমা'), selected: pType == 'j', onSelected: (_) => setLedgerState(() => pType = 'j')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('− খরচ'), selected: pType == 'k', onSelected: (_) => setLedgerState(() => pType = 'k')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: aCtrl, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: 'টাকা (200+300 লিখতে পারেন)', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        // Expression evaluator for "200+300"
                        double sum = 0;
                        for (var part in aCtrl.text.split('+')) {
                          sum += double.tryParse(part.trim()) ?? 0;
                        }
                        if (sum <= 0) return;

                        setLedgerState(() {
                          p['t'].add({
                            'id': DateTime.now().microsecondsSinceEpoch,
                            'ty': pType,
                            'a': sum,
                            'd': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            'nt': noteCtrl.text.trim(),
                          });
                        });
                        _saveData();
                        setState(() {});
                        aCtrl.clear();
                        noteCtrl.clear();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (c, idx) {
                      final t = txs[txs.length - 1 - idx];
                      bool isJ = t['ty'] == 'j';
                      return ListTile(
                        dense: true,
                        title: Text("${t['d']} · ${t['nt'] ?? ''}"),
                        leading: Text(isJ ? "+ জমা" : "− খরচ", style: TextStyle(fontWeight: FontWeight.bold, color: isJ ? Colors.teal : Colors.red)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${money((t['a'] as num).toDouble())} tk", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 16),
                              onPressed: () {
                                setLedgerState(() => p['t'].remove(t));
                                _saveData();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 8. Summary Tab
  Widget _buildSummaryTab() {
    double totalSell = 0;
    for (var r in marketEntries) {
      int i = r['i'];
      int k = getPcsPerCtn(i);
      int net = (((r['gc'] ?? 0) as num).toInt() * k + ((r['gp'] ?? 0) as num).toInt()) -
          (((r['fc'] ?? 0) as num).toInt() * k + ((r['fp'] ?? 0) as num).toInt());
      double rVal = (r['r'] as num?)?.toDouble() ?? 0.0;
      totalSell += (net / k) * rVal;
    }

    double totalJ = 0, totalK = 0;
    for (var p in hisabPersons) {
      for (var t in p['t'] ?? []) {
        if (t['ty'] == 'j') totalJ += (t['a'] as num).toDouble();
        if (t['ty'] == 'k') totalK += (t['a'] as num).toDouble();
      }
    }
    double baki = totalJ - totalK;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildCircleCard("Total Sell", totalSell, Colors.teal),
              _buildCircleCard("Total Joma", totalJ, Colors.blue),
              _buildCircleCard("Total Khoroch", totalK, Colors.red),
              _buildCircleCard("Baki", baki, baki >= 0 ? Colors.teal : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(String title, num val, Color col) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: col, width: 3), color: col.withOpacity(0.08)),
              alignment: Alignment.center,
              child: Text(
                money(val),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
