import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleTextParse extends StatefulWidget {
  @override
  _SimpleTextParseState createState() => _SimpleTextParseState();
}

class _SimpleTextParseState extends State<SimpleTextParse> {
  final TextEditingController _inputController = TextEditingController();
  List<List<String>> _tableData = [];

  void _extractTable() {
  final lines = _inputController.text.split('\n');
  List<List<String>> rows = [];

  for (var line in lines) {
    if (line.trim().isEmpty) continue;

    // ابحث عن مقطع يبدأ بـ te أو teg، يليه أي رموز أو أرقام أو حروف
    final rawMatch = RegExp(r'(teg?\S*)', caseSensitive: false).firstMatch(line);
    if (rawMatch == null) continue;

    // فلترة المقطع ليكون فقط te أو teg متبوعًا بأرقام
    final raw = rawMatch.group(0) ?? '';
    final filtered = RegExp(r'^(teg?|te)(\d+)$', caseSensitive: false)
        .firstMatch(raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')) // حذف الرموز
        ?.group(0) ?? '';

    if (filtered.isEmpty) continue;

    // استخراج الـ core من بداية السطر حتى قبل te أو :
    int index1 = line.indexOf(':');
    int index2 = line.toLowerCase().indexOf(raw.toLowerCase());
    int index = index1 == -1 ? index2 : index1;
    String core = index != -1 ? line.substring(0, index).trim() : '';

    rows.add([filtered.toUpperCase(), core]);
  }

  // إزالة التكرار حسب قيمة te
  final seen = <String>{};
  rows = rows.where((row) => seen.add(row[0])).toList();

  setState(() {
    _tableData = rows.map((r) => [r[1], r[0]]).toList(); // Swap Core <=> Agg
  });
}
  void _copyAsExcel() {
    final buffer = StringBuffer();
    buffer.writeln('Core\tAggregator');
    for (var row in _tableData) {
      buffer.writeln('${row[0]}\t${row[1]}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نسخ النتائج بصيغة Excel')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تحليل نصوص بسيطة')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'ألصق النص هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _extractTable,
                  child: Text('إظهار الجدول'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _copyAsExcel,
                  child: Text('نسخ كـ Excel'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: _tableData.isEmpty
                  ? Center(child: Text('لا توجد بيانات بعد'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Core')),
                          DataColumn(label: Text('Aggregator')),
                        ],
                        rows: _tableData
                            .map(
                              (row) => DataRow(
                                cells: row.map((cell) => DataCell(Text(cell))).toList(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}