import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guide_me/user/galeri.dart';
import 'diskusiPage.dart';
import 'package:guide_me/Login.dart';
import 'daftar_destinasi.dart';
import 'requestRole.dart';
import 'tambah_destinasi.dart';
import 'daftar_event.dart';
import 'Profile.dart';
import 'destinasi_detail_page.dart'; 
import 'add_event.dart';
import 'detail_event.dart'; 
import 'tiket.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        canvasColor: const Color(0xFFEEEEEE),
        fontFamily:
            GoogleFonts.poppins().fontFamily, // Menggunakan Poppins sebagai default
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
  static const Color grayColor = Color(0xFFEEEEEE);
  static const Color primaryColor = Color(0xFF5ABB4D);

  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;
  String? _userName;
  bool _showAppBarTitle =
      false; // Ini tampaknya tidak digunakan secara aktif untuk AppBar
  int _currentCarouselIndex = 0;
  String _selectedDestinationCategory = 'All';
  String _selectedEventCategory = 'All';
  String _searchQuery = '';
  Timer? _timer;

  List<Map<String, dynamic>> _carouselItems = [];
  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingDestinations = true;
  bool _isLoadingEvents = true;

  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;

  final List<Map<String, dynamic>> _destinationCategories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Wisata Alam', 'icon': Icons.nature_people_rounded},
    {'name': 'Wisata Budaya', 'icon': Icons.museum_rounded},
    {'name': 'Wisata Religi', 'icon': Icons.mosque_rounded},
    {'name': 'Wisata Kuliner', 'icon': Icons.restaurant_rounded},
    {'name': 'Wisata Sejarah', 'icon': Icons.account_balance_rounded},
    {'name': 'Wisata Edukasi', 'icon': Icons.school_rounded},
    {'name': 'Wisata Petualangan', 'icon': Icons.hiking_rounded},
    {'name': 'Taman Hiburan', 'icon': Icons.celebration_rounded},
    {'name': 'Pantai', 'icon': Icons.beach_access},
    {'name': 'Gunung', 'icon': Icons.terrain_rounded},
    {'name': 'Air Terjun', 'icon': Icons.water_drop_rounded},
    {'name': 'Museum', 'icon': Icons.museum_outlined},
  ];

  final List<Map<String, dynamic>> _eventCategories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Konser', 'icon': Icons.music_note_rounded},
    {'name': 'Festival', 'icon': Icons.celebration_rounded},
    {'name': 'Pameran', 'icon': Icons.art_track_rounded},
    {'name': 'Seminar', 'icon': Icons.record_voice_over_rounded},
    {'name': 'Workshop', 'icon': Icons.handyman_rounded},
    {'name': 'Olahraga', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Kuliner', 'icon': Icons.restaurant_rounded},
    {'name': 'Budaya', 'icon': Icons.museum_rounded},
    {'name': 'Edukasi', 'icon': Icons.school_rounded},
    {'name': 'Teknologi', 'icon': Icons.devices_rounded},
    {'name': 'Bisnis', 'icon': Icons.business_center_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _initializeData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      // Perbarui _showSearchResults hanya jika ada fokus dan query tidak kosong
      _showSearchResults = _searchFocusNode.hasFocus && _searchQuery.isNotEmpty;
      _updateSearchResults();
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      // Tampilkan hasil jika ada fokus dan query tidak kosong
      _showSearchResults = _searchFocusNode.hasFocus && _searchQuery.isNotEmpty;
      // Jika fokus hilang dan query kosong, hapus hasil
      if (!_searchFocusNode.hasFocus && _searchQuery.isEmpty) {
        _searchResults.clear();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus(); // Penting untuk menghilangkan fokus
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
      _searchQuery = '';
    });
  }

  // >>>>>> BAGIAN PENTING: Penanganan Tap Hasil Pencarian <<<<<<
  void _handleSearchResultTap(Map<String, dynamic> item) {
    print('=== DEBUG SEARCH TAP ===');
    print('Full item data: $item');

    // Pastikan 'id' dan 'type' ada dan tidak null
    final String? id = item['id'] as String?;
    final String? type = item['type'] as String?;

    if (id == null || id.isEmpty) {
      _showErrorSnackBar('ID item tidak valid');
      return;
    }

    if (type == null || type.isEmpty) {
      _showErrorSnackBar('Tipe item tidak dikenali');
      return;
    }

    // Bersihkan hasil pencarian sebelum navigasi
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
      _searchQuery = '';
    });

    // Tunggu sebentar agar UI bersih dulu
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        if (type == 'destination') {
          print('Navigating to DestinasiDetailPage with ID: $id');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinasiDetailPage(destinasiId: id),
            ),
          );
        } else if (type == 'event') {
          print('Navigating to EventDetailPage with ID: $id');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(eventId: id),
            ),
          );
        } else {
          _showErrorSnackBar('Tipe item tidak dikenali: $type');
        }
      } catch (e) {
        print('ERROR during navigation: $e');
        _showErrorSnackBar('Gagal membuka halaman detail');
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // >>>>>> BAGIAN PENTING: Perbaikan untuk method _updateSearchResults <<<<<<
  void _updateSearchResults() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });
      return;
    }

    List<Map<String, dynamic>> tempResults = [];

    // Search in destinations dengan validasi ketat
    for (var dest in _destinations) {
      try {
        // Skip jika data tidak valid
        if (dest['id'] == null ||
            dest['namaDestinasi'] == null ||
            dest['namaDestinasi'].toString().trim().isEmpty) {
          continue;
        }

        final String name = dest['namaDestinasi'].toString().toLowerCase();
        final String category =
            (dest['kategori'] ?? '').toString().toLowerCase();
        final String location = (dest['lokasi'] ?? '').toString().toLowerCase();

        if (name.contains(_searchQuery) ||
            category.contains(_searchQuery) ||
            location.contains(_searchQuery)) {
          tempResults.add({
            'id': dest['id'].toString(), // Pastikan ini String
            'name': dest['namaDestinasi'].toString(),
            'type': 'destination',
            'category': dest['kategori']?.toString() ?? 'Umum',
            'location': dest['lokasi']?.toString() ?? 'Lokasi tidak tersedia',
          });
        }
      } catch (e) {
        print('Error processing destination for search: $e');
        continue;
      }
    }

    // Search in events dengan validasi ketat
    for (var event in _events) {
      try {
        // Skip jika data tidak valid
        if (event['id'] == null ||
            event['namaEvent'] == null ||
            event['namaEvent'].toString().trim().isEmpty) {
          continue;
        }

        final String name = event['namaEvent'].toString().toLowerCase();
        final String category =
            (event['kategori'] ?? '').toString().toLowerCase();

        if (name.contains(_searchQuery) || category.contains(_searchQuery)) {
          tempResults.add({
            'id': event['id'].toString(), // Pastikan ini String
            'name': event['namaEvent'].toString(),
            'type': 'event',
            'category': event['kategori']?.toString() ?? 'Umum',
          });
        }
      } catch (e) {
        print('Error processing event for search: $e');
        continue;
      }
    }

    // Limit hasil untuk performa yang lebih baik (maksimal 10 hasil)
    if (tempResults.length > 10) {
      tempResults = tempResults.take(10).toList();
    }

    print('Search results count: ${tempResults.length}');
    for (var result in tempResults) {
      print(
          'Result: ${result['name']}, ID: ${result['id']}, Type: ${result['type']}');
    }

    setState(() {
      _searchResults = tempResults;
      _showSearchResults =
          _searchFocusNode.hasFocus && _searchResults.isNotEmpty && _searchQuery.isNotEmpty;
    });
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _checkUserRole(),
      _checkLoginStatus(),
      _fetchUserName(),
      fetchCarouselItems(),
      _fetchDestinations(), // Memuat destinasi
      _fetchEvents(), // Memuat event
    ]);
    _updateLastActive();
    _startActiveTimer();
  }

  // >>>>>> BAGIAN PENTING: Memastikan ID di ambil saat fetch <<<<<<
  Future<void> _fetchDestinations() async {
    try {
      print('=== FETCHING DESTINATIONS ===');
      final snapshot =
          await FirebaseFirestore.instance
              .collection('destinasi')
              .orderBy('rating', descending: true)
              .get();

      if (mounted) {
        setState(() {
          _destinations =
              snapshot.docs.map((doc) {
                final data = doc.data();
                // PASTIKAN ID selalu ada dan berupa string
                data['id'] = doc.id;

                // Validasi data wajib
                data['namaDestinasi'] =
                    data['namaDestinasi'] ?? 'Nama tidak tersedia';
                data['kategori'] = data['kategori'] ?? 'Umum';
                data['lokasi'] = data['lokasi'] ?? 'Lokasi tidak tersedia';
                data['rating'] = (data['rating'] ?? 0).toDouble();
                data['imageUrl'] = data['imageUrl'] ?? '';

                print(
                    'Fetched Destination: ${data['namaDestinasi']}, ID: ${doc.id}');
                return data;
              }).toList();
          _isLoadingDestinations = false;
        });

        // Update search results setelah data dimuat
        _updateSearchResults();
        print('Total destinations loaded: ${_destinations.length}');
      }
    } catch (e) {
      print('Error fetching destinations: $e');
      if (mounted) {
        setState(() => _isLoadingDestinations = false);
        _showErrorSnackBar('Gagal memuat data destinasi: $e');
      }
    }
  }

  Future<void> _fetchEvents() async {
    try {
      print('=== FETCHING EVENTS ===');
      final snapshot =
          await FirebaseFirestore.instance.collection('events').get();

      if (mounted) {
        setState(() {
          _events =
              snapshot.docs.map((doc) {
                final data = doc.data();
                // PASTIKAN ID selalu ada dan berupa string
                data['id'] = doc.id;

                // Validasi data wajib
                data['namaEvent'] = data['namaEvent'] ?? 'Event tidak tersedia';
                data['kategori'] = data['kategori'] ?? 'Umum';
                data['imageUrl'] = data['imageUrl'] ?? '';

                print('Fetched Event: ${data['namaEvent']}, ID: ${doc.id}');
                return data;
              }).toList();
          _isLoadingEvents = false;
        });

        // Update search results setelah data dimuat
        _updateSearchResults();
        print('Total events loaded: ${_events.length}');
      }
    } catch (e) {
      print('Error fetching events: $e');
      if (mounted) {
        setState(() => _isLoadingEvents = false);
        _showErrorSnackBar('Gagal memuat data event: $e');
      }
    }
  }

  Future<void> fetchCarouselItems() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('sliders').get();
      if (mounted) {
        setState(() {
          _carouselItems = snapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    } catch (e) {
      print('Error fetching carousel items: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredDestinations({
    required bool isPopular,
  }) {
    var filtered =
        _destinations.where((dest) {
          final String? category = dest['kategori'];
          final bool matchesCategory =
              _selectedDestinationCategory == 'All' ||
              category == _selectedDestinationCategory;
          return matchesCategory;
        }).toList();

    if (isPopular) {
      // Urutkan berdasarkan rating tertinggi untuk terpopuler
      filtered.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
      // Ambil hanya setengah teratas (atau jumlah tertentu)
      final int halfLength = (filtered.length / 2).ceil();
      return filtered.take(halfLength).toList();
    } else {
      // Untuk "Lainnya", bisa diurutkan secara berbeda atau diambil sisanya
      // Saat ini diurutkan rating juga dan mengambil setengah bawah
      filtered.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
      final int halfLength = (filtered.length / 2).ceil();
      return filtered.skip(halfLength).toList();
    }
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    return _events.where((event) {
      final String? category = event['kategori'];
      final bool matchesCategory =
          _selectedEventCategory == 'All' || category == _selectedEventCategory;
      return matchesCategory;
    }).toList();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showAppBarTitle && mounted) {
      setState(() => _showAppBarTitle = showTitle);
    }
  }

  Future<void> _checkUserRole() async {
    if (!mounted) return;
    String? role = await getUserRole();
    if (mounted) {
      setState(() => userRole = role);
    }
  }

  void _updateLastActive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'lastActive': FieldValue.serverTimestamp()},
      );
    }
  }

  void _startActiveTimer() {
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateLastActive(),
    );
  }

  Future<void> _fetchUserName() async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && mounted) {
        // Tambahkan pengecekan doc.exists
        setState(() => _userName = doc['username']);
      }
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
      if (doc.exists) {
        // Tambahkan pengecekan doc.exists
        return doc['role'];
      }
    }
    return null;
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() => _isLoggedIn = user != null);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _timer?.cancel();
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
      backgroundColor: grayColor,
      onDrawerChanged: (isOpen) {
        if (!isOpen) _animationController.reverse();
      },
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(userRole: userRole),
    );
  }

  Widget _buildDrawer() {
    final drawerItems = <Map<String, dynamic>>[
      {
        'icon': Icons.map,
        'title': 'Destinasi',
        'action': () {
          Navigator.pop(context); // Tutup drawer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DaftarDestinasiPage(),
            ),
          );
        },
      },
      {
        'icon': Icons.chat,
        'title': 'Forum Diskusi',
        'action': () {
          Navigator.pop(context); // Tutup drawer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DiscussPage(),
            ),
          );
        },
      },
      {
        'icon': Icons.event,
        'title': 'Event',
        'action': () {
          Navigator.pop(context); // Tutup drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DaftarEventPage()),
          );
        },
      },
      {
        'icon': Icons.image,
        'title': 'Galeri',
        'action': () {
         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GaleriPage())
         );
        },
      },
    ];

    // Menambahkan item hanya jika user belum login atau belum memiliki role tertentu
    if (_isLoggedIn && userRole != "owner") {
      drawerItems.addAll([
        {
          'icon': Icons.tips_and_updates,
          'title': 'Tambah Destinasi',
          'action': () {
            Navigator.pop(context); // Tutup drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TambahDestinasiPage()),
            );
          },
        },
        {
          'icon': Icons.confirmation_number,
          'title': 'Tiket',
          'action': () {
            Navigator.pop(context); // Tutup drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TicketPage()),
            );
          },
        },
        {
          'icon': Icons.admin_panel_settings,
          'title': 'Request Role',
          'action': () {
            Navigator.pop(context); // Tutup drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RequestRolePage()),
            );
          },
        },
      ]);
    }

    if (userRole == "owner") {
      drawerItems.add({
        'icon': Icons.calendar_today,
        'title': 'Add Event',
        'action': () {
          Navigator.pop(context); // Tutup drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahEventPage()),
          );
        },
      });
    }

    drawerItems.add({
      'icon': _isLoggedIn ? Icons.logout : Icons.login,
      'title': _isLoggedIn ? "Keluar" : "Masuk",
      'action': () async {
        Navigator.pop(context); // Tutup drawer terlebih dahulu
        if (_isLoggedIn) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() {
              userRole = null;
              _userName = null;
              _isLoggedIn = false; // Update login status
            });
            // Gunakan pushAndRemoveUntil untuk membersihkan tumpukan navigasi
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false, // Hapus semua rute sebelumnya
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
    });

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Drawer(
        backgroundColor: grayColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primaryColor),
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
            ...drawerItems
                .map(
                  (item) => ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: Colors.black87,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                    onTap: (item['action'] as VoidCallback),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      // Ini akan menutup overlay pencarian ketika mengklik di luar area pencarian
      onTap: () {
        if (_showSearchResults) {
          _clearSearch();
        }
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 5),
                _buildWelcomeSection(),
                const SizedBox(height: 20),
                _buildCarousel(),
                _buildDestinationCategoriesSection(),
                _buildEventCategoriesSection(),
                _buildDestinationSection(
                  title: "Tempat Wisata Batam Terpopuler",
                  icon: Icons.star,
                  isPopular: true,
                ),
                _buildDestinationSection(
                  title: "Tempat Wisata Lainnya",
                  icon: Icons.location_on,
                  isPopular: false,
                ),
                _buildEventSection(title: "Event Terkini", icon: Icons.event),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Overlay hasil pencarian
          if (_showSearchResults)
            Positioned(
              top: 70, // Sesuaikan posisi agar di bawah search bar
              left: 16,
              right: 16,
              child: _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: grayColor,
      child: SafeArea( // Tambahkan SafeArea di sini
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
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: "Search destinations or events...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Jangan tampilkan apapun jika query kosong
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tampilkan pesan "tidak ada hasil" jika pencarian tidak menemukan apapun
    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Tidak ada hasil untuk "$_searchQuery"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final double maxResultsHeight = MediaQuery.of(context).size.height * 0.4;

    return Material( // Wrap with Material to ensure proper elevation and inkwell effects
      elevation: 4.0, // Add some elevation
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        constraints: BoxConstraints(maxHeight: maxResultsHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header hasil pencarian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Hasil pencarian untuk "$_searchQuery"',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_searchResults.length} hasil',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Daftar hasil
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            item['type'] == 'destination'
                                ? Colors.blue[50]
                                : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['type'] == 'destination'
                            ? Icons.location_on
                            : Icons.event,
                        color:
                            item['type'] == 'destination'
                                ? Colors.blue[600]
                                : Colors.orange[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['name'] as String, // Cast to String
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item['type'] == 'destination'
                          ? '${item['category'] as String} • ${item['location'] as String}'
                          : '${item['category'] as String} • Event',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    onTap: () {
                      print('Search result tapped: ${item['name']}');
                      _handleSearchResultTap(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    if (!_isLoggedIn || _userName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
      color: grayColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $_userName",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
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
      ),
    );
  }

  Widget _buildCarousel() {
    return Container(
      color: grayColor,
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child:
                  _carouselItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: 220.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              if (mounted) {
                                setState(() => _currentCarouselIndex = index);
                              }
                            },
                          ),
                          items:
                              _carouselItems
                                  .map((item) => _buildCarouselItem(item))
                                  .toList(),
                        ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                _carouselItems.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentCarouselIndex == entry.key
                              ? primaryColor
                              : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> item) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                item['imageUrl'] != null &&
                        (item['imageUrl'] as String).isNotEmpty
                    ? Image.network(
                        item['imageUrl'] as String, // Pastikan ini String
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder:
                            (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                        loadingBuilder:
                            (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'No Title', // Default jika null
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] ??
                        'No Description', // Default jika null
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            "Kategori Destinasi",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _destinationCategories.length,
            itemBuilder:
                (context, index) => _buildCategoryItem(
                  _destinationCategories[index],
                  isForDestination: true,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            "Kategori Event",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _eventCategories.length,
            itemBuilder:
                (context, index) => _buildCategoryItem(
                  _eventCategories[index],
                  isForDestination: false,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> category, {
    required bool isForDestination,
  }) {
    final isSelected =
        isForDestination
            ? _selectedDestinationCategory == category['name']
            : _selectedEventCategory == category['name'];

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            if (isForDestination) {
              _selectedDestinationCategory =
                  category['name'] as String; // Pastikan String
            } else {
              _selectedEventCategory =
                  category['name'] as String; // Pastikan String
            }
          });
        }
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
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        isSelected
                            ? primaryColor.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset:
                        isSelected ? const Offset(0, 3) : const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                category['icon'] as IconData, // Pastikan IconData
                color:
                    isSelected ? Colors.white : primaryColor.withOpacity(0.8),
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String, // Pastikan String
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required IconData icon,
    required bool isPopular,
  }) {
    if (_isLoadingDestinations) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = _getFilteredDestinations(isPopular: isPopular);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          color: grayColor,
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              destinations.isEmpty
                  ? Center(
                      child: Text(
                        "No destinations found.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final destination = destinations[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: DestinationCard(
                            id:
                                destination['id'] as String, // Pastikan ini String
                            title: destination['namaDestinasi'] as String,
                            image: destination['imageUrl'] as String,
                            rating:
                                (destination['rating'] as num).toDouble(), // Pastikan double
                            location: destination['lokasi'] as String,
                            kategori: destination['kategori'] as String,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEventSection({required String title, required IconData icon}) {
    if (_isLoadingEvents) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final events = _getFilteredEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          color: grayColor,
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              events.isEmpty
                  ? Center(
                      child: Text(
                        "No events found.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: EventCard(
                            id:
                                event['id'] as String, // Pastikan ini String
                            title: event['namaEvent'] as String,
                            image: event['imageUrl'] as String,
                            category: event['kategori'] as String,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Tidak ada perubahan signifikan di sini, tapi pastikan ID yang diterima adalah String
class DestinationCard extends StatelessWidget {
  final String id;
  final String title;
  final String image;
  final double rating;
  final String kategori;
  final String location;

  const DestinationCard({
    super.key,
    required this.id,
    required this.title,
    required this.image,
    required this.kategori,
    required this.rating,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinasiDetailPage(destinasiId: id),
          ),
        );
      },
      child: Container(
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
              Positioned.fill(
                child:
                    image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

// Tidak ada perubahan signifikan di sini, tapi pastikan ID yang diterima adalah String
class EventCard extends StatelessWidget {
  final String id;
  final String title;
  final String image;
  final String category;

  const EventCard({
    super.key,
    required this.id,
    required this.title,
    required this.image,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EventDetailPage(eventId: id)),
        );
      },
      child: Container(
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
              Positioned.fill(
                child:
                    image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
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
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final String? userRole;
  const CustomBottomNavBar({super.key, this.userRole});
  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    // Check if the current route is already the target route to prevent unnecessary pushes
    String? currentRouteName = ModalRoute.of(context)?.settings.name;

    if (index == 1 && currentRouteName == '/') { // HomePage is root '/'
      return; // Already on Home, do nothing
    } else if (index == 2 && currentRouteName == '/profile') { // Assuming ProfileScreen has a route name of '/profile'
      return; // Already on Profile, do nothing
    }

    setState(() => _selectedIndex = index);
    final currentUser = FirebaseAuth.instance.currentUser;

    switch (index) {
      case 0:
        // Future: Handle notifications page
        print('Notifications tapped');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications page (Under Construction)')),
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
        break;
      case 2:
        if (currentUser == null) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Akses Ditolak'),
                  content: const Text(
                    'Silakan login terlebih dahulu untuk mengakses profil.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        Navigator.push(
                          // Navigasi ke login
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
          );
        } else {
          Navigator.pushReplacement( // Use pushReplacement to avoid stacking ProfileScreen
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set selected index based on current route for proper highlight if navigating from external
    if (ModalRoute.of(context)?.settings.name == '/') {
      _selectedIndex = 1;
    } else if (ModalRoute.of(context)?.settings.name == '/profile') {
      _selectedIndex = 2;
    } else {
      // Default or other pages, assume home if not explicitly profile
      _selectedIndex = 1;
    }


    return Container(
      height: 60,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF5ABB4D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.notifications, 0),
          _buildNavItem(Icons.home, 1),
          _buildNavItem(Icons.person, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}