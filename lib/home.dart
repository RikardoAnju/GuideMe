import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guide_me/Login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 400),
    );

    _checkUserRole();
    _checkLoginStatus();
  }

  Future<void> _checkUserRole() async {
    String? role = await getUserRole();
    setState(() {
      userRole = role;
    });
  }

  Future<String?> getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return doc['role'];
    }
    return null;
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null; // Jika ada user, berarti sudah login
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      _animationController.reverse();
    } else {
      _scaffoldKey.currentState?.openDrawer();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (!isOpen) {
          _animationController.reverse();
        }
      },
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: Colors.black,
                ),
                onPressed: _toggleDrawer,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5ABB4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Membulatkan tombol
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Jelajah",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.telegram,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,

            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF5ABB4D)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/logo1.png',
                      width: 123,
                      height: 120,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text("Destinasi"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text("Event"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number),
                title: const Text("Tiket"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Galeri"),
                onTap: () {},
              ),
              if (_isLoggedIn && userRole != "owner")
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text("Request Role"),
                  onTap: () {},
                ),
              if (userRole == "owner")
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("Add Event"),
                  onTap: () {},
                ),

              ListTile(
                leading: Icon(
                  FirebaseAuth.instance.currentUser != null
                      ? Icons.logout
                      : Icons.login,
                ),
                title: Text(
                  FirebaseAuth.instance.currentUser != null
                      ? "Keluar"
                      : "Masuk",
                ),
                onTap: () async {
                  if (FirebaseAuth.instance.currentUser != null) {
                    // Jika user sudah login, lakukan logout
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      userRole = null; // Reset userRole setelah logout
                    });
                    // Arahkan kembali ke halaman login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  } else {
                    // Jika belum login, arahkan ke halaman login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 250.0,

                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    viewportFraction: 1.0,
                  ),
                  items:
                      [
                        'assets/images/slider1.png',
                        'assets/images/slider2.png',
                        'assets/images/slider3.png',
                      ].map((imagePath) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selamat Datang di Guide Me",
                        style: TextStyle(
                          color: Color(0xFF5ABB4D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Penunjuk Arah Tempat Wisata Batam",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5ABB4D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              30,
                            ), 
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Lihat destinasi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.telegram, 
                                  color: Colors.black, 
                                  size: 16, 
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Tempat Wisata Batam Terpopuler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: const [
                  WisataCard(
                    title: "Mega Wisata Ocarina",
                    image: "assets/images/slider2.png",
                  ),
                  WisataCard(
                    title: "Welcome To Batam",
                    image: "assets/images/slider1.png",
                  ),
                  WisataCard(
                    title: "Pantai Nongsa",
                    image: "assets/images/slider3.png",
                  ),
                  WisataCard(
                    title: "Jembatan Barelang",
                    image: "assets/images/slider1.png",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

class WisataCard extends StatelessWidget {
  final String title;
  final String image;

  const WisataCard({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF5ABB4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          Icon(Icons.home, color: Colors.white, size: 28),
          Icon(Icons.search, color: Colors.white, size: 28),
          Icon(Icons.person, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}
