import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Lokasyon.dart';
import 'PersonelSec.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';

class SayimEkrani extends StatefulWidget {
  final String username;
  final String? selectedPersonelAdSoyad;
  final int? selectedPersonelId;
  final String? selectedRoomNum;
  final int? selectedRoomId;

  SayimEkrani({
    required this.username,
    this.selectedPersonelAdSoyad,
    this.selectedPersonelId,
    this.selectedRoomNum,
    this.selectedRoomId,
  });

  @override
  _SayimEkraniState createState() => _SayimEkraniState();
}

class _SayimEkraniState extends State<SayimEkrani> {
  String? selectedRoomNum;
  int? selectedRoomId;
  String? selectedPersonelAdSoyad;
  int? selectedPersonelId;

  int totalEnvanter = 0;
  int bulunanEnvanter = 0;
  int bulunmayanEnvanter = 0;
  int farkliLokasyonEnvanter = 0;

  bool isLocationSelected = false;
  HoneywellScanner honeywellScanner = HoneywellScanner();
  String? scannedBarcode;

  @override
  void initState() {
    super.initState();
    selectedRoomId = widget.selectedRoomId;
    selectedRoomNum = widget.selectedRoomNum;
    selectedPersonelId = widget.selectedPersonelId;
    selectedPersonelAdSoyad = widget.selectedPersonelAdSoyad;
    isLocationSelected = widget.selectedPersonelId == null;
    _fetchEnvanterSayisi();

    honeywellScanner.startScanner();
    honeywellScanner.onScannerDecodeCallback = (scannedData) {
      setState(() {
        scannedBarcode = scannedData?.code;
      });
      _checkBarcode();
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
    super.dispose();
  }

  void _navigateAndSelectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Lokasyon(username: widget.username),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        isLocationSelected = true;
        selectedRoomId = result['roomId'];
        selectedRoomNum = result['roomNum'];
        selectedPersonelAdSoyad = null;
        selectedPersonelId = null;
        _fetchEnvanterSayisi();
      });
    }
  }

  void _navigateAndSelectPersonel(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonelSec(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        isLocationSelected = false;
        selectedPersonelAdSoyad = result['adSoyad'];
        selectedPersonelId = result['perId'];
        selectedRoomNum = result['roomNum'];
        selectedRoomId = result['roomId'];
        _fetchEnvanterSayisi();
      });
    }
  }

  Future<void> _fetchEnvanterSayisi() async {
    if (selectedRoomId == null) return;

    try {
      final totalResponse = await http.get(Uri.parse(
        isLocationSelected
            ? 'http://10.10.208.118:8083/api/materials/total/$selectedRoomId'
            : 'http://10.10.208.118:8083/api/materials/total/${selectedPersonelId!}/$selectedRoomId',
      ));
      final totalData = json.decode(totalResponse.body);

      final foundResponse = await http.get(Uri.parse(
        isLocationSelected
            ? 'http://10.10.208.118:8083/api/materials/found/$selectedRoomId'
            : 'http://10.10.208.118:8083/api/materials/found/${selectedPersonelId!}/$selectedRoomId',
      ));
      final foundData = json.decode(foundResponse.body);

      if (!isLocationSelected) {
        final otherLocationsResponse = await http.get(Uri.parse(
          'http://10.10.208.118:8083/api/materials/other-locations/${selectedPersonelId!}/$selectedRoomId',
        ));
        final otherLocationsData = json.decode(otherLocationsResponse.body);

        setState(() {
          farkliLokasyonEnvanter = otherLocationsData;
        });
      }

      setState(() {
        totalEnvanter = totalData;
        bulunanEnvanter = foundData;
        bulunmayanEnvanter = totalEnvanter - bulunanEnvanter;
      });
    } catch (e) {
      print('Envanter bilgisi alınırken hata oluştu: $e');
    }
  }

  void _checkBarcode() async {
    if (scannedBarcode != null && scannedBarcode!.isNotEmpty) {
      try {
        final url = isLocationSelected
            ? 'http://10.10.208.118:8083/api/materials/update-status?barkodNo=$scannedBarcode&found=true'
            : 'http://10.10.208.118:8083/api/personel/update-material-status';

        final body = {
          'roomId': selectedRoomId.toString(),
          if (!isLocationSelected) 'perId': selectedPersonelId!.toString(),
          'barkodNo': scannedBarcode!,
          'found': 'true',
        };

        final response = await http.post(Uri.parse(url), body: body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barkod başarıyla güncellendi.')),
          );
          _fetchEnvanterSayisi();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barkod farklı bir odaya aittir.')),
          );
        }
      } catch (e) {
        print('Barkod güncellenirken hata oluştu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir barkod numarası girin')),
      );
    }
  }

  void _saveFoundMaterials() async {
    if (!isLocationSelected &&
        selectedPersonelId != null &&
        selectedRoomId != null) {
      try {
        final materialsResponse = await http.get(Uri.parse(
            'http://10.10.208.118:8083/api/personel/materials?perId=$selectedPersonelId'));
        final List<dynamic> materials = jsonDecode(materialsResponse.body);

        if (materials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulunan malzeme yok.')),
          );
          return;
        }

        final List<dynamic> foundMaterials =
            materials.where((m) => m['bulduMu'] == true).toList();

        if (foundMaterials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulunan malzeme yok.')),
          );
          return;
        }

        for (var material in foundMaterials) {
          final matId = material['matId'];
          final sicilNo = material['personel']['sicilNo'];

          final url = 'http://10.10.208.118:8083/api/found-materials/save';

          final body = jsonEncode({
            'material': {
              'matId': matId,
            },
            'room': {
              'id': selectedRoomId,
            },
            'personel': {
              'per_id': selectedPersonelId,
            },
            'sicilNo': sicilNo,
            'foundDate': DateTime.now().toIso8601String(),
          });

          final headers = {"Content-Type": "application/json"};

          final response =
              await http.post(Uri.parse(url), body: body, headers: headers);

          if (response.statusCode == 200) {
            print('Malzeme $matId başarıyla kaydedildi.');
          } else {
            print('Malzeme $matId kaydedilemedi: ${response.body}');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sayım başarıyla kaydedildi.')),
        );
      } catch (e) {
        print('Sayım kaydı yapılırken hata oluştu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Geçersiz işlem: Personel ve Oda seçili olmalı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Envanter Takip - Sayım",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 255, 255, 255), // Parlak kırmızı
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 247, 89, 89), // Parlak kırmızı
                Color(0xFF8B0000), // Koyu kırmızı
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 1),
              ElevatedButton(
                onPressed: () => _navigateAndSelectLocation(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text(
                  "LOKASYON SEÇ",
                  style: TextStyle(
                      color:
                          Color.fromARGB(255, 0, 0, 0)), // Yazı rengi koyu gri
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _navigateAndSelectPersonel(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text(
                  "PERSONEL SEÇ",
                  style: TextStyle(
                      color:
                          Color.fromARGB(255, 0, 0, 0)), // Yazı rengi koyu gri
                ),
              ),
              const SizedBox(height: 14),
              if (!isLocationSelected && selectedPersonelAdSoyad != null)
                Text(
                  'Personel: $selectedPersonelAdSoyad',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 251, 253, 131),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (selectedRoomNum != null)
                Text(
                  'Oda Numarası: $selectedRoomNum',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 37, 227, 248),
                  ),
                )
              else
                const Text(
                  "Henüz Lokasyon veya Personel Seçmediniz",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              SizedBox(height: 3),
              if (scannedBarcode != null)
                Text(
                  'Taranan Barkod: $scannedBarcode',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: 5),
              _buildInventoryInfoRow(
                  "TOPLAM SAYILMASI\nGEREKEN ENVANTER", totalEnvanter),
              _buildInventoryInfoRow(
                  "BULUNMAYAN ENVANTERLER", bulunmayanEnvanter),
              _buildInventoryInfoRow("BULUNAN ENVANTERLER", bulunanEnvanter),
              if (!isLocationSelected)
                _buildInventoryInfoRow(
                    "FARKLI LOKASYONDAKİ ENVANTERLER", farkliLokasyonEnvanter),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFoundMaterials,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text(
                  "SAYIMI KAYDET",
                  style: TextStyle(
                      color:
                          Color.fromARGB(255, 0, 0, 0)), // Yazı rengi koyu gri
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor:
          const Color(0xFF8B0000), // Beyaz alanı arka plan rengiyle kapatma
    );
  }

  Widget _buildInventoryInfoRow(String title, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              value.toString(),
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
