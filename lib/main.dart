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
  (double, double, int) labOf(List
