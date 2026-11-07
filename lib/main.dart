import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────── Data ─────────────────────────
const BASE = <List<dynamic>>[
  ["মিল্ক কেক", 72], ["মাফিন কেক", 48], ["ডপস ১০", 24], ["লুপস ৫", 48], ["লেক্সাস ৫", 48],
  ["লেক্সাস ১০", 24], ["লেক্সাস ফ্যামিলি", 1], ["মেরি ফ্যামিলি", 12], ["মিল্ক ৫", 48], ["ঘি ৫", 48],
  ["ঘি ১০", 24], ["ঘি ফ্যামিলি", 8], ["চকোলেট ১০", 48], ["এনার্জি ৫", 48], ["এনার্জি ১০", 24],
  ["এনার্জি ফ্যামিলি", 8], ["৪ পিসের নুডলস", 1], ["৮ পিসের নুডলস", 1], ["পাতা নুডলস", 12],
  ["১৫ গ্রাম মরিচ গুড়া", 1], ["৫০ গ্রাম মরিচ গুড়া", 1], ["১৫ গ্রাম হলুদ গুড়া", 1], ["৫০ গ্রাম হলুদ গুড়া", 1],
  ["হলুদ গুড়া ৫ কেজি", 1], ["মরিচ গুড়া ৫ কেজি", 1], ["মাংসের মশলা", 1], ["মুরগির মশলা", 1],
  ["গরু মাংসের মশলা", 1], ["মাছের মশলা", 1], ["১৫ গ্রাম জিরার গুরা", 1], ["৫০ গ্রাম জিরার গুরা", 1],
  ["বিরিয়ানি মশলা ৪০ গ্রাম", 1], ["সরিষ তেল ৮০ গ্রাম", 1], ["সরিষ তেল ২০০ গ্রাম", 1], ["ঘি টোস্ট মিনি", 96],
  ["ড্রাই কেক মিনি", 48], ["কোকোনাট ২০ টাকা", 8], ["কোকোনাট ফ্যামিলি", 24], ["৫ টাকা চানাচুর", 1],
  ["৩০ টাকা চানাচুর", 1], ["৫০ টাকা চানাচুর", 1], ["লাচ্ছা সেমাই", 1], ["ভার্মিচিলি সেমাই", 1],
  ["বালিশ সেমাই", 1], ["এগ নুডলস্", 24], ["তেঁতুল চাটনী", 1], ["১৫ গ্রাম চা", 1], ["৫০০ গ্রাম চা", 1],
  ["রোস্টের মশলা", 1],
];
const LB = {'open': 'Prothom stock', 'in': 'Mal ashlo +', 'bahir': 'Market e gelo −', 'ferot': 'Ferot +', 'out': 'Bikri −'};

double nn(dynamic x) => x is num ? x.toDouble() : (double.tryParse('$x') ?? 0);
double rd(double x) => (x * 1000).round() / 1000;
String ns(double x) => x == x.truncateToDouble() ? x.toInt().toString() : x.toString();
String _grp(String d) {
  if (d.length <= 3) return d;
  final l = d.substring(d.length - 3);
  var r = d.substring(0, d.length - 3);
  final p = <String>[];
  while (r.length > 2) { p.insert(0, r.substring(r.length - 2)); r = r.substring(0, r.length - 2); }
  if (r.isNotEmpty) p.insert(0, r);
  return '${p.join(',')},$l';
}
String mm2(double v) {
  final r = (v * 100).round() / 100;
  var s = r.abs().toStringAsFixed(2);
  if (s.endsWith('.00')) { s = s.substring(0, s.length - 3); } else if (s.endsWith('0')) { s = s.substring(0, s.length - 1); }
  final pt = s.split('.');
  return (r < 0 ? '-' : '') + _grp(pt[0]) + (pt.length > 1 ? '.${pt[1]}' : '');
}
String m2(double v) => ns((v * 100).round() / 100);
String money(double v) => (v.round() < 0 ? '-' : '') + _grp(v.round().abs().toString());
String sg(double v) => (v > 0 ? '+' : v < 0 ? '−' : '') + mm2(v.abs());
String fmt(double q, int k) {
  q = rd(q);
  final u = q.abs(), c = (u / k + 1e-9).floor();
  return '${q < 0 ? '-' : ''}$c ctn ${ns(rd(u - c * k))} pcs';
}
String dq(double q, int k) {
  q = rd(q);
  if (k > 1 && q % k == 0) return '${ns(q / k)} ctn';
  final c = q / k;
  if (k > 1 && (c * 100 - (c * 100).round()).abs() < 1e-6) return '${ns((c * 100).round() / 100)} ctn';
  return fmt(q, k);
}
String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String today() => ymd(DateTime.now());
int newId() => DateTime.now().millisecondsSinceEpoch * 1000 + Random().nextInt(1000);
double am(String v) => v.split('+').fold(0.0, (s, x) => s + (double.tryParse(x.replaceAll(',', '').trim()) ?? 0));
double pf(String s) => max(0.0, double.tryParse(s.trim()) ?? 0);
String nz(dynamic v) => nn(v) == 0 ? '' : ns(nn(v));
String esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
TextEditingController TC([String t = '']) => TextEditingController(text: t);

class SD {
  final Map r; final int i, k; final double g, f, net, v;
  SD(this.r, this.i, this.k, this.g, this.f, this.net, this.v);
}

class Store extends ChangeNotifier {
  late SharedPreferences sp;
  Map S = {};
  Future<void> init() async { sp = await SharedPreferences.getInstance(); load(_dec(sp.getString('stk1'))); }
  Map _dec(String? s) { try { final x = jsonDecode(s ?? 'null'); if (x is Map) return x; } catch (_) {} return {}; }
  void load(Map x) {
    S = {'custom': [], 'per': {}, 'pr': {}, 'cp': {}, 'lv': {}, 'log': [], 'mk': [], 'del': {}, 'hp': []};
    x.forEach((k, v) { if (v != null) S[k] = v; });
    if (S['fx2'] == null) { for (final i in [19, 20, 21, 22, 25, 26, 27, 28, 29, 30, 31, 48]) { per.remove('$i'); } S['fx2'] = 1; }
  }
  void save() { try { sp.setString('stk1', jsonEncode(S)); } catch (_) {} notifyListeners(); }
  void keep() { try { sp.setString('stk1_prev', jsonEncode(S)); } catch (_) {} }
  Map get per => S['per']; Map get pr => S['pr']; Map get cp => S['cp']; Map get lv => S['lv']; Map get del => S['del'];
  List get log => S['log']; List get mk => S['mk']; List get hp => S['hp']; List get custom => S['custom'];
  int get n => BASE.length + custom.length;
  String name(int i) => i >= n ? '?' : '${i < BASE.length ? BASE[i][0] : custom[i - BASE.length][0]}';
  int K(int i) {
    final v = nn(per['$i']);
    if (v > 0) return v.round();
    if (i >= n) return 1;
    final b = nn(i < BASE.length ? BASE[i][1] : custom[i - BASE.length][1]);
    return b > 0 ? b.round() : 1;
  }
  double PR(int i) => nn(pr['$i']);
  double CP(int i) => nn(cp['$i']);
  bool isDel(int i) => del['$i'] == true;
  List<int> get valid => [for (var i = 0; i < n; i++) if (!isDel(i)) i];
  double qty(Map e) => rd(nn(e['c']) * K(e['i']) + nn(e['p']));
  double gq(Map r) => rd(nn(r['gc']) * K(r['i']) + nn(r['gp']));
  double fq(Map r) => rd(nn(r['fc']) * K(r['i']) + nn(r['fp']));
  double nq(Map r) => rd(gq(r) - fq(r));
  double stock(int i) =>
      rd(log.fold(0.0, (s, e) => e['i'] == i ? s + qty(e) : s) - mk.fold(0.0, (s, r) => r['i'] == i ? s + nq(r) : s));
  double acost(int i, String d2) {
    double q = 0, v = 0;
    for (final e in log) {
      if (e['i'] != i || e['t'] == 'out' || (d2.isNotEmpty && (e['d'] as String).compareTo(d2) > 0)) continue;
      final c = nn(e['cp']) > 0 ? nn(e['cp']) : CP(i), qq = qty(e);
      q += qq; v += qq * c;
    }
    return q != 0 ? v / q : CP(i);
  }
  SD sd(Map r) { final i = r['i'] as int, k = K(i), g = gq(r), f = fq(r), net = rd(g - f); return SD(r, i, k, g, f, net, net / k * nn(r['r'])); }
  List<SD> sellData(String d) {
    final R = [for (final r in mk) if (r['d'] == d && !isDel(r['i'])) sd(r)];
    R.sort((a, b) => a.i - b.i);
    return R;
  }
  (double, double, int) labOf(List<SD> R, String d) {
    final lc = R.where((x) => acost(x.i, d) > 0).toList();
    return (lc.fold(0.0, (s, x) => s + x.net / x.k * acost(x.i, d)), lc.fold(0.0, (s, x) => s + x.v - x.net / x.k * acost(x.i, d)), lc.length);
  }
  double pj(Map p) => (p['t'] as List).where((e) => e['ty'] == 'j').fold(0.0, (s, e) => s + nn(e['a']));
  double pk(Map p) => (p['t'] as List).where((e) => e['ty'] == 'k').fold(0.0, (s, e) => s + nn(e['a']));
}

final st = Store();
final curTab = ValueNotifier<int>(0);

// ───────────────────────── Theme / UI helpers ─────────────────────────
bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color ac(BuildContext c) => isDark(c) ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
Color bad(BuildContext c) => isDark(c) ? const Color(0xFFF87171) : const Color(0xFFEF4444);
Color jm(BuildContext c) => isDark(c) ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
Color mut(BuildContext c) => isDark(c) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color scol(BuildContext c, double v) => v > 0 ? ac(c) : v < 0 ? bad(c) : Theme.of(c).colorScheme.onSurface;
TextStyle sub(BuildContext c) => TextStyle(color: mut(c), fontSize: 13.5, height: 1.5);
const pad = EdgeInsets.fromLTRB(12, 0, 12, 28);
const gap = SizedBox(width: 10);

ThemeData _theme(Brightness b) {
  final d = b == Brightness.dark;
  final bd = d ? const Color(0xFF222F3E) : const Color(0xFFE2E8F0);
  final bg = d ? const Color(0xFF0B0F17) : const Color(0xFFF4F6FA);
  final card = d ? const Color(0xFF141B26) : Colors.white;
  final a = d ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
  OutlineInputBorder ob(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: 1.5));
  return ThemeData(
    useMaterial3: true, brightness: b, scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488), brightness: b, primary: a, surface: card),
    cardTheme: CardThemeData(color: card, elevation: 0, margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: bd))),
    inputDecorationTheme: InputDecorationTheme(isDense: true, filled: true, fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12), border: ob(bd), enabledBorder: ob(bd), focusedBorder: ob(a)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        side: BorderSide(color: bd), minimumSize: const Size(0, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: a, foregroundColor: d ? Colors.black : Colors.white, minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  );
}

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

Future<bool> confirm(BuildContext c, String msg) async =>
    await showDialog<bool>(
      context: c,
      builder: (x) => AlertDialog(
        title: Text('Delete korben?', style: TextStyle(color: bad(c))),
        content: Text('$msg\n\nVul hole pore "Reset undo" diye ferot ante parben.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('Na, bondho')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: bad(c)), onPressed: () => Navigator.pop(x, true), child: const Text('Haa, delete koro')),
        ],
      ),
    ) ?? false;

Widget lb(BuildContext c, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 10, 0, 5), child: Text(t, style: sub(c).copyWith(fontWeight: FontWeight.w600, fontSize: 13)));
Widget tf(TextEditingController c, {String? hint, bool num = true, ValueChanged<String>? on}) => TextField(
    controller: c, onChanged: on, keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    decoration: InputDecoration(hintText: hint));
Widget fld(BuildContext c, String label, TextEditingController t, {ValueChanged<String>? on, String? hint, bool num = true}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(c, label), tf(t, hint: hint, on: on, num: num)]);
Widget big(String t, VoidCallback f) => Padding(
    padding: const EdgeInsets.only(top: 12), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: f, child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))));
Widget h2(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)));
Widget cardW(List<Widget> ch) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ch)));
Widget xBtn(VoidCallback f) => SizedBox(width: 38, height: 32, child: TextButton(style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: const Color(0xFFEF4444)), onPressed: f, child: const Text('✕', style: TextStyle(fontWeight: FontWeight.w700))));

Widget labW(BuildContext c, List<SD> R, String d) {
  final o = st.labOf(R, d);
  if (o.$3 == 0) return Text('Kroy dor deya nai, lab dekhano jachche na', style: sub(c));
  return Text.rich(TextSpan(style: sub(c), children: [
    TextSpan(text: 'Kroy dam: ${mm2(o.$1)} tk · '),
    TextSpan(text: 'Lab: ${sg(o.$2)} tk', style: TextStyle(fontWeight: FontWeight.bold, color: scol(c, o.$2))),
    if (o.$3 < R.length) const TextSpan(text: ' (kichu product e kroy dor nai)'),
  ]));
}

class Tog extends StatelessWidget {
  final List<String> l; final int v; final ValueChanged<int> on;
  const Tog(this.l, this.v, this.on, {super.key});
  @override
  Widget build(BuildContext c) => Row(children: [
        for (var i = 0; i < l.length; i++)
          Expanded(child: Padding(padding: EdgeInsets.only(right: i < l.length - 1 ? 8 : 0),
              child: v == i ? FilledButton(onPressed: () => on(i), child: Text(l[i])) : OutlinedButton(onPressed: () => on(i), child: Text(l[i])))),
      ]);
}

class DateF extends StatelessWidget {
  final TextEditingController c; final VoidCallback? on; final bool clear;
  const DateF(this.c, {this.on, this.clear = false, super.key});
  @override
  Widget build(BuildContext ctx) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: c,
        builder: (_, v, __) => TextField(
          controller: c, readOnly: true,
          decoration: InputDecoration(
              suffixIcon: clear && c.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { c.clear(); on?.call(); })
                  : const Icon(Icons.calendar_today, size: 18)),
          onTap: () async {
            final r = await showDatePicker(context: ctx, initialDate: DateTime.tryParse(c.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (r != null) { c.text = ymd(r); on?.call(); }
          },
        ),
      );
}

class Keep extends StatefulWidget {
  final Widget child;
  const Keep(this.child, {super.key});
  @override
  State<Keep> createState() => _KeepS();
}
class _KeepS extends State<Keep> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext c) { super.build(c); return widget.child; }
}

// Product selector: ◀ [picker] ▶
class ProdSel extends StatelessWidget {
  final List<int> items; final int? value; final ValueChanged<int> onChanged; final bool del;
  const ProdSel({super.key, required this.items, required this.value, required this.onChanged, this.del = false});
  @override
  Widget build(BuildContext c) {
    final idx = value == null ? -1 : items.indexOf(value!);
    void step(int d) { if (items.isEmpty) return; onChanged(items[(max(0, idx) + d).clamp(0, items.length - 1)]); }
    return Row(children: [
      SizedBox(width: 44, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: EdgeInsets.zero), onPressed: () => step(-1), child: const Text('◀'))),
      const SizedBox(width: 6),
      Expanded(child: OutlinedButton(
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: Theme.of(c).scaffoldBackgroundColor, foregroundColor: Theme.of(c).colorScheme.onSurface),
        onPressed: () async {
          final r = await showModalBottomSheet<int>(context: c, isScrollControlled: true, builder: (_) => _Picker(items, del));
          if (r != null) onChanged(r);
        },
        child: Row(children: [
          Expanded(child: Text(value == null ? 'Product baachun' : '${value! + 1}. ${st.name(value!)}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('▼', style: TextStyle(fontSize: 12, color: mut(c))),
        ]),
      )),
      const SizedBox(width: 6),
      SizedBox(width: 44, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: EdgeInsets.zero), onPressed: () => step(1), child: const Text('▶'))),
    ]);
  }
}
class _Picker extends StatefulWidget {
  final List<int> items; final bool del;
  const _Picker(this.items, this.del);
  @override
  State<_Picker> createState() => _PickerS();
}
class _PickerS extends State<_Picker> {
  final q = TC();
  @override
  Widget build(BuildContext c) {
    final f = q.text.trim().toLowerCase();
    final L = widget.items.where((i) => !st.isDel(i) && (f.isEmpty || st.name(i).toLowerCase().contains(f))).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: SizedBox(height: MediaQuery.of(c).size.height * 0.8, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [const Expanded(child: Text('Product List', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bondho'))]),
        if (widget.del) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('💡 Tap korle select · Chepe dhore rakhle Delete option ashbe', style: sub(c).copyWith(fontSize: 12.5))),
        TextField(controller: q, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: '🔍 Product khujo...')),
        const SizedBox(height: 10),
        Expanded(child: L.isEmpty
            ? Center(child: Text('Kono product pawa jayni', style: sub(c)))
            : ListView.separated(itemCount: L.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, x) {
                final i = L[x];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(c, i),
                  onLongPress: !widget.del ? null : () async {
                    HapticFeedback.mediumImpact();
                    if (await confirm(c, "Apni ki '${st.name(i)}' product-ti list theke DELETE korte chan?")) {
                      st.del['$i'] = true; st.save(); setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: mut(c).withValues(alpha: 0.3), width: 1.5), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${i + 1}. ${st.name(i)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('1 ctn = ${st.K(i)} pcs${st.PR(i) > 0 ? ' · ${mm2(st.PR(i))} tk' : ''}', style: sub(c).copyWith(fontSize: 12)),
                      ])),
                      Text('Select ➜', style: TextStyle(color: ac(c), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              })),
      ]))),
    );
  }
}

// ───────────────────────── PDF (HTML → PDF; Bangla shaping works) ─────────────────────────
class HR { final List<String> c; final String cls; HR(this.c, [this.cls = '']); }
String pdfHtml(String title, String sub, List<String> head, List<HR> rows, {Set<int> right = const {}, String foot = '', String top = ''}) {
  final b = StringBuffer('<html><head><meta charset="utf-8"><style>'
      'body{font-family:sans-serif;font-size:11px}h1{font-size:22px;margin:0}.s{color:#444;margin:4px 0 10px}table{width:100%;border-collapse:collapse}'
      'th{background:#e5e7eb;text-align:left;padding:5px}td{padding:4px 5px;border-bottom:1px solid #d1d5db}.r{text-align:right}'
      'tr.red td{background:#fee2e2;color:#b91c1c}tr.hd td{background:#dbeafe;font-weight:bold}tr.pp td{background:#eef2ff;font-weight:bold}tr.det td{color:#374151}'
      '.f{margin-top:12px;font-size:14px;font-weight:bold;border-top:2px solid #000;padding-top:6px;line-height:1.7}</style></head><body>');
  b.write('<h1>${esc(title)}</h1><div class="s">${esc(sub)}${top.isEmpty ? '' : ' &nbsp; <b style="color:#b91c1c">${esc(top)}</b>'}</div><table><tr>');
  for (var i = 0; i < head.length; i++) { b.write('<th${right.contains(i) ? ' class="r"' : ''}>${esc(head[i])}</th>'); }
  b.write('</tr>');
  for (final r in rows) {
    b.write('<tr class="${r.cls}">');
    for (var i = 0; i < r.c.length; i++) { b.write('<td${right.contains(i) ? ' class="r"' : ''}>${r.c[i]}</td>'); }
    b.write('</tr>');
  }
  b.write('</table><div class="f">$foot</div></body></html>');
  return b.toString();
}
Future<void> exportPdf(BuildContext c, String file, String html) async {
  try {
    final bytes = await Printing.convertHtml(format: PdfPageFormat.a4, html: html);
    await Printing.sharePdf(bytes: bytes, filename: file);
  } catch (e) {
    if (c.mounted) toast(c, 'PDF save hoyni, abar chesta koro');
  }
}

// ───────────────────────── App shell ─────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await st.init();
  runApp(MaterialApp(title: 'Stock Register', debugShowCheckedModeBanner: false, themeMode: ThemeMode.system,
      theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark), home: const Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeS();
}
class _HomeS extends State<Home> {
  final pc = PageController();
  static const names = ['Entry', 'Stock', 'Market', 'Calc', 'Khata', 'Product', 'Hisab', 'Summary'];
  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 4), child: Align(alignment: Alignment.centerLeft,
              child: Text('📦 Stock Register', style: TextStyle(fontWeight: FontWeight.w700, color: ac(c))))),
          SizedBox(height: 50, child: ValueListenableBuilder<int>(valueListenable: curTab, builder: (_, cur, __) => ListView.separated(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), itemCount: names.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ChoiceChip(
                    label: Text(names[i], style: TextStyle(fontWeight: FontWeight.w600, color: cur == i ? Colors.white : mut(c))),
                    selected: cur == i, showCheckmark: false, selectedColor: const Color(0xFF0D9488), shape: const StadiumBorder(),
                    onSelected: (_) => pc.animateToPage(i, duration: const Duration(milliseconds: 220), curve: Curves.easeOut))))),
          Expanded(child: PageView(controller: pc, onPageChanged: (i) { FocusScope.of(c).unfocus(); curTab.value = i; }, children: const [
            Keep(EntryTab()), Keep(StockTab()), Keep(MktTab()), Keep(CalcTab()), Keep(KhataTab()), Keep(ProdTab()), Keep(HisabTab()), Keep(SumTab()),
          ])),
        ])))),
      );
}

// ───────────────────────── Dialogs: Details & Pcs/Ctn set ─────────────────────────
void showDet(BuildContext c, int i) => showDialog(context: c, builder: (_) => DetDlg(i));
void showSet(BuildContext c, int i) => showDialog(context: c, builder: (_) => SetDlg(i));

class DetDlg extends StatelessWidget {
  final int i;
  const DetDlg(this.i, {super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: st, builder: (_, __) {
        final k = st.K(i);
        final L = st.log.where((e) => e['i'] == i).toList(), M = st.mk.where((r) => r['i'] == i).toList();
        final o = L.fold(0.0, (s, e) => s + st.qty(e));
        final g = M.fold(0.0, (s, r) => s + st.gq(r)), f = M.fold(0.0, (s, r) => s + st.fq(r));
        final sv = M.fold(0.0, (s, r) => s + st.nq(r) / k * nn(r['r']));
        final A = <(String, num, Widget)>[
          for (final e in L) (e['d'] as String, nn(e['id']), ListTile(dense: true, title: Text('${e['d']}\n${LB[e['t']] ?? ''}', style: const TextStyle(fontSize: 13)),
              subtitle: Text('${ns(nn(e['c']))} ctn ${ns(nn(e['p']))} pcs · ${ns(st.qty(e))} pcs'),
              trailing: xBtn(() async { if (await confirm(c, 'Ei entry delete korben?')) { st.log.removeWhere((x) => x['id'] == e['id']); st.save(); } }))),
          for (final r in M) (r['d'] as String, nn(r['id']), ListTile(dense: true, title: Text('${r['d']}\nMarket e gelo', style: const TextStyle(fontSize: 13)),
              subtitle: Text('Gelo ${dq(st.gq(r), k)} · Ferot ${dq(st.fq(r), k)}${nn(r['r']) > 0 ? ' · dor ${mm2(nn(r['r']))}' : ''}'),
              trailing: xBtn(() async { if (await confirm(c, 'Ei entry delete korben?')) { st.mk.removeWhere((x) => x['id'] == r['id']); st.save(); } }))),
        ]..sort((a, b) { final x = b.$1.compareTo(a.$1); return x != 0 ? x : b.$2.compareTo(a.$2); });
        return Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(st.name(i), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bondho'))]),
          Text('1 ctn = $k pcs${st.PR(i) > 0 ? '  |  1 ctn dam: ${mm2(st.PR(i))} tk  |  1 pcs dam: ${mm2(st.PR(i) / k)} tk' : ''}', style: sub(c)),
          const SizedBox(height: 10),
          Text('Stock jog (prothom): ${fmt(o, k)}\nMarket e gelo: ${dq(g, k)}\nFerot: ${dq(f, k)}\nSell (gelo − ferot): ${dq(g - f, k)}${sv != 0 ? ' = ${mm2(sv)} tk' : ''}\nEkhon ache: ${fmt(o - (g - f), k)} (${ns(rd(o - (g - f)))} pcs)', style: const TextStyle(height: 1.7)),
          const Divider(),
          if (A.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(14), child: Text('Kono entry nei', style: sub(c)))) else ...A.map((x) => x.$3),
        ]))));
      });
}

class SetDlg extends StatefulWidget {
  final int i;
  const SetDlg(this.i, {super.key});
  @override
  State<SetDlg> createState() => _SetS();
}
class _SetS extends State<SetDlg> {
  late final sk = TC('${st.K(widget.i)}'), sd = TC(nz(st.PR(widget.i))), sp = TC(st.PR(widget.i) > 0 ? m2(st.PR(widget.i) / st.K(widget.i)) : ''),
      slv = TC(nz(st.lv['${widget.i}'])), skc = TC(nz(st.CP(widget.i)));
  double v(TextEditingController t) => double.tryParse(t.text) ?? 0;
  void syncP() { final k = v(sk), d = v(sd); sp.text = k > 0 && d > 0 ? m2(d / k) : ''; }
  void lvc() { final d = v(sd), l = double.tryParse(slv.text); if (d > 0 && slv.text.isNotEmpty && l != null && l >= 0) skc.text = m2(d * (1 - l / 100)); }
  @override
  Widget build(BuildContext c) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h2(st.name(widget.i)),
        fld(c, 'Ei product 1 ctn e koto pcs?', sk, on: (_) => syncP()),
        fld(c, '1 ctn er dam (tk)', sd, on: (_) { syncP(); lvc(); }),
        fld(c, '1 pcs er dam (tk), ctn dam theke auto ashe', sp, on: (_) { final k = v(sk), p = v(sp); sd.text = k > 0 && p > 0 ? m2(p * k) : ''; }),
        fld(c, 'Lav % (bikri dam theke koto % lav pao). Kroy dor = dam − dam × lav%', slv, on: (_) => lvc()),
        fld(c, 'Kroy dor (dealer price): 1 ctn = ___ tk (stock dam er jonno)', skc, on: (_) { final d = v(sd); slv.text = d > 0 && skc.text.isNotEmpty ? m2((d - v(skc)) / d * 100) : ''; }),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Bondho'))), gap,
          Expanded(child: FilledButton(onPressed: () {
            final k = int.tryParse(sk.text) ?? 0;
            if (k <= 0) return;
            final i = widget.i;
            st.per['$i'] = k; st.pr['$i'] = v(sd); st.cp['$i'] = v(skc); st.lv['$i'] = v(slv);
            st.save(); Navigator.pop(c);
          }, child: const Text('Save'))),
        ]),
      ]))));
}

// ───────────────────────── Tab 0: Entry ─────────────────────────
class EntryTab extends StatefulWidget {
  const EntryTab({super.key});
  @override
  State<EntryTab> createState() => _EntryS();
}
class _EntryS extends State<EntryTab> {
  final dt = TC(today()), c1 = TC(), c2 = TC(), ec = TC(), nm = TC(), nk = TC(), np = TC();
  int pe = 0; bool nx = st.S['nx'] != false;
  String cps(int i) => nz(st.CP(i));
  double n(TextEditingController t) => pf(t.text);
  @override
  void initState() { super.initState(); if (st.valid.isNotEmpty) pe = st.valid.first; ec.text = cps(pe); curTab.addListener(_tab); }
  void _tab() { if (curTab.value == 0 && mounted) setState(() => ec.text = cps(pe)); }
  @override
  void dispose() { curTab.removeListener(_tab); super.dispose(); }
  void go(int d) {
    final v = st.valid; if (v.isEmpty) return;
    var idx = v.indexOf(pe); if (idx < 0) idx = 0;
    setState(() { pe = v[(idx + d).clamp(0, v.length - 1)]; ec.text = cps(pe); });
  }
  void save() {
    final c = n(c1), p = n(c2);
    if (c == 0 && p == 0) { toast(context, 'Ctn ba pcs dao'); return; }
    final cpv = ec.text.isNotEmpty ? pf(ec.text) : st.CP(pe);
    st.log.add({'id': newId(), 'd': dt.text.isEmpty ? today() : dt.text, 't': 'open', 'i': pe, 'c': c, 'p': p, 'cp': cpv});
    if (cpv > 0) st.cp['$pe'] = cpv;
    c1.clear(); c2.clear(); st.save();
    if (nx) go(1);
    toast(context, 'Save hoyeche ✓');
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        if (st.valid.isNotEmpty && st.isDel(pe)) { pe = st.valid.first; ec.text = cps(pe); }
        final k = st.K(pe), q = n(c1) * k + n(c2), s = st.stock(pe);
        return ListView(padding: pad, children: [
          cardW([
            Text('Ekhane shudhu stock jog hoy (Prothom stock), jekono tarikhe. Market er mal ber/ferot Market tab e.', style: sub(ctx)),
            lb(ctx, 'Tarikh'), DateF(dt),
            lb(ctx, 'Product'),
            ProdSel(items: st.valid, value: pe, del: true, onChanged: (i) => setState(() { pe = i; ec.text = cps(i); })),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: OutlinedButton(onPressed: () => showDet(ctx, pe), child: const Text('Details'))), gap,
              Expanded(child: OutlinedButton(onPressed: () => showSet(ctx, pe), child: const Text('Pcs/Ctn')))]),
            Row(children: [Expanded(child: fld(ctx, 'CTN', c1, hint: '0', on: (_) => setState(() {}))), gap, Expanded(child: fld(ctx, 'PCS', c2, hint: '0', on: (_) => setState(() {})))]),
            fld(ctx, 'Kroy dor (dealer price), 1 ctn = ___ tk', ec),
            const SizedBox(height: 10),
            Text('Ekhon stock: ${fmt(s, k)}${q != 0 ? '  →  Pore: ${fmt(s + q, k)}' : ''}  (1 ctn = $k pcs)', style: sub(ctx).copyWith(fontWeight: FontWeight.w500)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: nx, title: const Text('Save korle porer product e jabe'),
                onChanged: (v) { nx = v ?? true; st.S['nx'] = nx; st.save(); }),
            big('Save koro', save),
          ]),
          Card(child: ExpansionTile(shape: const Border(), collapsedShape: const Border(), title: const Text('Notun product add', style: TextStyle(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), expandedCrossAxisAlignment: CrossAxisAlignment.start, children: [
            fld(ctx, 'Nam', nm, num: false, hint: 'Product er nam'),
            Row(children: [Expanded(child: fld(ctx, '1 ctn e pcs', nk, hint: '1')), gap, Expanded(child: fld(ctx, '1 ctn dam (tk)', np, hint: '0'))]),
            big('+ Add koro', () {
              final name = nm.text.trim(), k = int.tryParse(nk.text) ?? 0;
              if (name.isEmpty || k <= 0) { toast(ctx, 'Nam ar 1 ctn e pcs dao'); return; }
              st.custom.add([name, k]);
              final i = st.n - 1;
              st.pr['$i'] = double.tryParse(np.text) ?? 0;
              nm.clear(); nk.clear(); np.clear();
              pe = i; ec.text = cps(i); st.save();
            }),
          ])),
        ]);
      });
}

// ───────────────────────── Tab 1: Stock ─────────────────────────
class SRow { final int i, k; final bool red; final List<String> c; SRow(this.i, this.k, this.red, this.c); }
class StockTab extends StatefulWidget {
  const StockTab({super.key});
  @override
  State<StockTab> createState() => _StockS();
}
class _StockS extends State<StockTab> {
  int sm = 0; final d1 = TC(today()), d2 = TC(today()), q = TC();
  double rcst(int i) => st.acost(i, sm == 1 ? d2.text : '');
  List<String> get heads => sm < 2 ? ['Ctn-Pcs', 'Total pcs', 'Dam'] : ['Joma', 'Bikri', 'Bikri dam'];
  (List<SRow>, double) getData([bool all = false]) {
    final f = q.text.trim().toLowerCase(), a = d1.text, b = d2.text;
    final R = <SRow>[]; double tv = 0;
    bool inR(Map e) { final d = e['d'] as String; return (sm == 0 || b.isEmpty || d.compareTo(b) <= 0) && (sm != 2 || a.isEmpty || d.compareTo(a) >= 0); }
    for (final i in st.valid) {
      if (f.isNotEmpty && !st.name(i).toLowerCase().contains(f)) continue;
      final k = st.K(i);
      final L = st.log.where((e) => e['i'] == i && inR(e)).toList(), M = st.mk.where((r) => r['i'] == i && inR(r)).toList();
      if (L.isEmpty && M.isEmpty) { if (all && sm < 2) R.add(SRow(i, k, true, ['Stock nai', '0', ''])); continue; }
      final j = L.fold(0.0, (s, e) => s + st.qty(e)), net = M.fold(0.0, (s, r) => s + st.nq(r));
      if (sm < 2) {
        final qq = rd(j - net), c = rcst(i), v = qq / k * c; tv += v;
        R.add(SRow(i, k, qq <= 0, [qq == 0 ? 'Stock nai' : fmt(qq, k), ns(qq), c > 0 ? money(v) : '']));
      } else {
        final v = M.fold(0.0, (s, r) => s + st.nq(r) / k * nn(r['r'])); tv += v;
        R.add(SRow(i, k, false, [fmt(j, k), fmt(net, k), v != 0 ? mm2(v) : '']));
      }
    }
    return (R, tv);
  }
  Future<void> pdf() async {
    final (R, tv) = getData(true);
    if (R.isEmpty) { toast(context, 'Kono entry nei'); return; }
    final h = heads, title = sm == 0 ? 'Final Stock Report' : sm == 1 ? 'Stock Report' : 'Lenden Report';
    final a = d1.text.isEmpty ? '?' : d1.text, b = d2.text.isEmpty ? today() : d2.text;
    final sb = sm == 0 ? 'Tarikh: ${today()}' : sm == 1 ? 'Stock $b tarikh porjonto' : 'Lenden $a theke $b';
    final rows = [for (var x = 0; x < R.length; x++) () {
      final r = R[x]; final kd = sm < 2 ? rcst(r.i) : st.PR(r.i);
      return HR(['${x + 1}', esc(st.name(r.i)), '${r.k} pcs', esc(r.c[0]), kd > 0 ? mm2(kd) : '', esc(r.c[1]), esc(r.c[2])], r.red ? 'red' : '');
    }()];
    final html = pdfHtml(title, sb, ['No', 'Product', '1 ctn =', h[0], sm < 2 ? 'Kroy dor' : 'Bikri dor', h[1], h[2]], rows,
        right: {4, 5, 6}, top: sm < 2 ? 'Red = stock nai: ${R.where((r) => r.red).length} ta' : '',
        foot: '${sm == 2 ? 'Total bikri dam: ' : 'Total stock dam (kroy dor): '}${money(tv)} tk');
    await exportPdf(context, '${sm == 2 ? 'lenden-' : 'stock-'}${today()}.pdf', html);
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        final (R, tv) = getData();
        final h = heads;
        return ListView(padding: pad, children: [
          cardW([
            Tog(const ['Ekhon', 'Tarikh obdhi', 'Lenden'], sm, (v) => setState(() => sm = v)),
            if (sm > 0) Row(children: [
              if (sm == 2) Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, 'Theke'), DateF(d1, clear: true, on: () => setState(() {}))])),
              if (sm == 2) gap,
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, sm == 2 ? 'Porjonto' : 'Tarikh porjonto'), DateF(d2, clear: true, on: () => setState(() {}))])),
            ]),
            const SizedBox(height: 12),
            TextField(controller: q, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: '🔍 Product khujo...')),
            const SizedBox(height: 12),
            if (R.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Kono entry nei', style: sub(ctx)))),
            for (final r in R) Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: r.red ? bad(ctx).withValues(alpha: 0.08) : null, borderRadius: BorderRadius.circular(12), border: Border.all(color: mut(ctx).withValues(alpha: 0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(st.name(r.i), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('1 ctn = ${r.k} pcs\n${rcst(r.i) > 0 ? 'Kroy dor: ${mm2(rcst(r.i))} tk/ctn (pcs ${mm2(rcst(r.i) / r.k)})' : 'kroy dor deya nai'}\nBikri dam: ${st.PR(r.i) > 0 ? '${mm2(st.PR(r.i))} tk/ctn' : 'nai'}${nn(st.lv['${r.i}']) > 0 ? ' · Lav ${ns(nn(st.lv['${r.i}']))}%' : ''}', style: sub(ctx).copyWith(fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(children: [for (var x = 0; x < 3; x++) Expanded(flex: x == 0 ? 4 : 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h[x], style: sub(ctx).copyWith(fontSize: 11.5)), Text(r.c[x].isEmpty ? '-' : r.c[x], style: TextStyle(fontWeight: FontWeight.w600, color: r.red && x == 0 ? bad(ctx) : null)),
                ]))]),
                Row(children: [
                  TextButton(onPressed: () => showDet(ctx, r.i), child: const Text('Details')),
                  TextButton(onPressed: () => showSet(ctx, r.i), child: const Text('Pcs/Ctn set')),
                ]),
              ]),
            ),
            if (R.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${sm == 2 ? 'Total bikri dam: ' : 'Total stock dam (kroy dor): '}${money(tv)} tk', style: TextStyle(color: ac(ctx), fontWeight: FontWeight.w800, fontSize: 21))),
            big('PDF download', pdf),
          ]),
        ]);
      });
}

// ───────────────────────── Tab 2: Market ─────────────────────────
class MktTab extends StatefulWidget {
  const MktTab({super.key});
  @override
  State<MktTab> createState() => _MktS();
}
class _MktS extends State<MktTab> {
  final mdt = TC(today()), mb1 = TC(), mb2 = TC(), mbr = TC(), mf1 = TC(), mf2 = TC(), mfr = TC(), hy1 = TC(), hy2 = TC();
  int mb = 0; int? mf; bool mbc = true, fm = false; String loaded = '';
  String get date => mdt.text.isEmpty ? today() : mdt.text;
  @override
  void initState() { super.initState(); if (st.valid.isNotEmpty) mb = st.valid.first; rmb(); }
  void rmb() => mbr.text = nz(st.PR(mb));
  void addBahir() {
    final c = pf(mb1.text), p = pf(mb2.text);
    if (c == 0 && p == 0) { toast(context, 'Ctn ba pcs dao'); return; }
    Map? r; for (final x in st.mk) { if (x['d'] == date && x['i'] == mb) r = x; }
    if (r == null) { r = {'id': newId(), 'd': date, 'i': mb, 'gc': 0.0, 'gp': 0.0, 'fc': 0.0, 'fp': 0.0, 'r': 0.0}; st.mk.add(r); }
    r['gc'] = rd(nn(r['gc']) + c); r['gp'] = rd(nn(r['gp']) + p);
    r['r'] = mbr.text.isNotEmpty ? pf(mbr.text) : st.PR(mb);
    mb1.clear(); mb2.clear();
    if (mbc) { final v = st.valid, idx = v.indexOf(mb); mb = v[(idx + 1).clamp(0, v.length - 1)]; rmb(); }
    st.save(); toast(context, 'Jog hoyeche ✓');
  }
  void ffe() {
    final R = st.sellData(date); SD? x; for (final y in R) { if (y.i == mf) x = y; }
    if (x == null) return;
    x.r['fc'] = pf(mf1.text); x.r['fp'] = pf(mf2.text); x.r['r'] = pf(mfr.text); st.save();
  }
  (List<SD>, double) hyData() {
    final a = hy1.text, b = hy2.text;
    final R = [for (final r in st.mk) if ((a.isEmpty || (r['d'] as String).compareTo(a) >= 0) && (b.isEmpty || (r['d'] as String).compareTo(b) <= 0) && !st.isDel(r['i'])) st.sd(r)];
    R.sort((x, y) { final c = (x.r['d'] as String).compareTo(y.r['d']); return c != 0 ? c : x.i - y.i; });
    return (R, R.fold(0.0, (s, x) => s + x.v));
  }
  Future<void> sheetPdf(List<SD> R, double tv) async {
    if (R.isEmpty) { toast(context, 'Kono entry nei'); return; }
    final lo = st.labOf(R, date);
    final rows = [for (var x = 0; x < R.length; x++) HR(['${x + 1}', esc(st.name(R[x].i)), dq(R[x].g, R[x].k), dq(R[x].f, R[x].k), dq(R[x].net, R[x].k), nn(R[x].r['r']) > 0 ? mm2(nn(R[x].r['r'])) : '', nn(R[x].r['r']) > 0 ? mm2(R[x].v) : ''])];
    final foot = 'Total (${R.length} ta product): ${mm2(tv)} tk' + (lo.$3 > 0 ? '<br>Kroy dam: ${mm2(lo.$1)} tk &nbsp; <span style="color:${lo.$2 >= 0 ? '#15803d' : '#b91c1c'}">Lab: ${sg(lo.$2)} tk</span>' : '');
    await exportPdf(context, 'market-sheet-$date.pdf', pdfHtml('Market Sheet', 'Tarikh: $date', ['No', 'Product', 'Gelo', 'Ferot', 'Bikri', 'Dor/ctn', 'Dam'], rows, right: {5, 6}, foot: foot));
  }
  Future<void> histPdf() async {
    final (R, tv) = hyData();
    if (R.isEmpty) { toast(context, 'Kono market nai'); return; }
    final rows = <HR>[]; String? last; var days = 0;
    for (final x in R) {
      final d = x.r['d'] as String;
      if (d != last) { last = d; days++; final t = R.where((y) => y.r['d'] == d).fold(0.0, (s, y) => s + y.v); rows.add(HR(['Tarikh: $d', '', '', '', '', 'Total: ${mm2(t)} tk'], 'hd')); }
      final rr = nn(x.r['r']);
      rows.add(HR([esc(st.name(x.i)), dq(x.g, x.k), dq(x.f, x.k), dq(x.net, x.k), rr > 0 ? mm2(rr) : '', rr > 0 ? mm2(x.v) : '']));
    }
    final a = hy1.text, b = hy2.text;
    await exportPdf(context, 'market-history-${today()}.pdf', pdfHtml('Market History', a.isNotEmpty || b.isNotEmpty ? '${a.isEmpty ? 'shuru' : a} theke ${b.isEmpty ? 'ekhon porjonto' : b}' : 'Shob market',
        ['Product', 'Gelo', 'Ferot', 'Bikri', 'Dor/ctn', 'Dam'], rows, right: {4, 5}, foot: '$days ta market &nbsp; | &nbsp; History total: ${mm2(tv)} tk'));
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        if (st.valid.isNotEmpty && st.isDel(mb)) { mb = st.valid.first; rmb(); }
        final R = st.sellData(date), items = R.map((x) => x.i).toList();
        if (mf == null || !items.contains(mf)) mf = items.isNotEmpty ? items.first : null;
        SD? cur; for (final x in R) { if (x.i == mf) cur = x; }
        final key = cur == null ? '' : '$date|${cur.i}|${cur.r['id']}';
        if (key != loaded) { loaded = key; if (cur != null) { mf1.text = nz(cur.r['fc']); mf2.text = nz(cur.r['fp']); mfr.text = nz(cur.r['r']); } }
        final tv = R.fold(0.0, (s, x) => s + x.v);
        final (H, htv) = hyData();
        final days = <String, double>{}; for (final x in H) { days[x.r['d']] = (days[x.r['d']] ?? 0) + x.v; }
        final cnt = <String, int>{}; for (final x in H) { cnt[x.r['d']] = (cnt[x.r['d']] ?? 0) + 1; }
        return ListView(padding: pad, children: [
          cardW([lb(ctx, 'Market er tarikh'), DateF(mdt, on: () => setState(() { fm = false; loaded = ''; rmb(); }))]),
          cardW([
            h2('1. Bahir (mal gelo)'),
            ProdSel(items: st.valid, value: mb, onChanged: (i) => setState(() { mb = i; rmb(); })),
            Row(children: [Expanded(child: fld(ctx, 'CTN', mb1, hint: '0')), gap, Expanded(child: fld(ctx, 'PCS', mb2, hint: '0')), gap, Expanded(child: fld(ctx, 'Dor / ctn', mbr))]),
            CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: mbc, title: const Text('Add korle porer product e jabe'), onChanged: (v) => setState(() => mbc = v ?? true)),
            big('+ Bahir e jog koro', addBahir),
            if (R.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 10), child: Text('Ei tarikhe bahir:', style: sub(ctx))),
              for (final x in R) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: '${st.name(x.i)} · '), TextSpan(text: dq(x.g, x.k), style: const TextStyle(fontWeight: FontWeight.bold))]))),
                xBtn(() async { if (await confirm(ctx, 'Ei bahir entry delete korben?')) { st.mk.removeWhere((m) => m['id'] == x.r['id']); st.save(); } }),
              ])),
            ],
          ]),
          cardW([
            h2('2. Ferot'),
            ProdSel(items: items, value: mf, onChanged: (i) => setState(() => mf = i)),
            if (cur == null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Age bahir e product jog koro', style: sub(ctx))) else ...[
              Row(children: [Expanded(child: fld(ctx, 'Ferot CTN', mf1, on: (_) => ffe())), gap, Expanded(child: fld(ctx, 'Ferot PCS', mf2, on: (_) => ffe())), gap, Expanded(child: fld(ctx, 'Dor / ctn', mfr, on: (_) => ffe()))]),
              const SizedBox(height: 10),
              Text.rich(TextSpan(style: const TextStyle(height: 1.7), children: [
                TextSpan(text: 'Gelo ${dq(cur.g, cur.k)} − Ferot ${dq(cur.f, cur.k)} = '),
                TextSpan(text: 'Bikri ${dq(cur.net, cur.k)}\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (nn(cur.r['r']) > 0) ...[TextSpan(text: '${ns(rd(cur.net / cur.k))} ctn × ${mm2(nn(cur.r['r']))} = '), TextSpan(text: '${mm2(cur.v)} tk', style: TextStyle(fontWeight: FontWeight.bold, color: ac(ctx)))]
                else TextSpan(text: 'dor deya nai', style: sub(ctx)),
              ])),
            ],
          ]),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => setState(() => fm = true), child: const Text('Finish: pura Market Sheet dekho'))),
          const SizedBox(height: 12),
          if (fm) cardW([
            h2('Market Sheet · $date'),
            Table(columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2)}, children: [
              TableRow(children: [for (final t in ['Product', 'Gelo', 'Ferot', 'Bikri', 'Dam']) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(t, style: sub(ctx).copyWith(fontSize: 12, fontWeight: FontWeight.w600)))]),
              for (final x in R) TableRow(children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('${st.name(x.i)}\ndor ${nn(x.r['r']) > 0 ? mm2(nn(x.r['r'])) : '?'}', style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(dq(x.g, x.k), style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(dq(x.f, x.k), style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(dq(x.net, x.k), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(nn(x.r['r']) > 0 ? mm2(x.v) : '', style: const TextStyle(fontSize: 12))),
              ]),
            ]),
            if (R.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(14), child: Text('Kono bahir entry nei', style: sub(ctx)))),
            const Divider(),
            Text('Total: ${mm2(tv)} tk', style: TextStyle(color: ac(ctx), fontWeight: FontWeight.w800, fontSize: 21)),
            const SizedBox(height: 6), labW(ctx, R, date),
            big('PDF download', () => sheetPdf(R, tv)),
          ]),
          cardW([
            h2('History (tarikh onujayi)'),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, 'Theke'), DateF(hy1, clear: true, on: () => setState(() {}))])), gap,
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, 'Porjonto'), DateF(hy2, clear: true, on: () => setState(() {}))])),
            ]),
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('Tarikh na dile shob market ashbe.', style: sub(ctx))),
            const SizedBox(height: 10),
            if (days.isEmpty) Text('Kono market nai', style: sub(ctx)) else ...[
              for (final e in days.entries) Text.rich(TextSpan(style: const TextStyle(height: 1.8), children: [TextSpan(text: '${e.key} · ${cnt[e.key]} ta product · '), TextSpan(text: '${mm2(e.value)} tk', style: const TextStyle(fontWeight: FontWeight.bold))])),
              Text('Total: ${mm2(htv)} tk', style: TextStyle(color: ac(ctx), fontWeight: FontWeight.bold)),
            ],
            big('History PDF', histPdf),
          ]),
        ]);
      });
}

// ───────────────────────── Tab 3: Calc ─────────────────────────
class CalcTab extends StatefulWidget {
  const CalcTab({super.key});
  @override
  State<CalcTab> createState() => _CalcS();
}
class _CalcS extends State<CalcTab> {
  int cp = 0, cm = -1; final a1 = TC(), a2 = TC(), b1 = TC(), b2 = TC();
  double v(TextEditingController t) => double.tryParse(t.text) ?? 0;
  @override
  void initState() { super.initState(); if (st.valid.isNotEmpty) cp = st.valid.first; }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        if (st.valid.isNotEmpty && st.isDel(cp)) cp = st.valid.first;
        final k = st.K(cp), t = (v(a1) * k + v(a2)) + cm * (v(b1) * k + v(b2)), p = st.PR(cp);
        void r() => setState(() {});
        return ListView(padding: pad, children: [cardW([
          lb(ctx, 'Product'),
          ProdSel(items: st.valid, value: cp, onChanged: (i) => setState(() => cp = i)),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text('1 ctn = $k pcs${p > 0 ? '  |  ctn dam ${mm2(p)} tk  |  pcs dam ${mm2(p / k)} tk' : ''}', style: sub(ctx))),
          const SizedBox(height: 14), h2('Prothom'),
          Row(children: [Expanded(child: fld(ctx, 'CTN', a1, hint: '0', on: (_) => r())), gap, Expanded(child: fld(ctx, 'PCS', a2, hint: '0', on: (_) => r()))]),
          const SizedBox(height: 12),
          Tog(const ['− Biyog', '+ Jog'], cm == -1 ? 0 : 1, (i) => setState(() => cm = i == 0 ? -1 : 1)),
          Row(children: [Expanded(child: fld(ctx, 'CTN', b1, hint: '0', on: (_) => r())), gap, Expanded(child: fld(ctx, 'PCS', b2, hint: '0', on: (_) => r()))]),
          const SizedBox(height: 8),
          Text(fmt(t, k), style: TextStyle(color: t < 0 ? bad(ctx) : ac(ctx), fontWeight: FontWeight.w800, fontSize: 21)),
          Text('Total ${ns(t)} pcs', style: sub(ctx)),
          if (p > 0) Text('Dam: ${mm2(t / k * p)} tk', style: TextStyle(color: ac(ctx), fontWeight: FontWeight.w800, fontSize: 20)),
        ])]);
      });
}

// ───────────────────────── Tab 4: Khata ─────────────────────────
class KhataTab extends StatelessWidget {
  const KhataTab({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        final A = <(bool, Map)>[for (final e in st.log) (false, e), for (final e in st.mk) (true, e)]
          ..sort((a, b) { final x = (b.$2['d'] as String).compareTo(a.$2['d']); return x != 0 ? x : nn(b.$2['id']).compareTo(nn(a.$2['id'])); });
        return ListView(padding: pad, children: [cardW([
          h2('Shesh 150 ta entry'),
          if (A.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Kono entry nei', style: sub(ctx)))),
          for (final (m, e) in A.take(150)) ListTile(
            contentPadding: EdgeInsets.zero, dense: true,
            title: Text(st.name(e['i'])),
            subtitle: Text('${e['d']} · ${m ? 'Market e gelo' : LB[e['t']] ?? ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(m ? 'Gelo ${ns(nn(e['gc']))} ctn ${ns(nn(e['gp']))} pcs\nFerot ${ns(nn(e['fc']))} ctn ${ns(nn(e['fp']))} pcs' : '${ns(nn(e['c']))} ctn ${ns(nn(e['p']))} pcs', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
              xBtn(() async {
                if (!await confirm(ctx, 'Ei entry delete korben?')) return;
                (m ? st.mk : st.log).removeWhere((x) => x['id'] == e['id']); st.save();
              }),
            ]),
          ),
        ])]);
      });
}

// ───────────────────────── Tab 5: Product / Backup / Reset ─────────────────────────
class ProdTab extends StatefulWidget {
  const ProdTab({super.key});
  @override
  State<ProdTab> createState() => _ProdS();
}
class _ProdS extends State<ProdTab> {
  int pp = 0; final pk = TC(), pd = TC(), plv = TC(), pcr = TC();
  @override
  void initState() { super.initState(); if (st.valid.isNotEmpty) pp = st.valid.first; rp(); curTab.addListener(_tab); }
  void _tab() { if (curTab.value == 5 && mounted) setState(rp); }
  @override
  void dispose() { curTab.removeListener(_tab); super.dispose(); }
  void rp() { pk.text = '${st.K(pp)}'; pd.text = nz(st.PR(pp)); pcr.text = nz(st.CP(pp)); plv.text = nz(st.lv['$pp']); }
  void plsync() { final l = nn(st.lv['$pp']); if (l > 0 && st.PR(pp) > 0) { st.cp['$pp'] = (st.PR(pp) * (1 - l / 100) * 100).round() / 100; pcr.text = nz(st.cp['$pp']); } }
  Future<void> backup() async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/stock-backup-${today()}.json');
      await f.writeAsString(jsonEncode(st.S));
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) { if (mounted) toast(context, 'Backup hoyni'); }
  }
  Future<void> restore() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (r == null) return;
      final f = r.files.single;
      final x = jsonDecode(utf8.decode(f.bytes ?? await File(f.path!).readAsBytes()));
      if (x is! Map || x['log'] is! List || x['custom'] is! List) throw 0;
      st.keep(); st.load(x); st.save(); setState(rp);
      if (mounted) toast(context, 'Restore hoyeche ✓');
    } catch (_) { if (mounted) toast(context, 'File ta thik na'); }
  }
  Future<void> reset(String msg, void Function() f, String done) async {
    if (!await confirm(context, msg)) return;
    st.keep(); f(); st.save(); setState(rp);
    if (mounted) toast(context, done);
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        if (st.valid.isNotEmpty && st.isDel(pp)) { pp = st.valid.first; rp(); }
        return ListView(padding: pad, children: [
          cardW([
            h2('Product er pcs/ctn ar dam'),
            ProdSel(items: st.valid, value: pp, onChanged: (i) => setState(() { pp = i; rp(); })),
            Row(children: [
              Expanded(child: fld(ctx, '1 ctn = ___ pcs', pk, on: (s) { final v = int.tryParse(s) ?? 0; if (v > 0) { st.per['$pp'] = v; st.save(); } })), gap,
              Expanded(child: fld(ctx, '1 ctn dam (tk)', pd, on: (s) { st.pr['$pp'] = double.tryParse(s) ?? 0; plsync(); st.save(); })),
            ]),
            fld(ctx, 'Lav % (bikri dam theke koto % lav pao). Kroy dor = dam − dam × lav%', plv, on: (s) { st.lv['$pp'] = double.tryParse(s) ?? 0; plsync(); st.save(); }),
            fld(ctx, 'Kroy dor (dealer price): 1 ctn = ___ tk (stock dam er jonno)', pcr, on: (s) {
              final c = double.tryParse(s) ?? 0, p = st.PR(pp);
              st.cp['$pp'] = c; st.lv['$pp'] = p > 0 && c > 0 ? ((p - c) / p * 10000).round() / 100 : 0.0;
              plv.text = nz(st.lv['$pp']); st.save();
            }),
          ]),
          cardW([
            h2('Backup (data nirapod rakhte)'),
            Row(children: [Expanded(child: OutlinedButton(onPressed: backup, child: const Text('Backup download'))), gap, Expanded(child: OutlinedButton(onPressed: restore, child: const Text('Restore')))]),
          ]),
          Card(child: ExpansionTile(shape: const Border(), collapsedShape: const Border(), title: Text('⚙ Reset', style: sub(ctx).copyWith(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Reset korar age Backup nao.', style: sub(ctx))),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => reset('Apni ki nishchit shob entry (prothom stock, joma, bikri) muche felben? Product, pcs/ctn ar dam thakbe.', () { st.S['log'] = []; st.S['mk'] = []; }, 'Shob entry muche gechhe ✓'), child: const Text('Shob entry muche felo (product, pcs/ctn, dam thakbe)'))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => reset('Apni ki nishchit PURA reset korben? Shob entry, notun product, pcs/ctn ar dam muche jabe.', () { final nx = st.S['nx']; st.load({'nx': nx}); }, 'Pura reset hoyeche ✓'), child: const Text('Pura reset (product, pcs/ctn, dam shoho shob)'))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {
              try {
                final s = st.sp.getString('stk1_prev');
                if (s == null) { toast(ctx, 'Ager kichu nei'); return; }
                st.load(jsonDecode(s)); st.save(); setState(rp); toast(ctx, 'Ager obosthay ferot ashche ✓');
              } catch (_) { toast(ctx, 'Ferot ana gelo na'); }
            }, child: const Text('Reset undo (ager obosthay ferot)'))),
          ])),
        ]);
      });
}

// ───────────────────────── Tab 6: Hisab ─────────────────────────
class HisabTab extends StatefulWidget {
  const HisabTab({super.key});
  @override
  State<HisabTab> createState() => _HisabS();
}
class _HisabS extends State<HisabTab> {
  bool det = false;
  Future<void> addPerson() async {
    final t = TC();
    final nm = await showDialog<String>(context: context, builder: (x) => AlertDialog(
          title: const Text('Notun bekti add'),
          content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(hintText: 'Nam likhun')),
          actions: [TextButton(onPressed: () => Navigator.pop(x), child: const Text('Bondho')), FilledButton(onPressed: () => Navigator.pop(x, t.text.trim()), child: const Text('Add'))]));
    if (nm == null || nm.isEmpty) return;
    final p = {'id': newId(), 'n': nm, 't': []};
    st.hp.add(p); st.save();
    if (mounted) showDialog(context: context, builder: (_) => HDlg(p['id'] as int));
  }
  Future<void> pdf() async {
    final A = st.hp;
    if (A.isEmpty) { toast(context, 'Kono bekti nai'); return; }
    double tj = 0, tk = 0; for (final p in A) { tj += st.pj(p); tk += st.pk(p); }
    final net = tj - tk;
    String col(double v) => v > 0 ? '#15803d' : v < 0 ? '#b91c1c' : '#000';
    final rows = <HR>[];
    for (var i = 0; i < A.length; i++) {
      final p = A[i], j = st.pj(p), k = st.pk(p), b = j - k;
      rows.add(HR(['${i + 1}', esc('${p['n']}'), j > 0 ? mm2(j) : '', k > 0 ? mm2(k) : '', '<span style="color:${col(b)}">${sg(b)}</span>'], det ? 'pp' : ''));
      if (det) {
        final T = List<Map>.from(p['t'])..sort((x, y) { final c = (x['d'] as String).compareTo(y['d']); return c != 0 ? c : nn(x['id']).compareTo(nn(y['id'])); });
        for (final e in T) { rows.add(HR(['', '${esc(e['d'])} ${esc('${e['nt'] ?? ''}')}', e['ty'] == 'j' ? mm2(nn(e['a'])) : '', e['ty'] == 'k' ? mm2(nn(e['a'])) : '', ''], 'det')); }
      }
    }
    await exportPdf(context, 'hisab-${today()}.pdf', pdfHtml('Hisab Khata', 'Tarikh: ${today()}', ['No', 'Nam', 'Joma', 'Khoroch', 'Baki'], rows, right: {2, 3, 4},
        foot: 'Total joma: ${mm2(tj)} tk<br>Total khoroch: ${mm2(tk)} tk<br>Baki (joma − khoroch): <span style="color:${col(net)}">${sg(net)} tk</span>'));
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        double tj = 0, tk = 0; for (final p in st.hp) { tj += st.pj(p); tk += st.pk(p); }
        final net = tj - tk;
        return ListView(padding: pad, children: [cardW([
          SizedBox(width: double.infinity, child: FilledButton(onPressed: addPerson, child: const Text('+ Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 8),
          if (st.hp.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(14), child: Text('Kono bekti nai. + Add chapo.', style: sub(ctx)))),
          for (final p in st.hp) () {
            final j = st.pj(p), k = st.pk(p), b = j - k;
            return ListTile(contentPadding: EdgeInsets.zero, onTap: () => showDialog(context: ctx, builder: (_) => HDlg(p['id'] as int)),
              title: Text('${p['n']}'.isEmpty ? '(nam nai)' : '${p['n']}'),
              subtitle: Text('${(p['t'] as List).length} ta entry · tap koro\nJoma ${j > 0 ? mm2(j) : '-'} · Khoroch ${k > 0 ? mm2(k) : '-'}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(sg(b), style: TextStyle(fontWeight: FontWeight.w700, color: scol(ctx, b))),
                xBtn(() async { if (await confirm(ctx, "'${p['n']}' delete korben?")) { st.hp.removeWhere((x) => x['id'] == p['id']); st.save(); } }),
              ]));
          }(),
          if (st.hp.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text.rich(TextSpan(style: const TextStyle(height: 1.8), children: [
            TextSpan(text: 'Total joma: ${mm2(tj)}\nTotal khoroch: ${mm2(tk)}\n'),
            TextSpan(text: 'Baki: ${sg(net)} tk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scol(ctx, net))),
          ]))),
          CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: det, title: const Text('PDF e protita entry-o dekhao'), onChanged: (v) => setState(() => det = v ?? false)),
          big('PDF download', pdf),
        ])]);
      });
}

class HDlg extends StatefulWidget {
  final int id;
  const HDlg(this.id, {super.key});
  @override
  State<HDlg> createState() => _HDlgS();
}
class _HDlgS extends State<HDlg> {
  late final nm = TC('${gp()?['n'] ?? ''}');
  final a = TC(), d = TC(today()), nt = TC(); String ty = 'j';
  Map? gp() { for (final p in st.hp) { if (p['id'] == widget.id) return p; } return null; }
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: st, builder: (_, __) {
        final p = gp();
        if (p == null) return const SizedBox();
        final j = st.pj(p), k = st.pk(p), b = j - k, amt = am(a.text), nb = b + (ty == 'j' ? amt : -amt);
        final T = List<Map>.from(p['t'])..sort((x, y) { final z = (y['d'] as String).compareTo(x['d']); return z != 0 ? z : nn(y['id']).compareTo(nn(x['id'])); });
        return Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: TextField(controller: nm, style: const TextStyle(fontWeight: FontWeight.w700), onChanged: (s) { p['n'] = s; st.save(); })), gap, TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bondho'))]),
          const SizedBox(height: 10),
          Text.rich(TextSpan(style: const TextStyle(height: 1.7), children: [
            TextSpan(text: 'Joma: ${mm2(j)} · Khoroch: ${mm2(k)}\n'),
            TextSpan(text: 'Baki: ${sg(b)} tk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scol(c, b))),
          ])),
          const SizedBox(height: 10),
          Tog(const ['+ Joma', '− Khoroch'], ty == 'j' ? 0 : 1, (i) => setState(() => ty = i == 0 ? 'j' : 'k')),
          Row(children: [
            Expanded(child: fld(c, 'Taka (200+300 likhte paro)', a, num: false, on: (_) => setState(() {}))), gap,
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(c, 'Tarikh'), DateF(d)])),
          ]),
          fld(c, 'Note (na dileo hoy)', nt, num: false, hint: 'Bistarito...'),
          if (amt > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text.rich(TextSpan(children: [const TextSpan(text: 'Save korle Baki hobe: '), TextSpan(text: '${sg(nb)} tk', style: TextStyle(fontWeight: FontWeight.bold, color: scol(c, nb)))]))),
          big('Save', () {
            if (amt <= 0) { toast(c, 'Taka dao'); return; }
            (p['t'] as List).add({'id': newId(), 'ty': ty, 'a': amt, 'd': d.text.isEmpty ? today() : d.text, 'nt': nt.text.trim()});
            a.clear(); nt.clear(); st.save();
          }),
          const SizedBox(height: 8),
          if (T.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(14), child: Text('Kono entry nei', style: sub(c)))),
          for (final e in T) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${e['d']}\n${e['nt'] ?? ''}', style: const TextStyle(fontSize: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${e['ty'] == 'j' ? 'Joma +' : 'Khoroch −'}  ${mm2(nn(e['a']))}', style: TextStyle(fontWeight: FontWeight.w600, color: e['ty'] == 'j' ? ac(c) : bad(c))),
                xBtn(() async { if (await confirm(c, 'Ei entry delete korben?')) { (p['t'] as List).removeWhere((x) => x['id'] == e['id']); st.save(); } }),
              ])),
        ]))));
      });
}

// ───────────────────────── Tab 7: Summary ─────────────────────────
class SumTab extends StatefulWidget {
  const SumTab({super.key});
  @override
  State<SumTab> createState() => _SumS();
}
class _SumS extends State<SumTab> {
  final s1 = TC(), s2 = TC();
  bool zin(String d) => (s1.text.isEmpty || d.compareTo(s1.text) >= 0) && (s2.text.isEmpty || d.compareTo(s2.text) <= 0);
  Widget zc(BuildContext c, String lab, double v, Color col, double sz) {
    final t = money(v), big = sz > 90;
    final f = big ? (t.length > 9 ? 14.0 : t.length > 7 ? 16.0 : 19.0) : (t.length > 8 ? 10.0 : t.length > 6 ? 12.0 : 14.0);
    return Column(children: [
      Text(lab, style: sub(c).copyWith(fontSize: big ? 13 : 11.5, fontWeight: FontWeight.w600)), const SizedBox(height: 6),
      Container(width: sz, height: sz, padding: const EdgeInsets.all(4), alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: col.withValues(alpha: 0.12), border: Border.all(color: col, width: 2.5)),
          child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: f, height: 1.1))),
    ]);
  }
  Widget labLine(BuildContext c, double cost, double lab, int ln) => ln == 0 ? const SizedBox() : Text.rich(TextSpan(style: sub(c), children: [
        TextSpan(text: 'Kroy dam ${mm2(cost)} · '), TextSpan(text: 'Lab ${sg(lab)} tk', style: TextStyle(fontWeight: FontWeight.bold, color: scol(c, lab)))]));
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: st, builder: (ctx, _) {
        final D = <String, ({double sell, double j, double k, List<SD> R})>{};
        final sell = <String, double>{}, jj = <String, double>{}, kk = <String, double>{}, RR = <String, List<SD>>{};
        for (final r in st.mk) {
          final d = r['d'] as String;
          if (!zin(d) || st.isDel(r['i'])) continue;
          final x = st.sd(r); sell[d] = (sell[d] ?? 0) + x.v; (RR[d] ??= []).add(x);
        }
        for (final p in st.hp) { for (final e in p['t'] as List) { final d = e['d'] as String; if (!zin(d)) continue; if (e['ty'] == 'j') { jj[d] = (jj[d] ?? 0) + nn(e['a']); } else { kk[d] = (kk[d] ?? 0) + nn(e['a']); } } }
        final keys = {...sell.keys, ...jj.keys, ...kk.keys}.toList()..sort();
        for (final d in keys) { D[d] = (sell: sell[d] ?? 0, j: jj[d] ?? 0, k: kk[d] ?? 0, R: RR[d] ?? []); }
        double gs = 0, gj = 0, gk = 0, gc = 0, gl = 0; int gn = 0;
        final labs = <String, (double, double, int)>{};
        for (final d in keys) { final o = st.labOf(D[d]!.R, d); labs[d] = o; gc += o.$1; gl += o.$2; gn += o.$3; gs += D[d]!.sell; gj += D[d]!.j; gk += D[d]!.k; }
        final gb = gj - gk;
        Color bc(double v) => v < 0 ? bad(ctx) : ac(ctx);
        return ListView(padding: pad, children: [
          cardW([
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, 'Theke'), DateF(s1, clear: true, on: () => setState(() {}))])), gap,
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lb(ctx, 'Porjonto'), DateF(s2, clear: true, on: () => setState(() {}))])),
            ]),
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('Tarikh na dile shob din. Sell Market theke, Joma/Khoroch Hisab theke auto ashe.', style: sub(ctx))),
          ]),
          cardW([
            h2('Total'),
            Center(child: Wrap(alignment: WrapAlignment.center, spacing: 36, runSpacing: 16, children: [
              zc(ctx, 'Total Sell', gs, ac(ctx), 104), zc(ctx, 'Total Joma', gj, jm(ctx), 104), zc(ctx, 'Total Khoroch', gk, bad(ctx), 104), zc(ctx, 'Baki', gb, bc(gb), 104),
            ])),
            const SizedBox(height: 14),
            Center(child: Column(children: [Text('${keys.length} din', style: sub(ctx)), labLine(ctx, gc, gl, gn)])),
          ]),
          if (keys.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Kono din nai', style: sub(ctx)))),
          for (final d in keys.reversed) () {
            final o = D[d]!, l = labs[d]!, b = o.j - o.k;
            return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                zc(ctx, 'Sell', o.sell, ac(ctx), 68), zc(ctx, 'Joma', o.j, jm(ctx), 68), zc(ctx, 'Khoroch', o.k, bad(ctx), 68), zc(ctx, 'Baki', b, bc(b), 68)]),
              if (l.$3 > 0) Padding(padding: const EdgeInsets.only(top: 10), child: labLine(ctx, l.$1, l.$2, l.$3)),
            ])));
          }(),
        ]);
      });
}
