import 'dart:html' as html; import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; import 'package:js/js.dart'; import 'package:js/js_util.dart'; import 'package:string_similarity/string_similarity.dart'; import 'dart:async';


class ManualTextCompare extends StatefulWidget {
  const ManualTextCompare({super.key});

  @override
  State createState() => _ManualTextCompareState();
}

class _ManualTextCompareState extends State<ManualTextCompare> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String text1 = '', text2 = '';
  List rows1 = [], rows2 = [];
  List matched = [], unmatched1 = [], unmatched2 = [];

  List filteredMatched = [], filteredUnmatched1 = [], filteredUnmatched2 = [];
//ValueNotifier<List<String>> unmatchedRight = ValueNotifier([]);
  String searchMatched = '', searchUnmatched1 = '', searchUnmatched2 = '';
List<String> unmatchedRightLines = [];
List<String> unmatchedRight = [];

  void compareManualText() {
  rows1 = _extract(text1);
  rows2 = _extract(text2);
  matched.clear();
  unmatched1.clear();
  unmatched2.clear();

  for (var t1 in rows1) {
    bool found = false;
    for (var t2 in rows2) {
      if (StringSimilarity.compareTwoStrings(t1, t2) == 1) {
        matched.add(t1);
        found = true;
        break;
      }
    }
    if (!found) unmatched1.add(t1);
  }

  for (var t2 in rows2) {
    if (!matched.contains(t2)) unmatched2.add(t2);
  }

  filterSearchResults();
  setState(() {});
}

void compareTeOnly() {
final teGig = RegExp(r'\bTE(?!G)[^\s]*', caseSensitive: true);
  final regex = RegExp(r'\d+'); // أو استخدم \d+(\.\d+)? للأرقام العشرية


bool isGig(String line) => teGig.hasMatch(line.trim());
  Map<String, String> extractTegMap(String text) {
   


    final lines = text.split('\n');

    final map = <String, String>{};
 final mapx = <String, String>{};
    for (var line in lines) {
      final match = teGig.firstMatch(line);



      if (match != null) {
// final matches = regex.allMatches(match.toString());

// // تحويل الأرقام إلى List مع لصق "te" في بدايتها
// final result = matches.map((m) => 'te${m.group(0)}').toList();
//        // final teg = match.group(0)!;
       final teg = match.group(0)!;
        map[teg] = line.trim(); // احتفظ بالنص الكامل

      }
    }

    return map;
  }


  final map1 = extractTegMap(text1);
  final map2 = extractTegMap(text2);

  final teg1 = map1.keys.toSet();
  final teg2 = map2.keys.toSet();

  matched.clear();
  unmatched1.clear();
  unmatched2.clear();

  for (final t in teg1) {
    if (teg2.contains(t)) {
      matched.add(map1[t]!); // السطر الكامل من النص الأول
    } else {
      unmatched1.add(map1[t]!);
    }
  }

  for (final t in teg2) {
    if (!teg1.contains(t)) {
      unmatched2.add(map2[t]!); // السطر الكامل من النص الثاني
    }
  }

  filterSearchResults();
  setState(() {});
}
List<String> extractTeCodesFromTable(String tableText, {String delimiter = '\t'}) {
  final List<String> result = [];

  // تقسيم النص إلى صفوف
  final rows = tableText.split('\n');

  for (var row in rows) {
    final columns = row.split(delimiter);

    for (var col in columns) {
      final match = RegExp(r'TE\d+').firstMatch(col);
      if (match != null) {
        result.add(match.group(0)!); // نضيف TE مع الرقم
      }
    }
  }

  return result;
}

void extractCleanTeLinesToRight(String text) {
  final lines = text.split('\n');
  final tePattern = RegExp(r'\bTE[^\s\t]*', caseSensitive: true); // التقاط TE وما يليها حتى الفاصل

  List<String> result = [];

  for (var line in lines) {
    final matches = tePattern.allMatches(line);
    String cleanedLine = line;
    print('line');

print(line);
    for (final match in matches) {
      final rawTe = match.group(0)!;
      final digits = RegExp(r'\d+').allMatches(rawTe).map((m) => m.group(0)).join();
      if (digits.isNotEmpty) {
        final cleanedTe = 'TE$digits';
        cleanedLine = '${cleanedLine.replaceFirst(rawTe, cleanedTe)}   $cleanedTe'; 
      }
    }

    if (cleanedLine.contains(RegExp(r'TE\d+'))) {
      result.add(cleanedLine);
    }
  }

  setState(() {
    unmatchedRight = result;
  });
    print('unmatchedRight');

  print(unmatchedRight);
}
void compareTegOnly() {
final teGig = RegExp(r'\b(TEG|TE)\d+\b', caseSensitive: false);

bool isGig(String line) => teGig.hasMatch(line.trim());
  Map<String, String> extractTegMap(String text) {
    final lines = text.split('\n');
    final map = <String, String>{};

    for (var line in lines) {
      final match = teGig.firstMatch(line);
      if (match != null) {
        final teg = match.group(0)!;
        map[teg] = line.trim(); // احتفظ بالنص الكامل
      }
    }

    return map;
  }

  final map1 = extractTegMap(text1);
  final map2 = extractTegMap(text2);

  final teg1 = map1.keys.toSet();
  final teg2 = map2.keys.toSet();

  matched.clear();
  unmatched1.clear();
  unmatched2.clear();

  for (final t in teg1) {
    if (teg2.contains(t)) {
      matched.add(map1[t]!); // السطر الكامل من النص الأول
    } else {
      unmatched1.add(map1[t]!);
    }
  }

  for (final t in teg2) {
    if (!teg1.contains(t)) {
      unmatched2.add(map2[t]!); // السطر الكامل من النص الثاني
    }
  }

  filterSearchResults();
  setState(() {});
}

  List<String> _extract(String text) {
  return text
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line) // لا تزيل أي مسافات
      .toList();
}

  void copyAllText(List rows) {
    final text = rows.join('\n');
    final temp = html.TextAreaElement();
    temp.value = text;
    html.document.body!.append(temp);
    temp.select();
    html.document.execCommand('copy');
    temp.remove();
  }
void copyColumnAsExcel(List<dynamic> rows, String title) {
  final buffer = StringBuffer();

  /// يُرجِع أولوية المقطع (كلما كان الرقم أصغر كان المقطع أَوْلَى)
  int priority(String text) {
    final t = text.toLowerCase();
    if (t.contains('pe'))  return 1;
    if (t.contains('obr')) return 2;
    if (t.contains('oct')) return 3;
    if (t.contains('obo')) return 4;
    if (t.contains('hos')) return 5;
    if (t.contains('awa')) return 6;
    if (t.contains('saw')) return 7;
    if (t.contains('smh')) return 8;
    if (t.contains('smo')) return 9;
    return 999;
  }

  final teGig = RegExp(r'^(TEG|TE)\d+$');  // يقبل TEG123 أو TE123 فقط (حروف كبيرة)   
  final whitespace = RegExp(r'\s+');            // أى عدد من الفراغات / التابات

  for (final row in rows) {
    final parts = row.toString().trim().split(whitespace).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) continue;

    // -------- 1) حدّد gig (أول مقطع يُطابق TE\d+)
    String gig  = '';
    int gigIdx  = -1;
    for (var i = 0; i < parts.length; i++) {
      if (teGig.hasMatch(parts[i])) {
        gig = parts[i];
        gigIdx = i;
        break;
      }
    }
    if (gigIdx != -1) parts.removeAt(gigIdx); // أزل gig من القائمة الأصليّة

    // -------- 2) حدّد core و aggregator
    String core = parts.isNotEmpty ? parts.first : '';
    List<String> aggTokens = parts.length > 1 ? parts.sublist(1) : [];

    // تبادل core و aggregator بحسب الأولوية
    if (priority(aggTokens.join(' ')) < priority(core)) {
      final tmp       = core;
      core            = aggTokens.join(' ');
      aggTokens       = [tmp];
    }

    // -------- 3) صفّ الأعمدة بالترتيب: Core | Agg‑tokens (كل مقطع فى عمود) | Gig
    final excelCols = <String>[core, ...aggTokens, gig];
    buffer.writeln(excelCols.join('\t'));
  }

  // -------- 4) نسخ إلى الحافظة
  final temp = html.TextAreaElement()..value = buffer.toString();
  html.document.body!.append(temp);
  temp.select();
  html.document.execCommand('copy');
  temp.remove();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("تم نسخ $title بصيغة Excel (Text‑to‑Columns)")),
  );
}
// void copyColumnAsExcel(List<dynamic> rows, String title) {
//   final buffer = StringBuffer();

//   for (final row in rows) {
//     final line = row.toString().trim();
//     final parts = line.split(RegExp(r'\s+'));

//     if (parts.isEmpty) continue;

//     String core = '';
//     String agg = '';
//     String gig = '';

//     if (parts.length == 1) {
//       core = parts[0];
//     } else if (parts.length == 2) {
//       core = parts[0];
//       gig = parts[1];
//     } else {
//       core = parts.first;
//       gig = parts.last;
//       agg = parts.sublist(1, parts.length - 1).join(' ');
//     }

//     // تابع يعطي أولوية المقاطع
//     int getPriority(String text) {
//       text = text.toLowerCase();
//       if (text.contains('pe')) return 1;
//       if (text.contains('obr')) return 2;
//       if (text.contains('oct')) return 3;
//       if (text.contains('obo')) return 4;
//       if (text.contains('hos')) return 5;
//       if (text.contains('saw')) return 6;
//        if (text.contains('smh')) return 7;
//         if (text.contains('smo')) return 8;
//          if (text.contains('awa')) return 5;
//       return 999;
//     }

//     final corePriority = getPriority(core);
//     final aggPriority = getPriority(agg);

//     if (aggPriority < corePriority) {
//       final temp = core;
//       core = agg;
//       agg = temp;
//     }

//     buffer.writeln('$core\t$agg\t$gig');
//   }

//   final temp = html.TextAreaElement();
//   temp.value = buffer.toString();
//   html.document.body!.append(temp);
//   temp.select();
//   html.document.execCommand('copy');
//   temp.remove();

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("تم نسخ $title بصيغة Excel (text-to-columns)")),
//   );
// }
// void copyColumnAsExcel(List<dynamic> rows, String title) {
//   final buffer = StringBuffer();

//   for (final row in rows) {
//     final line = row.toString().trim();
//     final parts = line.split(RegExp(r'\s+'));

//     if (parts.isEmpty) continue;
//     // كتابة كل جزء في عمود مستقل (مفصول بـ tab)
//     //buffer.writeln(parts.join('\t'));
  

//   final temp = html.TextAreaElement();
//   temp.value = buffer.toString();
//   html.document.body!.append(temp);
//   temp.select();
//   html.document.execCommand('copy');
//   temp.remove();
//     String core = '';
//     String agg = '';
//     String gig = '';

//     if (parts.length == 1) {
//       core = parts[0];
//     } else if (parts.length == 2) {
//       core = parts[0];
//       gig = parts[1];
//     } else {
//       core = parts.first;
//       gig = parts.last;
//       agg = parts.sublist(1, parts.length - 1).join(' ');
//     }

//     // تابع يعطي أولوية المقاطع
//     int getPriority(String text) {
//       text = text.toLowerCase();
//       if (text.contains('pe')) return 1;
//       if (text.contains('obr')) return 2;
//       if (text.contains('oct')) return 3;
//       if (text.contains('obo')) return 4;
//       if (text.contains('hos')) return 5;

//       return 999;
//     }
// //     // تقسيم السطر إلى كلمات بناءً على المسافات
// //     final parts = line.split(RegExp(r'\s+'));

// //     // كتابة كل جزء في عمود مستقل (مفصول بـ tab)
// //     buffer.writeln(parts.join('\t'));
// //   }

// //   final temp = html.TextAreaElement();
// //   temp.value = buffer.toString();
// //   html.document.body!.append(temp);
// //   temp.select();
// //   html.document.execCommand('copy');
// //   temp.remove();
//     final corePriority = getPriority(core);
//     final aggPriority = getPriority(agg);

//     if (aggPriority < corePriority) {
//       final temp = core;
//       core = agg;
//       agg = temp;
//     }

//    // buffer.writeln('$core\t$agg\t$gig');
//        buffer.writeln(parts.join('\t'));

//   }

//   final temp = html.TextAreaElement();
//   temp.value = buffer.toString();
//   html.document.body!.append(temp);
//   temp.select();
//   html.document.execCommand('copy');
//   temp.remove();

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("تم نسخ $title بصيغة Excel (text-to-columns)")),
//   );
// }
// void copyColumnAsExcel(List<dynamic> rows, String title) {
//   final buffer = StringBuffer();

//   for (final row in rows) {
//     final line = row.toString().trim();

//     if (line.isEmpty) continue;

//     // تقسيم السطر إلى كلمات بناءً على المسافات
//     final parts = line.split(RegExp(r'\s+'));

//     // كتابة كل جزء في عمود مستقل (مفصول بـ tab)
//     buffer.writeln(parts.join('\t'));
//   }

//   final temp = html.TextAreaElement();
//   temp.value = buffer.toString();
//   html.document.body!.append(temp);
//   temp.select();
//   html.document.execCommand('copy');
//   temp.remove();

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text("تم نسخ $title بصيغة Excel (text-to-columns)")),
//   );
// }
void copyAsExcelTable(List<dynamic> list1, List<dynamic> list2, List<dynamic> list3) {
  final buffer = StringBuffer();
  final maxLength = [list1.length, list2.length, list3.length].reduce((a, b) => a > b ? a : b);

  for (int i = 0; i < maxLength; i++) {
    final val1 = i < list1.length ? list1[i] : '';
    final val2 = i < list2.length ? list2[i] : '';
    final val3 = i < list3.length ? list3[i] : '';
    buffer.writeln('$val1\t$val2\t$val3');
  }

  final temp = html.TextAreaElement();
  temp.value = buffer.toString();
  html.document.body!.append(temp);
  temp.select();
  html.document.execCommand('copy');
  temp.remove();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("تم نسخ الجدول بصيغة Excel")),
  );
}
  void filterSearchResults() {
    String clean(String text) => text.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    filteredMatched = matched.where((e) => clean(e).contains(clean(searchMatched))).toList();
    filteredUnmatched1 = unmatched1.where((e) => clean(e).contains(clean(searchUnmatched1))).toList();
    filteredUnmatched2 = unmatched2.where((e) => clean(e).contains(clean(searchUnmatched2))).toList();
  }

  Widget _textColumn(String title, List rows, Color color, void Function(String) onSearchChanged) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(hintText: 'بحث...'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    IconButton(
      icon: const Icon(Icons.copy),
      tooltip: 'نسخ عادي',
      onPressed: () => copyAllText(rows),
    ),
    IconButton(
      icon: const Icon(Icons.grid_on),
      tooltip: 'نسخ core/agg/TEG',
      onPressed: () => copyColumnAsExcel(rows, title),
    ),
  ],
),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: rows
                  .map((e) => Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: color,
                        child:  SelectableText(
  (e is List)
      ? e.join(' ').replaceAll(RegExp(r'\s+'), ' ')
      : e.toString(),
),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // needed for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(title: const Text(" مقارنة نصوص يدوية")), 
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'النص الأول'),
                    onChanged: (val) => text1 = val,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'النص الثاني'),
                    onChanged: (val) => text2 = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: compareManualText,
                  child: const Text("قارن النصوص"),
                ),
                ElevatedButton(
  onPressed: compareTegOnly,
  child: const Text("قارن مقاطع TEG فقط"),
),
  ElevatedButton(
  onPressed: compareTeOnly,
  child: const Text("قارن مقاطع TE فقط"),
),
 ElevatedButton(
  onPressed:(){
    print(text2);
    extractCleanTeLinesToRight(text2);} ,
  child: const Text(" arrange TE "),
),

              ],
            ),
            const SizedBox(height: 10),
            Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton.icon(
      icon: const Icon(Icons.copy),
      label: const Text("نسخ كل النتائج (Excel)"),
      onPressed: () {
        copyAsExcelTable(filteredUnmatched1, filteredMatched, filteredUnmatched2);
      },
    ),
  ],
),
const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  _textColumn("غير متطابق - الطرف الأول", filteredUnmatched1, Colors.red.shade100, (val) {
                    searchUnmatched1 = val;
                    filterSearchResults();
                    setState(() {});
                  }),
                  _textColumn("المتطابق", filteredMatched, Colors.yellow.shade200, (val) {
                    searchMatched = val;
                    filterSearchResults();
                    setState(() {});
                  }),
                  _textColumn("غير متطابق - الطرف الثاني", filteredUnmatched2, Colors.red.shade100, (val) {
                    searchUnmatched2 = val;
                    filterSearchResults();
                    setState(() {});
                  }),
                ],
              ),
            ),
             IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'نسخ النتائج',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: unmatchedRight.join('\n')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم نسخ النتائج إلى الحافظة")),
                   );
          },
        ),
               SelectableText(unmatchedRight.join('\n')), // عرض النتائج قابلة للنسخ يدوياً
       
      


          ],
        ),
      ),
    );
  }
}