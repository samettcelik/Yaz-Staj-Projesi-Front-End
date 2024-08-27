import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'SayimEkrani.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonelSec(),
    ),
  );
}

class PersonelSec extends StatefulWidget {
  @override
  _PersonelSecState createState() => _PersonelSecState();
}

class _PersonelSecState extends State<PersonelSec> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> personelList = [];
  List<Map<String, dynamic>> roomList = [];
  bool isLoading = false;
  String errorMessage = '';
  Map<String, dynamic>? selectedPersonel;

  void _searchPersonel() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      personelList.clear();
      selectedPersonel = null;
      roomList.clear();
    });

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lütfen bir arama terimi girin.';
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'http://10.10.208.118:8083/api/personel/search?query=$query'));

      if (response.statusCode == 200) {
        setState(() {
          personelList =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          if (personelList.isEmpty) {
            errorMessage = 'Aradığınız kriterlere uygun personel bulunamadı.';
          }
        });
      } else {
        setState(() {
          errorMessage = 'Bir hata oluştu: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _selectPersonel(Map<String, dynamic> personel) async {
    setState(() {
      selectedPersonel = personel;
      roomList.clear();
      isLoading = true;
    });

    final personelId = personel['per_id'];

    try {
      final response = await http.get(Uri.parse(
          'http://10.10.208.118:8083/api/personel/rooms-by-personel?perId=$personelId'));

      if (response.statusCode == 200) {
        setState(() {
          roomList =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          if (roomList.isEmpty) {
            errorMessage = 'Bu personelin kayıtlı malzemesi bulunmamaktadır.';
          } else {
            _showRoomSelection();
          }
        });
      } else {
        setState(() {
          errorMessage = 'Bir hata oluştu: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showRoomSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: roomList.map((room) {
            return ListTile(
              title: Text('Oda: ${room['odaNum'] ?? 'Oda numarası yok'}'),
              onTap: () {
                Navigator.pop(context);
                _selectRoom(room);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _selectRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SayimEkrani(
          username: 'Kullanıcı Adı',
          selectedPersonelId: selectedPersonel!['per_id'],
          selectedPersonelAdSoyad: selectedPersonel!['adSoyad'],
          selectedRoomId: room['id'],
          selectedRoomNum: room['odaNum'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Personel Seç",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 30.0, 8.0, 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Personel ismi ya da sicil no girin',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _searchPersonel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFFF4A4A), // Parlak kırmızı
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
                      'Bul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isLoading && personelList.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: personelList.length,
                        itemBuilder: (context, index) {
                          final personel = personelList[index];
                          return Column(
                            children: [
                              ListTile(
                                title: Text(
                                  personel['adSoyad'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  'Sicil No: ${personel['sicilNo']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white),
                                onTap: () {
                                  _selectPersonel(personel);
                                },
                              ),
                              const Divider(color: Colors.white70),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
