import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:honeywell_scanner/honeywell_scanner.dart';

class MalzemeBul extends StatefulWidget {
  const MalzemeBul({super.key});

  @override
  _MalzemeBulState createState() => _MalzemeBulState();
}

class _MalzemeBulState extends State<MalzemeBul> {
  Map<String, dynamic>? materialDetails;
  HoneywellScanner honeywellScanner = HoneywellScanner();
  String? scannedBarcode;
  TextEditingController barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Honeywell tarayıcıyı başlat ve dinleyicileri ayarla
    honeywellScanner.startScanner();
    honeywellScanner.onScannerDecodeCallback = (scannedData) {
      setState(() {
        scannedBarcode = scannedData?.code;
        barcodeController.text = scannedBarcode!;
      });
      fetchMaterialDetails(scannedBarcode!);
    };

    honeywellScanner.onScannerErrorCallback = (error) {
      print('Tarayıcı hatası: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarayıcı hatası oluştu.')),
      );
    };
  }

  @override
  void dispose() {
    honeywellScanner.stopScanner();
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> fetchMaterialDetails(String barkodNo) async {
    final response = await http.get(
        Uri.parse('http://10.10.208.118:8083/api/materials/details/$barkodNo'));

    if (response.statusCode == 200) {
      setState(() {
        materialDetails = json.decode(response.body);
      });
    } else {
      setState(() {
        materialDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Envanter Takip - Malzeme Bul",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Tam ekranı kaplaması için
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF4A4A), // Parlak kırmızı
              Color(0xFF8B0000), // Koyu kırmızı
            ],
            stops: [0.0, 1.0], // Renk geçişlerini ayarlama
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              TextField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: "RFID veya SN Numarası Girebilirsiniz",
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.white), // Değiştirilen ikon
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(16.0), // Modern köşeler
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(16.0), // Modern köşeler
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    fetchMaterialDetails(barcodeController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 255, 255, 255), // Buton arka plan rengi
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15), // Buton boyutu
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16.0), // Modern köşeler
                    ),
                    elevation: 20, // Daha fazla gölge için yüksek değer
                    shadowColor: const Color.fromARGB(255, 0, 0, 0)
                        .withOpacity(0.7), // Gölgenin rengi ve opaklığı
                  ),
                  child: const Text(
                    'MALZEME BUL',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color.fromARGB(255, 0, 0, 0), // Siyah yazı rengi
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildInventoryInfoRow(
                  "LOKASYON:",
                  materialDetails != null
                      ? materialDetails!['room']['subLocation']['name']
                      : "-"),
              buildInventoryInfoRow(
                  "ODA:",
                  materialDetails != null
                      ? materialDetails!['room']['odaNum']
                      : "-"),
              buildInventoryInfoRow("MARKA:",
                  materialDetails != null ? materialDetails!['marka'] : "-"),
              buildInventoryInfoRow("MODEL:",
                  materialDetails != null ? materialDetails!['model'] : "-"),
              buildInventoryInfoRow("RFID NUMARASI:", scannedBarcode ?? "-"),
              if (materialDetails == null && scannedBarcode != null)
                const Text('Veri bulunamadı',
                    style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInventoryInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(16.0), // Modern köşeler
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
