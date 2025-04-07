import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guide_me/Login.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set the app-wide theme to use gray background
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        canvasColor: const Color(0xFFEEEEEE),
      ),
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
  String? _userName;
  // Add a variable to track current carousel index
  int _currentCarouselIndex = 0;

  // Updated carousel items with titles
  final List<Map<String, String>> _carouselItems = [
    {
      'image': 'assets/images/slider1.png',
      'title': 'Welcome to Batam',
      'description': 'Discover the beauty of the island',
    },
    {
      'image': 'assets/images/slider2.png',
      'title': 'Mega Wisata Ocarina',
      'description': 'Explore our premium attractions',
    },
    {
      'image': 'assets/images/slider3.png',
      'title': 'Pantai Nongsa',
      'description': 'Enjoy the pristine beaches',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 400),
    );

    _checkUserRole();
    _checkLoginStatus();
    _fetchUserName();
  }

  Future<void> _checkUserRole() async {
    String? role = await getUserRole();
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      setState(() {
        _userName = doc['username'];
      });
    }
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
      _isLoggedIn = user != null;
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
    // Use a constant gray color throughout
    const Color grayColor = Color(0xFFEEEEEE);

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (!isOpen) {
          _animationController.reverse();
        }
      },
      // Set the scaffold background to gray
      backgroundColor: grayColor,

      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Drawer(
          // Apply gray background to drawer
          backgroundColor: grayColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  // Keep green for the header but can change if needed
                  color: const Color(0xFF5ABB4D),
                ),
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
                   
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      userRole = null; 
                      _userName = null; 
                    });
                   
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  } else {
                    
                    Navigator.push(
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

      body: Container(
      
        color: grayColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              Container(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                color: grayColor,
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
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white, 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide
                                    .none, 
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide
                                    .none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
                color: grayColor,
                child:
                    _isLoggedIn && _userName != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, $_userName",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Welcome to GuideME",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF808080),
                              ),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              
              Container(
                color: grayColor,
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 220.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                          ),
                          items:
                              _carouselItems.map((item) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2.0,
                                      ),
                                      child: Stack(
                                        children: [
                                          // Image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: Image.asset(
                                              item['image']!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                          // Gradient overlay for better text visibility
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(
                                                      0.6,
                                                    ),
                                                  ],
                                                  stops: const [0.6, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Text overlay
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title']!,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 3.0,
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['description']!,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      shadows: [
                                                        Shadow(
                                                          blurRadius: 2.0,
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Add indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          _carouselItems.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _currentCarouselIndex == entry.key
                                        ? const Color(
                                          0xFF5ABB4D,
                                        ) // Active dot color (green)
                                        : Colors.grey.withOpacity(
                                          0.5,
                                        ), // Inactive dot color
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              // Enhanced Popular destinations section with improved cards
              Container(
                padding: const EdgeInsets.all(16.0),
                color: grayColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF5ABB4D),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Tempat Wisata Batam Terpopuler",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: [
                        // Improved attractive cards
                        EnhancedWisataCard(
                          title: "Mega Wisata Ocarina",
                          image: "assets/images/slider2.png",
                          rating: 4.8,
                        ),
                        EnhancedWisataCard(
                          title: "Welcome To Batam",
                          image: "assets/images/slider1.png",
                          rating: 4.5,
                        ),
                        EnhancedWisataCard(
                          title: "Pantai Nongsa",
                          image: "assets/images/slider3.png",
                          rating: 4.7,
                        ),
                        EnhancedWisataCard(
                          title: "Jembatan Barelang",
                          image: "assets/images/slider1.png",
                          rating: 4.9,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// Enhanced WisataCard with more appealing design
class EnhancedWisataCard extends StatelessWidget {
  final String title;
  final String image;
  final double rating;

  const EnhancedWisataCard({
    super.key,
    required this.title,
    required this.image,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Rating in the top right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Batam",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
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
          Icon(Icons.notifications, color: Colors.white, size: 28),
          Icon(Icons.home, color: Colors.white, size: 28),
          Icon(Icons.person, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}
