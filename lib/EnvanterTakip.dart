import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'SayimEkrani.dart';
import 'MalzemeBul.dart';
import 'main.dart';

class EnvanterTakip extends StatefulWidget {
  final String username;
  final bool isPersonelBazli;

  EnvanterTakip({required this.username, this.isPersonelBazli = false});

  @override
  _EnvanterTakipState createState() => _EnvanterTakipState();
}

class _EnvanterTakipState extends State<EnvanterTakip> {
  int totalMaterials = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTotalMaterialCount();
  }

  Future<void> _fetchTotalMaterialCount() async {
    setState(() {
      isLoading = true;
    });

    try {
      final locationIdResponse = await http.get(Uri.parse(
          'http://10.10.208.118:8083/api/location/${widget.username}'));
      final locationId = json.decode(locationIdResponse.body);

      // Personel bazlı mı kontrol ediyoruz
      final String apiUrl = widget.isPersonelBazli
          ? 'http://10.10.208.118:8083/api/materials/personel-total/$locationId'
          : 'http://10.10.208.118:8083/api/materials/location/$locationId/total';

      final response = await http.get(Uri.parse(apiUrl));
      final data = json.decode(response.body);

      setState(() {
        // Eğer API yanıtı bir sayı içeriyorsa direkt olarak totalMaterials'a atıyoruz
        totalMaterials =
            data is int ? data : int.parse(data['total'].toString());
      });
    } catch (e) {
      print('Error fetching total material count: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          flexibleSpace: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/images/botasarkaplansız.png',
                  height: 80,
                ),
                const SizedBox(height: 0),
                const Text(
                  'Envanter Takip Sistemi',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.only(bottom: 20.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF4A4A), // Kırmızı
                    Color(0xFF8B0000), // Koyu kırmızı
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$totalMaterials',
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Toplam Malzeme Sayısı',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                children: <Widget>[
                  buildModernButton(context, 'SAYIM', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SayimEkrani(username: widget.username)),
                    );
                  }),
                  buildModernButton(context, 'MALZEME BUL', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MalzemeBul()),
                    );
                  }),
                  buildModernButton(
                      context,
                      isLoading ? 'GÜNCELLENİYOR...' : 'VERİLERİ GÜNCELLE',
                      isLoading
                          ? null
                          : () {
                              _fetchTotalMaterialCount();
                            }),
                  buildModernButton(context, 'ÇIKIŞ YAP', _logout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildModernButton(
      BuildContext context, String text, VoidCallback? onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 204, 44, 44),
        minimumSize: const Size(60, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 10,
        shadowColor: const Color.fromARGB(255, 196, 35, 35).withOpacity(0.5),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
