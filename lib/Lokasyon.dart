import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Lokasyon extends StatefulWidget {
  final String username;

  Lokasyon({required this.username});

  @override
  _LokasyonState createState() => _LokasyonState();
}

class _LokasyonState extends State<Lokasyon> {
  List<Map<String, dynamic>> subLocations = [];
  List<Map<String, dynamic>> filteredSubLocations = [];
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = false;
  String query = "";

  @override
  void initState() {
    super.initState();
    fetchSubLocations();
  }

  Future<void> fetchSubLocations() async {
    setState(() {
      isLoading = true;
    });

    final response =
        await http.get(Uri.parse('http://10.10.208.118:8083/api/sublocations'));

    if (response.statusCode == 200) {
      setState(() {
        subLocations = List<Map<String, dynamic>>.from(json
            .decode(response.body)
            .map((data) => {'name': data['name'], 'id': data['id']}));
        filteredSubLocations = subLocations;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      query = newQuery;
      filteredSubLocations = subLocations
          .where((subLocation) =>
              subLocation['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> fetchRooms(int subId) async {
    setState(() {
      isLoading = true;
    });

    final response =
        await http.get(Uri.parse('http://10.10.208.118:8083/api/rooms/$subId'));

    if (response.statusCode == 200) {
      setState(() {
        rooms = List<Map<String, dynamic>>.from(json.decode(response.body));
        isLoading = false;
      });
    } else {
      setState(() {
        rooms = [
          {'odaNum': 'Odalar yüklenemedi', 'id': null}
        ];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lokasyon Seç",
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
                        decoration: InputDecoration(
                          hintText: 'Lokasyon Ara...',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: updateSearchQuery,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSubLocations.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                filteredSubLocations[index]['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                              onTap: () async {
                                await fetchRooms(
                                    filteredSubLocations[index]['id']);
                                setState(() {});
                              },
                            ),
                            const Divider(color: Colors.white70),
                          ],
                        );
                      },
                    ),
                  ),
                  if (rooms.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6.0,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Odalar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 90, 244),
                            ),
                          ),
                          const Divider(),
                          ...rooms.map((room) {
                            return ListTile(
                              title: Text(room['odaNum']),
                              onTap: () {
                                Navigator.pop(context, {
                                  'roomId': room['id'],
                                  'roomNum': room['odaNum'],
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
