// DownVsFlap.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:flutter/services.dart';


@JS('Tesseract')
external TesseractJS get tesseract;

@JS()
@anonymous
class TesseractJS {
  external dynamic recognize(String image, String lang, dynamic options);
}

class DownVsFlap extends StatefulWidget {
  const DownVsFlap({super.key});

  @override
  State<DownVsFlap> createState() => _DownVsFlapState();
}

class _DownVsFlapState extends State<DownVsFlap> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> images = [];
  List<String> extractedTexts = [];
  bool isLoading = false;

String _extractCore(String line) {
  final start = line.indexOf('=');
  if (start == -1) return '...';

  // حدد أقرب نهاية بعد علامة =
  final after = line.substring(start + 1);
  final endIndexes = [
    after.indexOf(':'),
    after.indexOf('.'),
    after.indexOf('/'),
    after.indexOf('\\'),
  ].where((i) => i != -1).toList();

  if (endIndexes.isEmpty) {
    return after.trim();
  }

  final end = endIndexes.reduce((a, b) => a < b ? a : b);
  return after.substring(0, end).trim();
}

// String _extractGigNum(String line) {
//   final lower = line.toLowerCase();

//   final teIndex = lower.indexOf('te');
//   final portIndex = lower.indexOf('port');

//   if (teIndex == -1 || portIndex == -1 || portIndex <= teIndex) return '...';

//   final gigPart = line.substring(teIndex, portIndex).trim();
//   return gigPart.replaceAll(';', '').replaceAll('#', '').trim();
// }
// String _extractGigNum(String line) {
//   final pattern = RegExp(r'(TE.*?)(?=\s*port)', caseSensitive: false);
//   final match = pattern.firstMatch(line);

//   if (match != null) {
//     final extracted = match.group(1)!;
//     return extracted.replaceAll(';', '').replaceAll('#', '').replaceAll(',', '').replaceAll(':', '').replaceAll('.', '').trim();
//   }

//   return '...';
// }
String? _extractGigNum(String line) {
  final pattern = RegExp(r'(TEG?\D*?)(\d+)(?=\s*port)', caseSensitive: false);
  final match = pattern.firstMatch(line);

  if (match != null) {
    final prefix = match.group(1)!.toUpperCase().contains('TEG') ? 'TEG' : 'TE';
    final number = match.group(2)!;
    return '$prefix$number';
  }

  return null; // لا يوجد TE..port => حذف السطر
}
void copyTableToClipboard(List<TableRow> rows, String title) {
  final buffer = StringBuffer();
  for (final row in rows) { // نتخطى العنوان
    for (final cell in row.children!) {
      if (cell is Padding && cell.child is SelectableText) {
        final text = (cell.child as SelectableText).data ?? '';
        buffer.write('$text\t');
      }
    }
    buffer.writeln();
  }

  Clipboard.setData(ClipboardData(text: buffer.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("تم نسخ جدول $title")),
  );
}
void copyTableWithoutDate(List<TableRow> rows, String title) {
  final buffer = StringBuffer();
  for (final row in rows) {
    final cells = row.children!;
    // تخطى إذا كان صف العنوان
    if (cells[0] is Padding && (cells[0] as Padding).child is Text && (cells[0] as Padding).child is! SelectableText) {
      continue;
    }

    for (int i = 0; i < cells.length - 1; i++) { // نتوقف قبل عمود التاريخ
      final cell = cells[i];
      if (cell is Padding && cell.child is SelectableText) {
        final text = (cell.child as SelectableText).data ?? '';
        buffer.write('$text\t');
      }
    }
    buffer.writeln();
  }

  Clipboard.setData(ClipboardData(text: buffer.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("تم نسخ جدول $title بدون التاريخ")),
  );
}
String removePortSuffix(String text) {
  final pattern = RegExp(r'[-_]port', caseSensitive: false);
  final match = pattern.firstMatch(text);
  if (match == null) return text;
  return text.substring(0, match.start).trim();
}

  Future pickImages() async {
    final upload = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;
    upload.click();
    upload.onChange.listen((event) async {
      final files = upload.files;
      if (files == null || files.isEmpty) return;

      setState(() {
        isLoading = true;
        // images.clear();
        // extractedTexts.clear();
      });

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoadEnd.first;
        final imageUrl = reader.result as String;

        images.add(imageUrl);
        extractedTexts.add("جاري التحليل...");
        final index = images.length - 1;

        processImage(imageUrl, index);
      }

      setState(() => isLoading = false);
    });
  }

  Future<void> processImage(String imageUrl, int index) async {
    final image = html.ImageElement(src: imageUrl);
    await image.onLoad.first;

    // إنشاء canvas لزيادة دقة الصورة
    final canvas = html.CanvasElement(width: image.width, height: image.height);
    final ctx = canvas.context2D;
    
    // تكبير الصورة للحصول على دقة أعلى
    final scale = 2;  // يمكنك تعديل هذه القيمة
    canvas.width = image.width! * scale;
    canvas.height = image.height! * scale;
    ctx.scale(scale.toDouble(), scale.toDouble());
    ctx.drawImage(image, 0, 0);

    // تحويل الصورة إلى تدرج رمادي (Grayscale)
    final imageData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);
    for (int i = 0; i < imageData.data.length; i += 4) {
      int r = imageData.data[i];
      int g = imageData.data[i + 1];
      int b = imageData.data[i + 2];
      int gray = (0.299 * r + 0.587 * g + 0.114 * b).round();

      imageData.data[i] = gray;  // قناة الأحمر
      imageData.data[i + 1] = gray;  // قناة الأخضر
      imageData.data[i + 2] = gray;  // قناة الأزرق
    }
    ctx.putImageData(imageData, 0, 0);

    // زيادة التباين (Contrast Enhancement)
    final factor = 1.5; // يمكنك تعديل هذه القيمة للحصول على أفضل نتيجة
    for (int i = 0; i < imageData.data.length; i += 4) {
      int gray = imageData.data[i];
      gray = enhanceContrast(gray, factor);
      imageData.data[i] = gray;
      imageData.data[i + 1] = gray;
      imageData.data[i + 2] = gray;
    }
    ctx.putImageData(imageData, 0, 0);

    // إزالة التشويش (Optional) باستخدام thresholding
    final threshold = 150;
    for (int i = 0; i < imageData.data.length; i += 4) {
      int gray = imageData.data[i];
      int value = gray > threshold ? 255 : 0;
      imageData.data[i] = value;
      imageData.data[i + 1] = value;
      imageData.data[i + 2] = value;
    }
    ctx.putImageData(imageData, 0, 0);

    // الآن يمكننا استخراج النصوص بعد كل التحسينات
    final grayImageUrl = canvas.toDataUrl();
    final text = await extractText(grayImageUrl);

    setState(() {
      extractedTexts[index] = text.trim().isEmpty ? "[لم يتم استخراج نص]" : text.trim();
    });
  }

  // دالة لتحسين التباين (Contrast Enhancement)
  int enhanceContrast(int gray, double factor) {
    return (128 + (gray - 128) * factor).clamp(0, 255).toInt();
  }

  Future<String> extractText(String imageUrl) async {
    final jsPromise = tesseract.recognize(
      imageUrl,
      'eng',
      jsify({'preserve_interword_spaces': '1', 'tessedit_pageseg_mode': 3}),
    );
    final result = await promiseToFuture(jsPromise);
    final data = getProperty(result, 'data');
    final rawText = getProperty(data, 'text').toString();
    return rawText;
  }
  String extractDateAfterSuffix(String line, List<String> suffixes) {
  final lower = line.toLowerCase();
  for (var suffix in suffixes) {
    final suffixIndex = lower.indexOf(suffix);
    if (suffixIndex != -1) {
      final afterSuffix = line.substring(suffixIndex + suffix.length);
      final equIndex = afterSuffix.toLowerCase().indexOf('equ');
      if (equIndex != -1) {
        return afterSuffix.substring(0, equIndex).trim();
      }
    }
  }
  return '...';
}

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
      extractedTexts.removeAt(index);
    });
  }

  void clearAll() {
    setState(() {
    
      images.clear();
      extractedTexts.clear();
    });
  }
 List<TableRow> _buildTableRowsBySuffix(List<String> suffixes) {
  final List<TableRow> rows = [];
  final Set<String> seenGigNums = {}; // لتخزين قيم Gig المكررة

  for (final text in extractedTexts) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lowerLine = line.trim().toLowerCase();
      if (suffixes.any((suffix) => lowerLine.contains(suffix))) {
        final aggregator = _extractAggregator(line);
        if (aggregator == 'none') continue;

      //   final gig = _extractGigNum(line);
      //  // if (gig.toString().contains('te')!= true) continue;////////////////////
      //   if (seenGigNums.contains(gig)) continue; // ✅ تخطي السطر إذا كان مكررًا
      //   seenGigNums.add(gig);
final gig = _extractGigNum(line);
if (gig == null) continue; // ✨ حذف الصف لو gig غير صالح
if (seenGigNums.contains(gig)) continue;
seenGigNums.add(gig);
       final core = _extractCore(line);
String finalAgg = removePortSuffix(aggregator);
String finalCore = removePortSuffix(core);

// إذا كان يحتوي aggregator على "pe" → نقلب القيم
final aggLower = aggregator.toLowerCase();

if (aggLower.contains('pe')) {
  finalAgg = core;
  finalCore = aggregator;
} else if (aggLower.contains('obr') || aggLower.contains('oct')) {
  finalAgg = core;
  finalCore = aggregator;
}

rows.add(
  TableRow(
   children: [
  Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(finalCore)),
  Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(finalAgg)),
  Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(gig)),
  Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(
    suffixes.firstWhere((suffix) => lowerLine.endsWith(suffix), orElse: () => ''),
  )),
  Padding(padding: const EdgeInsets.all(8.0), child: SelectableText(
    extractDateAfterSuffix(line, suffixes),
  )),
],
  ),
);
      }
    }
  }

  return rows;
}

String _extractAggregator(String line) {
  final lowerLine = line.toLowerCase();
  final index = lowerLine.indexOf('physical');

  if (index != -1) {
    return line.substring(0, index).trim();
  }

  // Fallback: ابحث عن 4 حروف متصلة من كلمة physical
  const keyword = 'physical';
  for (int i = 0; i < line.length - 3; i++) {
    final sub = line.substring(i, i + 4).toLowerCase();
    int matchCount = 0;
    for (var ch in sub.split('')) {
      if (keyword.contains(ch)) matchCount++;
    }
    if (matchCount >= 4) {
      return line.substring(0, i).trim();
    }
  }

  return 'none';
}

 bool showTable = false; // أضف هذا المتغير داخل _DownVsFlapState

@override
Widget build(BuildContext context) {
  super.build(context);
  return Scaffold(
    appBar: AppBar(title: const Text("تحليل الصورة إلى نصوص")),
    body: 
    SingleChildScrollView(
      child:
    Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: pickImages,
                child: const Text("اختيار صور"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: clearAll,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف الكل"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading) const CircularProgressIndicator(),
          const SizedBox(height: 10),
         if (images.isNotEmpty)
  ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: images.length,
    itemBuilder: (context, index) {
      return Card(
       
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Image.network(images[index]),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => removeImage(index),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SelectableText(
                            extractedTexts[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                showTable = true;
              });
            },
            child: const Text("إظهار الجدول"),
          ),
          if (showTable)
  Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    //    const Text("الجدول - Major", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      
      Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text("الجدول - Major", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
 Row(
  children: [
    ElevatedButton(
      onPressed: () {
        final rows = _buildTableRowsBySuffix(['major', 'ajor', 'jor','or']);
        copyTableToClipboard(rows, 'Major');
      },
      child: const Text("نسخ"),
    ),
    const SizedBox(width: 8),
    ElevatedButton(
      onPressed: () {
        final rows = _buildTableRowsBySuffix(['major', 'ajor', 'jor','or']);
        copyTableWithoutDate(rows, 'Major');
      },
      child: const Text("نسخ بدون التاريخ"),
    ),
  ],
),
  ],
),
      
      
        Table(
          border: TableBorder.all(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.grey),
              children: [
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Core')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Aggregator')),
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Gig num')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Major')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Date')),
              ],
            ),
            ..._buildTableRowsBySuffix(['major', 'ajor', 'jor','or'])
          ],
        ),
        const SizedBox(height: 20),
     //   const Text("الجدول - Cleared", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
       Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text("الجدول - Cleared", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
   Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text("الجدول - Cleared", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Row(
      children: [
        ElevatedButton(
          onPressed: () {
            final rows = _buildTableRowsBySuffix(['cleared', 'leared', 'eared','ared','red']);
            copyTableToClipboard(rows, 'Cleared');
          },
          child: const Text("نسخ"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final rows = _buildTableRowsBySuffix(['cleared', 'leared', 'eared','ared','red']);
            copyTableWithoutDate(rows, 'Cleared');
          },
          child: const Text("نسخ بدون التاريخ"),
        ),
      ],
    ),
  ],
),
  ],
),
       
        Table(
          border: TableBorder.all(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.grey),
              children: [
                                Padding(padding: EdgeInsets.all(8.0), child: Text('Core')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Aggregator')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Gig num')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Clear')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Date')),
              ],
            ),
            ..._buildTableRowsBySuffix(['cleared', 'leared', 'eared','ared','red'])
          ],
        ),
      ],
    ),
  ),
        ],
      ),
    ),
  ));
}
}

