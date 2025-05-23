import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ads.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  bool isScanning = false;
  bool _isDialogOpen = false;
  final MobileScannerController controller = MobileScannerController();
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _createBanner();
  }

  void handleData(String data) async {
    if (_isDialogOpen) return;

    if (data.startsWith('http') ||
        data.startsWith('mailto:') ||
        data.startsWith('tel:')) {
      await launchUrl(Uri.parse(data));
    } else {
      _isDialogOpen = true;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Scan Result"),
          content: Text(data),
          actions: [
            TextButton(
              onPressed: () {
                _isDialogOpen = false;
                Navigator.pop(context);
              },
              child: const Text("Dismiss"),
            ),
          ],
        ),
      );
    }

    setState(() {
      isScanning = false;
    });
    controller.stop();
  }

  void startScanning() {
    setState(() {
      isScanning = true;
    });
    controller.start();
  }

  void _createBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId1!,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('-----BannerAd failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }


  @override
  void dispose() {
    controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.document_scanner_rounded, size: screenWidth * 0.08),
              SizedBox(width: screenWidth * 0.02),
              Text(
                "QR Scanner",
                style: TextStyle(
                  fontFamily: "f1",
                  fontSize: screenWidth * 0.054,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blueGrey.shade800,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: isScanning
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Align the QR/Barcode inside the frame",
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            Container(
              width: screenWidth * 0.8,
              height: screenWidth * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent, width: 4), // 🔴 Colored border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        final barcode = capture.barcodes.first;
                        if (barcode.rawValue != null) {
                          handleData(barcode.rawValue!);
                        }
                      },
                    ),
                    const _ScanLine(),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.05),
            Container(
              height: screenHeight * 0.08,
              width: screenWidth * 0.65,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isScanning = false;
                  });
                  controller.stop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1, vertical: 12),
                ),
                icon: Icon(Icons.cancel, size: screenWidth * 0.08, color: Colors.white),
                label: Text(
                  "Cancel Scan",
                  style: TextStyle(color: Colors.white, fontFamily: "f1", fontSize: screenWidth * 0.045),
                ),
              ),
            )
          ],
        )
            : Container(
          height: screenHeight * 0.075,
          width: screenWidth * 0.6,
          child: ElevatedButton.icon(
            onPressed: startScanning,
            icon: const Icon(Icons.qr_code_scanner, size: 30),
            label: Text(
              "Start Scan",
              style: TextStyle(fontSize: screenWidth * 0.048, fontFamily: "f1"),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 14),
              textStyle: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
          ),
        ),
      ),
      bottomNavigationBar: _isBannerAdReady
          ? Container(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox(height: 50),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Positioned(
          top: 300 * _animation.value - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.redAccent.withOpacity(0.8),
          ),
        );
      },
    );
  }
}
