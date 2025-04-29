import 'dart:io';
import 'dart:ui' as ui;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:united_code_scanner_generator/ads.dart';
import 'package:pdf/widgets.dart' as pw;

class Generator extends StatefulWidget {
  @override
  _GeneratorState createState() => _GeneratorState();
}

class _GeneratorState extends State<Generator> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _createReward();
    _createBanner();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.storage,
      Permission.photos,
    ].request();
  }

  String code = '';
  String codeType = 'QR';
  GlobalKey qrKey = GlobalKey();

  final Map<String, int> _code39CharValues = {
    '0': 0,
    '1': 1,
    '2': 2,
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9,
    'A': 10,
    'B': 11,
    'C': 12,
    'D': 13,
    'E': 14,
    'F': 15,
    'G': 16,
    'H': 17,
    'I': 18,
    'J': 19,
    'K': 20,
    'L': 21,
    'M': 22,
    'N': 23,
    'O': 24,
    'P': 25,
    'Q': 26,
    'R': 27,
    'S': 28,
    'T': 29,
    'U': 30,
    'V': 31,
    'W': 32,
    'X': 33,
    'Y': 34,
    'Z': 35,
    '-': 36,
    '.': 37,
    ' ': 38,
    '\$': 39,
    '/': 40,
    '+': 41,
    '%': 42
  };
  final List<String> _code93Charset = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '-',
    '.',
    ' ',
    '\$',
    '/',
    '+',
    '%'
  ];

  RewardedAd? rewardedAd;
  int score = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  void _createReward() {
    RewardedAd.load(
        adUnitId: AdMobService.rewardedAdUnitId!,
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            setState(() {
              print("Rewarded ad loaded");
              rewardedAd = ad;
            });
          },
          onAdFailedToLoad: (error) {
            setState(() {
              print(
                  "----------------------------------------Failed to load rewarded ad: $error");
              rewardedAd = null;
            });
          },
        ));
  }

  void _createBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId!,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('-----------------------------------------------------------------------------BannerAd failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showReward() {
    if (rewardedAd != null) {
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createReward();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print(
              "-------------------------------------------------------------------------Failed to load rewarded ad: $error");
          ad.dispose();
          _createReward();
        },
      );
      rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          score++;
        },
      );
    }
  }


  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }
    }
  }

  Future<void> _saveQRCode() async  {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      final appFolder = Directory("${downloadsDirectory!.path}/MyQRcodes");
      if (!(await appFolder.exists())) {
        await appFolder.create(recursive: true);
      }

      final fileName = "QRCode_${DateTime.now().millisecondsSinceEpoch}.png";
      final filePath = "${appFolder.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (Platform.isAndroid) {
        final result = await File(filePath).exists();
        if (result) {
          await _refreshGallery(filePath);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        content: Text(
          "✅ QR Code Saved",
          style: TextStyle(color: Colors.green),
        ),
      ));

      print("Saved at: $filePath");

    } catch (e) {
      print("Error saving QR code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR code')),
      );
    }
  }

  Future<void> _saveBarcodeAsPDF(Uint8List barcodeImageBytes) async {
    try {
      await requestStoragePermission();

      final pdf = pw.Document();
      final outputDirectory = await getExternalStorageDirectory();

      final downloadsDirectory = Directory('/storage/emulated/0/Download');

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final filePath = '${downloadsDirectory.path}/barcode_${DateTime.now().millisecondsSinceEpoch}.pdf';

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(barcodeImageBytes),
              ),
            );
          },
        ),
      );

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode saved as PDF!')),
      );

      print("PDF saved to: $filePath");
    } catch (e) {
      print("Error saving PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save barcode as PDF')),
      );
    }
  }

  Future<void> _refreshGallery(String filePath) async {
    const MethodChannel _channel = MethodChannel('com.example.app/media_scanner');
    try {
      await _channel.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      print("Failed to refresh gallery: $e");
    }
  }

  Widget build(BuildContext context) {
    final bool isUPCA = codeType == 'UPCA';
    final bool isEAN13 = codeType == 'EAN13';

    final bool isUPCAValid =
        code.length == 12 && RegExp(r'^\d+$').hasMatch(code);
    final bool isEAN13Valid =
        code.length == 12 && RegExp(r'^\d+$').hasMatch(code);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    print("Widthhhhhh = $screenWidth");
    print("Heighttttt = $screenHeight");

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Exit"),
                content: Text("Are you sure you want to exit?"),
                actions: [
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text("OK"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  )
                ],
              ),
            );
          },
          icon: Icon(Icons.exit_to_app, color: Colors.white, size: 30),
        ),
        title: Text(
          "United Barcode Generator",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "f1",
            fontSize: screenWidth * 0.054,
          ),
        ),
        centerTitle: true,
        elevation: 6,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Enter Text or Link",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "f1",
                                  color: Colors.blueGrey.shade900,
                                )),
                            SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                hintText: "Your code input...",
                                hintStyle: TextStyle(fontFamily: "f1"),
                                filled: true,
                                fillColor: Colors.blueGrey.shade50,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: (isUPCA || isEAN13)
                                  ? TextInputType.number
                                  : TextInputType.text,
                              inputFormatters: (isUPCA || isEAN13)
                                  ? [FilteringTextInputFormatter.digitsOnly]
                                  : [],
                              onChanged: (val) => setState(() => code = val),
                            ),
                            SizedBox(height: 24),
                            Text("Select Code Type",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "f1",
                                  color: Colors.blueGrey.shade900,
                                )),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: codeType,
                                  isExpanded: true,
                                  style: TextStyle(
                                      fontFamily: "f1", color: Colors.black),
                                  onChanged: (val) => setState(() {
                                    codeType = val!;
                                    code = '';
                                  }),
                                  items: [
                                    'QR',
                                    'URL QR',
                                    'Audio QR',
                                    'CODE 39',
                                    'CODE 93',
                                    'CODE 128',
                                    'DataMatrix',
                                    'EAN13',
                                    'PDF417',
                                    'Aztec',
                                    'UPCA',
                                    'UPCE',
                                    'TelePen',
                                    'MaxiCode'
                                  ]
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e,
                                            child: Text(e,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                            if (isUPCA)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  '⚠️ UPCA requires exactly 12 numeric digits.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontFamily: "f1",
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (isEAN13)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  '⚠️ EAN13 requires exactly 12 numeric digits. The 13th (checksum) is calculated automatically.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontFamily: "f1",
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    if (code.isNotEmpty)
                      if ((isUPCA && !isUPCAValid) ||
                          (isEAN13 && !isEAN13Valid))
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '❗ Enter exactly 12 digits to generate a valid ${isUPCA ? 'UPCA' : 'EAN13'} code.',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontFamily: "f1",
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 12,
                                shadowColor: Colors.black45,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: RepaintBoundary(
                                    key:
                                        codeType.contains("QR") ? qrKey : qrKey,
                                    child: codeType.contains("QR")
                                        ? CustomPaint(
                                            size: Size(200, 200),
                                            painter: QrPainter(
                                              data: code,
                                              version: QrVersions.auto,
                                              errorCorrectionLevel:
                                                  QrErrorCorrectLevel.H,
                                              gapless: true,
                                              color: Colors.black,
                                              emptyColor: Colors.white,
                                            ),
                                          )
                                        : _buildCodeWidget(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: code.isNotEmpty
                                    ? () async {
                                        _showReward();
                                        _saveQRCode();
                                      }
                                    : null,
                                icon: Icon(Icons.save_alt_outlined),
                                label: Text("Download"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade800,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          _isBannerAdReady
              ? Container(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  alignment: Alignment.center,
                  child: AdWidget(
                    ad: _bannerAd!,
                  ),
                )
              : SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      "",
                      style: TextStyle(fontFamily: "f1", color: Colors.grey),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Widget _buildCodeWidget() {
    switch (codeType) {
      case 'QR':
      case 'URL QR':
      case 'Audio QR':
        return QrImageView(data: code, size: 200);

      case 'CODE 39':
        final valid =
            RegExp(r'^[0-9A-Z\-\.\ \$\/\+\%]+$').hasMatch(code.toUpperCase());
        if (!valid) {
          return Text(
            "Only CODE 39 supported characters allowed (0-9, A-Z, - . space \$ / + %).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        final fullCode = getCode39WithChecksum(code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Final CODE 39 with checksum: $fullCode",
              style: TextStyle(fontFamily: "f1"),
            ),
            SizedBox(height: 10),
            BarcodeWidget(
              barcode: Barcode.code39(),
              data: fullCode,
              width: 200,
              height: 100,
            ),
          ],
        );

      case 'CODE 93':
        final valid = code.isNotEmpty &&
            code
                .toUpperCase()
                .split('')
                .every((c) => _code93Charset.contains(c));
        if (!valid) {
          return Text(
            "Only CODE 93 supported characters allowed (0-9, A-Z, - . space \$ / + %).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        final fullCode = getCode93WithChecksum(code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Final CODE 93 with checksum: $fullCode",
              style: TextStyle(fontFamily: "f1"),
            ),
            SizedBox(height: 10),
            BarcodeWidget(
              barcode: Barcode.code93(),
              data: fullCode,
              width: 200,
              height: 100,
            ),
          ],
        );

      case 'CODE 128':
        final codeWithChecksum = getCode128WithChecksum(code);
        if (codeWithChecksum.isEmpty) {
          return Text(
            "Invalid characters for CODE 128 B. Only ASCII 32–127 allowed.",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calculated checksum (not shown in barcode): ${codeWithChecksum.split('␟').last}",
              style: TextStyle(fontFamily: "f1"),
            ),
            SizedBox(height: 10),
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: code, // Don't append checksum, library does it
              width: 200,
              height: 100,
            ),
          ],
        );

      case 'PDF417':
        final isValid = code.runes.every((r) => r >= 32 && r <= 126);
        if (!isValid) {
          return Text(
            "PDF417 supports only ASCII characters (32–126).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return BarcodeWidget(
          barcode: Barcode.pdf417(),
          data: code,
          width: 250,
          height: 100,
        );

      case 'Aztec':
        final isValid = code.runes.every((r) => r >= 32 && r <= 126);
        if (!isValid) {
          return Text(
            "Aztec code supports only ASCII characters (32–126).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return BarcodeWidget(
          barcode: Barcode.aztec(),
          data: code,
          width: 200,
          height: 200,
        );

      case 'DataMatrix':
        final isValid = code.runes.every((r) => r >= 32 && r <= 126);
        if (!isValid) {
          return Text(
            "DataMatrix supports only ASCII characters (32–126).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return BarcodeWidget(
          barcode: Barcode.dataMatrix(),
          data: code,
          width: 200,
          height: 200,
        );

      case 'TelePen':
        final isValid = code.runes.every((r) => r >= 32 && r <= 126);
        if (!isValid) {
          return Text(
            "TelePen supports only ASCII characters (32–126).",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return BarcodeWidget(
          barcode: Barcode.telepen(),
          data: code,
          width: 200,
          height: 200,
        );

      case 'UPCE':
        if (!RegExp(r'^\d{6,8}$').hasMatch(code)) {
          return Text(
            "UPC-E requires 6 to 8 numeric digits depending on format.",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        return BarcodeWidget(
          barcode: Barcode.upcE(),
          data: code,
          width: 200,
          height: 200,
        );

      case 'UPCA':
        if (code.length != 11 || !RegExp(r'^\d{11}$').hasMatch(code)) {
          return Text(
            "Enter exactly 11 digits. The 12th (checksum) will be calculated automatically.",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        final fullCode = getUPCACode(code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Final UPCA Code: $fullCode",
              style: TextStyle(fontFamily: "f1"),
            ),
            SizedBox(height: 10),
            BarcodeWidget(
              barcode: Barcode.upcA(),
              data: fullCode,
              width: 200,
              height: 100,
            ),
          ],
        );

      case 'EAN13':
        if (code.length != 12 || !RegExp(r'^\d{12}$').hasMatch(code)) {
          return Text(
            "Enter exactly 12 digits. The 13th (checksum) will be calculated automatically.",
            style: TextStyle(color: Colors.red, fontFamily: "f1"),
          );
        }
        final fullCode = getEAN13Code(code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Final EAN13 Code: $fullCode",
              style: TextStyle(fontFamily: "f1"),
            ),
            SizedBox(height: 10),
            BarcodeWidget(
              barcode: Barcode.ean13(),
              data: fullCode,
              width: 200,
              height: 100,
            ),
          ],
        );

      case 'MaxiCode':
        return Text(
          "MaxiCode is currently not supported.",
          style: TextStyle(fontFamily: "f1"),
        );
      default:
        return SizedBox();
    }
  }

  String getUPCACode(String data) {
    if (data.length != 11 || !RegExp(r'^\d{11}$').hasMatch(data)) return '';

    int sumOdd = 0;
    int sumEven = 0;

    for (int i = 0; i < 11; i++) {
      int digit = int.parse(data[i]);
      if (i % 2 == 0) {
        sumOdd += digit;
      } else {
        sumEven += digit;
      }
    }

    int total = (sumOdd * 3) + sumEven;
    int checksum = (10 - (total % 10)) % 10;

    return data + checksum.toString();
  }

  String getEAN13Code(String data) {
    if (data.length != 12 || !RegExp(r'^\d{12}$').hasMatch(data)) return '';

    int sumOdd = 0;
    int sumEven = 0;

    for (int i = 0; i < 12; i++) {
      int digit = int.parse(data[i]);
      if (i % 2 == 0) {
        sumOdd += digit;
      } else {
        sumEven += digit;
      }
    }

    int total = sumOdd + (sumEven * 3);
    int checksum = (10 - (total % 10)) % 10;

    return data + checksum.toString();
  }

  String getCode39WithChecksum(String data) {
    String upperData = data.toUpperCase();
    int sum = 0;

    for (int i = 0; i < upperData.length; i++) {
      String char = upperData[i];
      if (!_code39CharValues.containsKey(char)) return '';
      sum += _code39CharValues[char]!;
    }

    int checksumIndex = sum % 43;
    String checksumChar = _code39CharValues.entries
        .firstWhere((entry) => entry.value == checksumIndex)
        .key;

    return upperData + checksumChar;
  }

  String getCode93WithChecksum(String data) {
    String upper = data.toUpperCase();
    List<int> values = [];

    for (int i = 0; i < upper.length; i++) {
      int index = _code93Charset.indexOf(upper[i]);
      if (index == -1) return ''; // Invalid character
      values.add(index);
    }

    int calcWeightedSum(List<int> values, int maxWeight) {
      int weight = 1;
      int sum = 0;
      for (int i = values.length - 1; i >= 0; i--) {
        sum += values[i] * weight;
        weight = weight == maxWeight ? 1 : weight + 1;
      }
      return sum % 47;
    }

    int c = calcWeightedSum(values, 20);
    values.add(c);
    int k = calcWeightedSum(values, 15);

    String cChar = _code93Charset[c];
    String kChar = _code93Charset[k];

    return upper + cChar + kChar;
  }

  String getCode128WithChecksum(String data) {
    if (data.isEmpty) return '';

    const int startCodeB = 104;
    int checksum = startCodeB;

    for (int i = 0; i < data.length; i++) {
      int charValue = data.codeUnitAt(i) - 32;
      if (charValue < 0 || charValue > 95) {
        return '';
      }
      checksum += charValue * (i + 1);
    }

    int checksumValue = checksum % 103;
    return '$data␟$checksumValue';
  }
}
