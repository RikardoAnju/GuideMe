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
  
  // ScrollController for animation effects
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  
  // Add a variable to track current carousel index
  int _currentCarouselIndex = 0;
  // Add a variable to track selected category
  String _selectedCategory = 'All';
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
  
  // Categories with modern icons
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Beach', 'icon': Icons.beach_access},
    {'name': 'Café', 'icon': Icons.coffee_rounded},
    {'name': 'Park', 'icon': Icons.nature_people_rounded},
    {'name': 'Mall', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Hotel', 'icon': Icons.hotel_rounded},
    {'name': 'History', 'icon': Icons.museum_rounded},
  ];
  
  // Destination items - Popular Tourist Spots
  final List<Map<String, dynamic>> _popularDestinations = [
    {
      'title': "Mega Wisata Ocarina",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Park',
      'location': 'Batam'
    },
    {
      'title': "Pantai Nongsa",
      'image': "assets/images/slider3.png",
      'rating': 4.7,
      'category': 'Beach',
      'location': 'Batam'
    },
    {
      'title': "Jembatan Barelang",
      'image': "assets/images/slider1.png",
      'rating': 4.9,
      'category': 'History',
      'location': 'Batam'
    },
    {
      'title': "Nagoya Hill Mall",
      'image': "assets/images/slider2.png",
      'rating': 4.6,
      'category': 'Mall',
      'location': 'Batam'
    },
  ];
  
  // Other tourist attractions - Separated from popular destinations
  final List<Map<String, dynamic>> _otherDestinations = [
    {
      'title': "Welcome Monument",
      'image': "assets/images/slider1.png",
      'rating': 4.5,
      'category': 'History',
      'location': 'Batam'
    },
    {
      'title': "Harbor Bay",
      'image': "assets/images/slider3.png",
      'rating': 4.4,
      'category': 'Beach',
      'location': 'Batam'
    },
    {
      'title': "Joyful Café",
      'image': "assets/images/slider1.png",
      'rating': 4.7,
      'category': 'Café',
      'location': 'Batam'
    },
    {
      'title': "Mercure Hotel",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Hotel',
      'location': 'Batam'
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Fixed milliseconds instead of microseconds
    );
    _checkUserRole();
    _checkLoginStatus();
    _fetchUserName();
    
    // Add scroll listener for animations
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    // Show/hide app bar title based on scroll position
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          controller: _scrollController, // Add the scroll controller
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
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
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
                          items: _carouselItems.map((item) {
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
                      children: _carouselItems.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == entry.key
                                ? const Color(0xFF5ABB4D) // Active dot color (green)
                                : Colors.grey.withOpacity(0.5), // Inactive dot color
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // Category selector section - IMPROVED
              Container(
                padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                child: Text(
                  "Categories",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Enhanced categories with modern icons and animation - FIXED ANIMATION
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['name'];
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(top: isSelected ? 0 : 8.0, bottom: isSelected ? 8.0 : 0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['name'];
                          });
                        },
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5ABB4D)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected 
                                          ? const Color(0xFF5ABB4D).withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: isSelected ? 8 : 4,
                                      spreadRadius: isSelected ? 2 : 0,
                                      offset: isSelected 
                                          ? const Offset(0, 3)
                                          : const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: isSelected ? Colors.white : const Color(0xFF5ABB4D).withOpacity(0.8),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF5ABB4D) : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Popular destinations section - FIXED CARD IMPLEMENTATION
              Container(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                color: grayColor,
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
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
              ),
             
             
              SizedBox(
                height: 240, // Height for the cards
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _popularDestinations.where((dest) =>
                    _selectedCategory == 'All' || dest['category'] == _selectedCategory
                  ).length,
                  itemBuilder: (context, index) {
                    final filteredDestinations = _popularDestinations.where((dest) =>
                      _selectedCategory == 'All' || dest['category'] == _selectedCategory
                    ).toList();
                    
                    if (filteredDestinations.isEmpty) {
                      return const Center(
                        child: Text("No destinations in this category"),
                      );
                    }
                    
                    final destination = filteredDestinations[index];
                   
                    // Use safer animation approach
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0,
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        child: DestinationCard(
                          title: destination['title'],
                          image: destination['image'],
                          rating: destination['rating'],
                          location: destination['location'],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // ADDED SEPARATE SECTION FOR OTHER TOURIST ATTRACTIONS
              Container(
                padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
                color: grayColor,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF5ABB4D),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tempat Wisata Lainnya",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Other destinations section - SEPARATED FROM POPULAR DESTINATIONS
              SizedBox(
                height: 240, // Height for the cards
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _otherDestinations.where((dest) =>
                    _selectedCategory == 'All' || dest['category'] == _selectedCategory
                  ).length,
                  itemBuilder: (context, index) {
                    final filteredDestinations = _otherDestinations.where((dest) =>
                      _selectedCategory == 'All' || dest['category'] == _selectedCategory
                    ).toList();
                    
                    if (filteredDestinations.isEmpty) {
                      return const Center(
                        child: Text("No destinations in this category"),
                      );
                    }
                    
                    final destination = filteredDestinations[index];
                    
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0,
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        child: DestinationCard(
                          title: destination['title'],
                          image: destination['image'],
                          rating: destination['rating'],
                          location: destination['location'],
                        ),
                      ),
                    );
                  },
                ),
              ),
             
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// Renamed and fixed card implementation
class DestinationCard extends StatelessWidget {
  final String title;
  final String image;
  final double rating;
  final String location;
  
  const DestinationCard({
    super.key,
    required this.title,
    required this.image,
    required this.rating,
    required this.location,
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
            Positioned.fill(
              child: Image.asset(
                image, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
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
                  mainAxisSize: MainAxisSize.min, // Make sure row doesn't take all width
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
                          location,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
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