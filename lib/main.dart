import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EnvanterTakip.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GirisYap(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GirisYap extends StatefulWidget {
  const GirisYap({super.key});

  @override
  GirisYapState createState() => GirisYapState();
}

class GirisYapState extends State<GirisYap> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isUsernameCorrect = true;
  String _message = '';

  Future<void> _login() async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://10.10.208.118:8083/api/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EnvanterTakip(username: username),
          ),
        );
      } else {
        setState(() {
          _message = 'Hatalı giriş yaptınız';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Bağlantı hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white, // Üst kısım beyaz
                  Color(0xFFFFE6E6), // Orta kısım açık kırmızı
                  Color(0xFFFF0000), // Alt kısım BOTAŞ kırmızısı
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // İçeriği ortalar
              children: [
                const SizedBox(height: 10), // Logoyu biraz daha yukarı taşır
                Image.asset(
                  'lib/images/botasarkaplansız.png',
                  height: 190, // Logoyu biraz daha büyüt
                  width: 190,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          labelStyle: TextStyle(
                            color: Color(0xFFFF0000), // BOTAŞ kırmızısı
                            fontWeight: FontWeight.bold,
                          ),
                          suffixIcon:
                              Icon(Icons.person_outline, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: TextStyle(
                            color: Color(0xFFFF0000), // BOTAŞ kırmızısı
                            fontWeight: FontWeight.bold,
                          ),
                          suffixIcon:
                              Icon(Icons.lock_outline, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFF0000), // BOTAŞ kırmızısı
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 70, // Butonu biraz daha genişlet
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _message,
                        style: TextStyle(
                          color: _message == 'Başarılı giriş yaptınız'
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
