// image_text_extractor_dual.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:string_similarity/string_similarity.dart';

@JS('Tesseract')
external TesseractJS get tesseract;

@JS()
@anonymous
class TesseractJS {
  external dynamic recognize(String image, String lang, dynamic options);
}

class ImageTextExtractor extends StatefulWidget {
  const ImageTextExtractor({super.key});

  @override
  State<ImageTextExtractor> createState() => _DualImageTextExtractorState();
}

class _DualImageTextExtractorState extends State<ImageTextExtractor> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
bool showComparison = false;
List<String> unique1 = [];
List<String> unique2 = [];
List<String> matched = [];
  // الطرف الأول
  List<String> images1 = [];
  List<String> texts1 = [];
  bool isLoading1 = false;

  // الطرف الثاني
  List<String> images2 = [];
  List<String> texts2 = [];
  bool isLoading2 = false;
void compareTexts() {
  final lines1 = texts1.expand((t) => t.split('\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final lines2 = texts2.expand((t) => t.split('\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  final matchedLines = <String>[];
  final unmatched1 = <String>[];
  final usedIndices2 = <int>{};

  for (final line1 in lines1) {
    double bestScore = 0;
    int bestIndex = -1;

    for (int i = 0; i < lines2.length; i++) {
      if (usedIndices2.contains(i)) continue;
      double score = line1.similarityTo(lines2[i]);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    if (bestScore >= 0.8 && bestIndex != -1) {
      matchedLines.add(line1); // يمكنك حفظ الاثنين لو أردت لاحقًا
      usedIndices2.add(bestIndex);
    } else {
      unmatched1.add(line1);
    }
  }

  final unmatched2 = <String>[];
  for (int i = 0; i < lines2.length; i++) {
    if (!usedIndices2.contains(i)) {
      unmatched2.add(lines2[i]);
    }
  }

  setState(() {
    matched = matchedLines;
    unique1 = unmatched1;
    unique2 = unmatched2;
    showComparison = true;
  });
}

  Future<void> pickImages(bool isFirstSide) async {
    final upload = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;
    upload.click();
    upload.onChange.listen((event) async {
      final files = upload.files;
      if (files == null || files.isEmpty) return;

      setState(() {
        if (isFirstSide) {
          isLoading1 = true;
        } else {
          isLoading2 = true;
        }
      });

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoadEnd.first;
        final imageUrl = reader.result as String;

        if (isFirstSide) {
          images1.add(imageUrl);
          texts1.add("جاري التحليل...");
          await processImage(imageUrl, texts1, images1.length - 1);
        } else {
          images2.add(imageUrl);
          texts2.add("جاري التحليل...");
          await processImage(imageUrl, texts2, images2.length - 1);
        }
      }

      setState(() {
        isFirstSide ? isLoading1 = false : isLoading2 = false;
      });
    });
  }

  Future<void> processImage(String imageUrl, List<String> texts, int index) async {
    final image = html.ImageElement(src: imageUrl);
    await image.onLoad.first;

    final canvas = html.CanvasElement(width: image.width, height: image.height);
    final ctx = canvas.context2D;

    const scale = 3;
    canvas.width = image.width! * scale;
    canvas.height = image.height! * scale;
    ctx.scale(scale.toDouble(), scale.toDouble());
    ctx.drawImage(image, 0, 0);

    final imageData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);
    for (int i = 0; i < imageData.data.length; i += 4) {
      int r = imageData.data[i];
      int g = imageData.data[i + 1];
      int b = imageData.data[i + 2];
      int gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
      imageData.data[i] = gray;
      imageData.data[i + 1] = gray;
      imageData.data[i + 2] = gray;
    }

    // Threshold
    const threshold = 150;
    for (int i = 0; i < imageData.data.length; i += 4) {
      int gray = imageData.data[i];
      int value = gray > threshold ? 255 : 0;
      imageData.data[i] = value;
      imageData.data[i + 1] = value;
      imageData.data[i + 2] = value;
    }
    ctx.putImageData(imageData, 0, 0);

    final processedUrl = canvas.toDataUrl();
    final text = await extractText(processedUrl);

    setState(() {
      texts[index] = text.trim().isEmpty ? "[لم يتم استخراج نص]" : text.trim();
    });
  }

  Future<String> extractText(String imageUrl) async {
    final jsPromise = tesseract.recognize(
      imageUrl,
      'eng',
      jsify({
        'preserve_interword_spaces': '1',
        'tessedit_pageseg_mode': 3,
      }),
    );
    final result = await promiseToFuture(jsPromise);
    final data = getProperty(result, 'data');
    return getProperty(data, 'text').toString();
  }

  void removeImage(int index, bool isFirstSide) {
    setState(() {
      if (isFirstSide) {
        images1.removeAt(index);
        texts1.removeAt(index);
      } else {
        images2.removeAt(index);
        texts2.removeAt(index);
      }
    });
  }

  void clearAll(bool isFirstSide) {
    setState(() {
      if (isFirstSide) {
        images1.clear();
        texts1.clear();
      } else {
        images2.clear();
        texts2.clear();
      }
    });
  }
void copyTableToClipboard(List<String> col1, List<String> col2, List<String> col3) {
  final rowCount = [col1.length, col2.length, col3.length].reduce((a, b) => a > b ? a : b);
  final buffer = StringBuffer();

  buffer.writeln("الطرف الأول\tالمتطابق\tالطرف الثاني");

  for (int i = 0; i < rowCount; i++) {
    final row = [
      i < col1.length ? col1[i] : '',
      i < col2.length ? col2[i] : '',
      i < col3.length ? col3[i] : '',
    ];
    buffer.writeln(row.join('\t'));
  }

  Clipboard.setData(ClipboardData(text: buffer.toString()));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('📋 تم نسخ الجدول إلى الحافظة')),
  );
}
  Widget sideWidget({
    required String title,
    required List<String> images,
    required List<String> texts,
    required bool isLoading,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required bool isFirstSide,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: onPick, child: const Text("اختيار صور")),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف الكل"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading) const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
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
                              onPressed: () => removeImage(index, isFirstSide),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(
                          texts[index],
                          style: const TextStyle(fontSize: 14),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text("تحليل نصوص - طرفين")),
      body: Row(
        children: [
          sideWidget(
            title: "الطرف الأول",
            images: images1,
            texts: texts1,
            isLoading: isLoading1,
            onPick: () => pickImages(true),
            onClear: () => clearAll(true),
            isFirstSide: true,
          ),
          const VerticalDivider(width: 8, thickness: 1),
          sideWidget(
            title: "الطرف الثاني",
            images: images2,
            texts: texts2,
            isLoading: isLoading2,
            onPick: () => pickImages(false),
            onClear: () => clearAll(false),
            isFirstSide: false,
          ),
          Expanded(
  child: Column(
    children: [
      ElevatedButton(
        onPressed: compareTexts,
        child: const Text("مقارنة النصوص"),
      ),
      const SizedBox(height: 10),
       if (showComparison)
      ElevatedButton.icon(
  onPressed: () => copyTableToClipboard(unique1, matched, unique2),
  icon: const Icon(Icons.copy),
  label: const Text("نسخ الجدول"),
),
const SizedBox(height: 10),
      if (showComparison)
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('غير متكرر في الطرف الأول', textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('✅ متطابق (≥ 80%)', textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('غير متكرر في الطرف الثاني', textAlign: TextAlign.center),
                    ),
                  ],
                ),
                for (int i = 0; i < [unique1.length, matched.length, unique2.length].reduce((a, b) => a > b ? a : b); i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(i < unique1.length ? unique1[i] : ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(i < matched.length ? matched[i] : ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(i < unique2.length ? unique2[i] : ''),
                      ),
                    ],
                  ),
              ],
            ),
            
          ),
        ),
     if (showComparison)   const SizedBox(height: 30),
        if (showComparison)
const Text(
  "🧹 Remove Duplicate",
  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
),
if (showComparison)const SizedBox(height: 10),
if (showComparison)
 ElevatedButton.icon(
  onPressed: () => copyTableToClipboard(
    unique1.toSet().toList(),
    matched.toSet().toList(),
    unique2.toSet().toList(),
  ),
  icon: const Icon(Icons.copy),
  label: const Text("نسخ الجدول"),
),
const SizedBox(height: 10),
const SizedBox(height: 10),
if (showComparison)
Expanded(
  child: SingleChildScrollView(
    child: Table(
      border: TableBorder.all(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('غير متكرر في الطرف الأول', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('✅ متطابق (بدون تكرار)', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('غير متكرر في الطرف الثاني', textAlign: TextAlign.center),
            ),
          ],
        ),
        for (int i = 0;
            i <
                [
                  unique1.toSet().length,
                  matched.toSet().length,
                  unique2.toSet().length
                ].reduce((a, b) => a > b ? a : b);
            i++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  i < unique1.toSet().length
                      ? unique1.toSet().elementAt(i)
                      : '',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  i < matched.toSet().length
                      ? matched.toSet().elementAt(i)
                      : '',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  i < unique2.toSet().length
                      ? unique2.toSet().elementAt(i)
                      : '',
                ),
              ),
            ],
          ),
      ],
    ),
  ),
),
    ],
  ),
),
        ],
      ),
    );
  }
}