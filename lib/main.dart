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
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
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
  List<dynamic> logs = [];
  List<dynamic> marketEntries = [];
  List<dynamic> hisabPersons = [];

  int selectedProductIdx = 0;
  final TextEditingController ctnController = TextEditingController();
  final TextEditingController pcsController = TextEditingController();
  final TextEditingController dealerRateController = TextEditingController();
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
          logs = List<dynamic>.from(data['log'] ?? []);
          marketEntries = List<dynamic>.from(data['mk'] ?? []);
          hisabPersons = List<dynamic>.from(data['hp'] ?? []);
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
      'log': logs,
      'mk': marketEntries,
      'hp': hisabPersons,
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
    if (active.isNotEmpty && !active.contains(selectedProductIdx)) {
      setState(() {
        selectedProductIdx = active.first;
      });
    }
  }

  int getPcsPerCtn(int i) {
    if (perCarton.containsKey(i.toString())) {
      return perCarton[i.toString()] as int;
    }
    if (i < allProducts.length) {
      return allProducts[i][1] as int;
    }
    return 1;
  }

  int getStock(int i) {
    int k = getPcsPerCtn(i);
    int totalIn = 0;
    for (var e in logs) {
      if (e['i'] == i) {
        totalIn += ((e['c'] ?? 0) * k + (e['p'] ?? 0)) as int;
      }
    }
    int totalOut = 0;
    for (var r in marketEntries) {
      if (r['i'] == i) {
        int g = ((r['gc'] ?? 0) * k + (r['gp'] ?? 0)) as int;
        int f = ((r['fc'] ?? 0) * k + (r['fp'] ?? 0)) as int;
        totalOut += (g - f);
      }
    }
    return totalIn - totalOut;
  }

  void _saveEntry() {
    double c = double.tryParse(ctnController.text) ?? 0;
    double p = double.tryParse(pcsController.text) ?? 0;
    if (c == 0 && p == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কার্টুন অথবা পিস লিখুন!')),
      );
      return;
    }
    double? cp = double.tryParse(dealerRateController.text);
    if (cp != null && cp > 0) {
      dealerPrices[selectedProductIdx.toString()] = cp;
    }

    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'd': selectedDate,
      't': 'open',
      'i': selectedProductIdx,
      'c': c,
      'p': p,
      'cp': cp ?? 0,
    };

    setState(() {
      logs.add(entry);
      ctnController.clear();
      pcsController.clear();
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('স্টক সফলভাবে সেভ হয়েছে ✓'),
        backgroundColor: Color(0xFF0D9488),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final active = activeProductIndices.where((idx) {
              final name = allProducts[idx][0].toString().toLowerCase();
              return query.isEmpty || name.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'পণ্য নির্বাচন করুন',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Text(
                    '💡 ট্যাপ করলে সিলেক্ট হবে · চেপে ধরে রাখলে (Long Press) ডিলিট অপশন আসবে',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '🔍 পণ্য খুঁজুন...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        query = val;
                      });
                    },
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

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              selectedProductIdx = i;
                            });
                            Navigator.pop(context);
                          },
                          onLongPress: () {
                            HapticFeedback.vibrate();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('পণ্য ডিলিট করবেন?'),
                                content: Text("আপনি কি নিশ্চিত '$name' তালিকা থেকে ডিলিট করতে চান?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('না'),
                                  ),
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("$name ডিলিট হয়েছে ✓")),
                                      );
                                    },
                                    child: const Text('হ্যাঁ, ডিলিট', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
                                    Text(
                                      "${i + 1}. $name",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      "১ কার্টুন = $pcs পিস",
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
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

  @override
  Widget build(BuildContext context) {
    final active = activeProductIndices;
    final currentName = active.contains(selectedProductIdx)
        ? "${selectedProductIdx + 1}. ${allProducts[selectedProductIdx][0]}"
        : "পণ্য নির্বাচন করুন";

    int currentStockPcs = active.contains(selectedProductIdx) ? getStock(selectedProductIdx) : 0;
    int k = active.contains(selectedProductIdx) ? getPcsPerCtn(selectedProductIdx) : 1;
    int ctn = currentStockPcs ~/ k;
    int pcs = currentStockPcs % k;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📦 Stock Register (Flutter)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Entry Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
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
                      initialValue: selectedDate,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('পণ্য নির্বাচন (ট্যাপ করুন)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _openProductPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ctnController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'কার্টুন (CTN)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: pcsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'পিস (PCS)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dealerRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'ক্রয় দর / কার্টুন (tk)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "এখন স্টক আছে: $ctn ctn $pcs pcs (১ ctn = $k pcs)",
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveEntry,
                        child: const Text('Save koro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stock Tab
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: active.length,
            itemBuilder: (context, idx) {
              final i = active[idx];
              final name = allProducts[i][0];
              final kVal = getPcsPerCtn(i);
              final totalPcs = getStock(i);
              final c = totalPcs ~/ kVal;
              final p = totalPcs % kVal;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("১ কার্টুন = $kVal পিস | মোট: $totalPcs pcs"),
                  trailing: Text(
                    totalPcs <= 0 ? "স্টক নাই" : "$c ctn $p pcs",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: totalPcs <= 0 ? Colors.red : Colors.teal,
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Market Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 60, color: Colors.teal),
                const SizedBox(height: 10),
                Text(
                  "মার্কেট এন্ট্রি: ${marketEntries.length} টি রেকর্ড",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 4. Calc Tab
          const Center(child: Text("ক্যালকুলেটর ট্যাব")),

          // 5. Khata Tab
          logs.isEmpty
              ? const Center(child: Text("কোনো এন্ট্রি নেই"))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final e = logs[logs.length - 1 - index];
                    final pName = allProducts[e['i']][0];
                    return ListTile(
                      title: Text(pName),
                      subtitle: Text("${e['d']} | ${e['c']} ctn ${e['p']} pcs"),
                    );
                  },
                ),

          // 6. Summary Tab
          const Center(child: Text("ডেইলি সামারি ট্যাব")),
        ],
      ),
    );
  }
}
