import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../services/localization.dart';
import '../models/room.dart';
import '../models/saved_alert.dart';
import '../widgets/room_card.dart';
import 'login_page.dart';
import 'add_post_page.dart';
import 'categories_page.dart';
import 'my_ads_page.dart';
import 'my_alerts_page.dart';
import 'room_detail_page.dart';
import 'pending_ads_page.dart';
import 'reject_reasons_page.dart';
import 'profile_page.dart';
import 'contact_us_page.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDistrict;
  String? _selectedTown;
  String? _selectedCategory;
  RangeValues? _priceRange;
  bool _isOffline = false;
  bool _showBackOnline = false;
  final int _pageSize = 10;
  int _loadedRoomsCount = 10;
  Timer? _connectivityTimer;
  final Set<String> _precachedThumbnails = {};
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<Room> _latestRooms = [];
  List<Room> _cachedRooms = [];
  List<String> _categories = [];
  List<Room> _filteredRooms = [];
  List<int> _priceList = [];
  int _minPrice = 0;
  int _maxPrice = 0;
  // ignore: unused_field
  RangeValues? _effectivePriceRange;

  static const Map<String, List<String>> _districtTowns = {
    'Colombo': [
      'Nugegoda', 'Maharagama', 'Piliyandala', 'Colombo 3', 'Dehiwala',
      'Boralesgamuwa', 'Kottawa', 'Battaramulla', 'Homagama', 'Athurugiriya',
      'Moratuwa', 'Colombo 6', 'Rajagiriya', 'Malabe', 'Talawatugoda',
      'Colombo 4', 'Pannipitiya', 'Kaduwela', 'Wellampitiya', 'Ratmalana',
      'Colombo 5', 'Kotte', 'Mount Lavinia', 'Colombo 10', 'Kohuwala',
      'Colombo 8', 'Angoda', 'Colombo 12', 'Colombo 2', 'Colombo 13',
      'Avissawella', 'Colombo 11', 'Kolonnawa', 'Nawala', 'Colombo 9',
      'Colombo 7', 'Meegoda', 'Colombo 15', 'Kesbewa', 'Colombo 14',
      'Hanwella', 'Padukka', 'Godagama', 'Colombo 1', 'Polgasowita',
      'Kalubowila', 'Kotikawatta', 'Ranala', 'Nawagamuwa', 'Olaboduwa', 'Embulgama',
    ],
    'Gampaha': [
      'Gampaha City', 'Negombo', 'Kadawatha', 'Kiribathgoda', 'Wattala',
      'Ja-Ela', 'Kelaniya', 'Nittambuwa', 'Minuwangoda', 'Kandana',
      'Ragama', 'Delgoda', 'Katunayake', 'Veyangoda', 'Seeduwa',
      'Ganemulla', 'Mirigama', 'Divulapitiya', 'Biyagama', 'Kalagedihena',
      'Kirindiwela', 'Peliyagoda', 'Dompe', 'Miriswatta', 'Bopitiya',
      'Pugoda', 'Gonawala', 'Mawaramandiya', 'Walikatiya', 'Delathura', 'Nilsirigama',
    ],
    'Kalutara': [
      'Panadura', 'Horana', 'Kalutara City', 'Bandaragama', 'Alutgama',
      'Matugama', 'Wadduwa', 'Beruwala', 'Ingiriya', 'Gonapola',
      'Talagala', 'Awittawa', 'Ittapane', 'Pitipana', 'Meegahathenna',
      'Kevitiyagala', 'Moragala', 'Walallavita', 'Polgampola', 'Uthumgama',
    ],
    'Kandy': [
      'Kandy City', 'Gampola', 'Katugastota', 'Akurana', 'Peradeniya',
      'Pilimatalawa', 'Digana', 'Kundasale', 'Nawalapitiya', 'Gelioya',
      'Galagedara', 'Kadugannawa', 'Ampitiya', 'Madawala Bazaar', 'Wattegama',
      'Pussellawa', 'Menikhinna', 'Galaha', 'Danthure', 'Deltota',
      'Pallekele', 'Udunuwara', 'Urapola', 'Doluwa', 'Dodamwala',
      'Poththapitiya', 'Pathahewaheta', 'Rattapitiya', 'Tawalantenne',
    ],
    'Matale': [
      'Matale', 'Dambulla', 'Sigiriya', 'Galewela', 'Ukuwela',
      'Rattota', 'Yatawatta', 'Pallepola', 'Naula', 'Laggala-Pallegama',
    ],
    'Nuwara Eliya': [
      'Nuwara Eliya', 'Hatton', 'Talawakele', 'Ginigathena', 'Walapane',
      'Madulla', 'Kundasale', 'Hanguranketha', 'Nuwara Eliya-Maskeliya',
      'Kotagala', 'Ramboda', 'Ambewela', 'Pundaluoya', 'Haputale', 'Welimada',
    ],
    'Galle': [
      'Galle', 'Hikkaduwa', 'Ambalangoda', 'Elpitiya', 'Bentota',
      'Baddegama', 'Balapitiya', 'Ahangama', 'Urubokka', 'Nagoda',
      'Neluwa', 'Udugama', 'Imaduwa', 'Habaraduwa', 'Karandeniya',
    ],
    'Matara': [
      'Matara', 'Weligama', 'Akuressa', 'Hakmana', 'Kamburupitiya',
      'Dickwella', 'Deniyaya', 'Devinuwara', 'Kekanadura', 'Pitabeddara',
      'Thihagoda', 'Malimbada', 'Pasgoda', 'Mulatiyana', 'Welihinda',
    ],
    'Hambantota': [
      'Hambantota', 'Tangalle', 'Beliatta', 'Tissamaharama', 'Kataragama',
      'Ambalantota', 'Weeraketiya', 'Angunakolapelessa', 'Lunugamvehera',
      'Okewela', 'Walasmulla', 'Sooriyawewa', 'Middeniya', 'Rajagalatenna',
    ],
    'Jaffna': [
      'Jaffna', 'Chavakachcheri', 'Point Pedro', 'Valvettithurai', 'Karainagar',
      'Kayts', 'Nallur', 'Tellippalai', 'Uduvil', 'Chankanai',
      'Sandilipay', 'Maruthankerny', 'Velanai', 'Delft', 'Kopay',
    ],
    'Kilinochchi': [
      'Kilinochchi', 'Poonakary', 'Paranthan', 'Mullaitivu', 'Mankulam',
      'Vavuniya', 'Mannar', 'Mulliyawalai', 'Oddusuddan', 'Madhu',
      'Nanattan', 'Murunkan', 'Adampan', 'Puthukkudiyiruppu', 'Iranamadu',
    ],
    'Mannar': [
      'Mannar', 'Vankalai', 'Pesalai', 'Madhu', 'Nanattan',
      'Murunkan', 'Adampan', 'Puthukkudiyiruppu', 'Iranamadu', 'Talaimannar',
      'Erukkalampiddy', 'Sillalai', 'Uttukulam', 'Marichchikaddi', 'Kallikulam',
    ],
    'Vavuniya': [
      'Vavuniya', 'Cheddikulam', 'Nedunkeni', 'Mullaitivu', 'Mannar',
      'Kilinochchi', 'Anuradhapura', 'Trincomalee', 'Batticaloa', 'Ampara',
      'Polonnaruwa', 'Kurunegala', 'Puttalam', 'Matale', 'Nuwara Eliya',
    ],
    'Mullaitivu': [
      'Mullaitivu', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Oddusuddan',
      'Puthukkudiyiruppu', 'Mankulam', 'Maritimepattu', 'Thunukkai', 'Poonakary',
      'Paranthan', 'Mulliyawalai', 'Nanattan', 'Madhu', 'Iranamadu',
    ],
    'Batticaloa': [
      'Batticaloa', 'Eravur', 'Valachchenai', 'Kattankudy', 'Oddamavadi',
      'Kalmunai', 'Sainthamaruthu', 'Pottuvil', 'Arayampathy', 'Chenkalady',
      'Vakarai', 'Manmunai', 'Porativu', 'Kiran', 'Koralai Pattu',
    ],
    'Ampara': [
      'Ampara', 'Akkaraipattu', 'Kalmunai', 'Sainthamaruthu', 'Pottuvil',
      'Uhana', 'Maha Oya', 'Navithanveli', 'Lahugala', 'Dehiattakandiya',
      'Sammanthurai', 'Irakkamam', 'Addalachchenai', 'Alayadiwembu', 'Damana',
    ],
    'Trincomalee': [
      'Trincomalee', 'Kinniya', 'Muttur', 'Kuchchaveli', 'Seruvila',
      'Thampalakamam', 'Gomarankadawala', 'Padavi Sri Pura', 'Kantalai',
      'Moratuwa', 'Verugal', 'Eachchilampattu', 'Nilaveli', 'Pulmoddai', 'Sampur',
    ],
    'Kurunegala': [
      'Kurunegala', 'Kuliyapitiya', 'Narammala', 'Polgahawela', 'Wariyapola',
      'Pannala', 'Alawwa', 'Mawathagama', 'Nikaweratiya', 'Ibbagamuwa',
      'Ganewatta', 'Pothuhera', 'Katugampola', 'Bingiriya', 'Dambadeniya',
    ],
    'Puttalam': [
      'Puttalam', 'Chilaw', 'Wennappuwa', 'Marawila', 'Dankotuwa',
      'Nattandiya', 'Anamaduwa', 'Kalpitiya', 'Arachchikattuwa', 'Madampe',
      'Vanathavilluwa', 'Nawagattegama', 'Pallama', 'Lunuwila', 'Mundalama',
    ],
    'Anuradhapura': [
      'Anuradhapura', 'Kekirawa', 'Medawachchiya', 'Tambuttegama', 'Mihintale',
      'Nochchiyagama', 'Galnewa', 'Rambewa', 'Thalawa', 'Rajanganaya',
      'Horowpothana', 'Ipalogama', 'Palagala', 'Kahatagasdigiliya', 'Nachchadoowa',
    ],
    'Polonnaruwa': [
      'Polonnaruwa', 'Kaduruwela', 'Hingurakgoda', 'Medirigiriya', 'Dimbulagala',
      'Elahera', 'Lankapura', 'Welikanda', 'Aralaganwila', 'Manampitiya',
      'Giritale', 'Thamankaduwa', 'Bakamuna', 'Dehiattakandiya', 'Jayantipura',
    ],
    'Badulla': [
      'Badulla', 'Bandarawela', 'Haputale', 'Welimada', 'Mahiyanganaya',
      'Rideegama', 'Girandurukotte', 'Hali-Ela', 'Uva-Paranagama', 'Kandaketiya',
      'Ella', 'Passara', 'Lunugala', 'Sorabora', 'Madulsima',
    ],
    'Moneragala': [
      'Moneragala', 'Wellawaya', 'Bibile', 'Kataragama', 'Buttala',
      'Siyambalanduwa', 'Medagama', 'Thanamalvila', 'Sevanagala', 'Badalkumbura',
      'Dambagalla', 'Pitabeddara', 'Okkampitiya', 'Nakkala', 'Hulandawa',
    ],
    'Ratnapura': [
      'Ratnapura', 'Embilipitiya', 'Balangoda', 'Pelmadulla', 'Eheliyagoda',
      'Kuruwita', 'Kiriella', 'Opanayaka', 'Nivithigala', 'Ayagama',
      'Kalawana', 'Imbulpe', 'Godakawela', 'Kahawatta', 'Weligepola',
    ],
    'Kegalle': [
      'Kegalle', 'Mawanella', 'Warakapola', 'Rambukkana', 'Galigamuwa',
      'Yatiyanthota', 'Deraniyagala', 'Bulathkohupitiya', 'Aranayaka', 'Kitulgala',
      'Hemmathagama', 'Dehiovita', 'Ruwanwella', 'Weligalla', 'Udapotha',
    ],
  };

  List<String> get _districts => (_districtTowns.keys.toList()..sort());
  // Rooms received from the stream while the user is scrolled down.
  // Applied (and scroll reset) only when the user taps the banner.
  List<Room>? _bufferedRoomsUpdate;
  int _bufferedNewCount = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showGoToTop = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _checkConnectivity(),
    );
    AppState.instance.rooms.addListener(_onRoomsChanged);
    AppState.instance.pendingNotification.addListener(
      _handlePendingNotification,
    );
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 120;
      if (shouldShow != _showGoToTop) {
        setState(() {
          _showGoToTop = shouldShow;
        });
      }
    });
    // Process rooms already available (e.g. after navigation or hot reload)
    final initialRooms = AppState.instance.rooms.value.cast<Room>();
    if (initialRooms.isNotEmpty) {
      _latestRooms = initialRooms;
      _updateFilterData(initialRooms);
    }
    // Handle a pending notification roomId set before HomePage was built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handlePendingNotification(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    AppState.instance.rooms.removeListener(_onRoomsChanged);
    AppState.instance.pendingNotification.removeListener(
      _handlePendingNotification,
    );
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handlePendingNotification() async {
    final pending = AppState.instance.pendingNotification.value;
    if (pending == null || (pending.roomId.isEmpty && (pending.type == null || pending.type!.isEmpty))) {
      return;
    }

    // Clear immediately so we don't navigate twice.
    AppState.instance.pendingNotification.value = null;
    if (!mounted) return;

    if (pending.type == 'pending_ad') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PendingAdsPage()),
      );
      return;
    }

    final roomId = pending.roomId;
    if (roomId.isEmpty) return;

    // Retry up to 3 times with a short delay between attempts.
    // This handles the brief "offline" window that can occur when the app
    // is brought to the foreground from a background state, which can cause
    // the first Firestore fetch to fail before the network is fully resumed.
    Room? room;
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
      }
      room = await AppState.instance.fetchRoom(roomId);
      if (room != null) break;
    }

    if (room == null || !mounted) return;

    // Only apply the alert filter when no filter is currently active.
    // If the user already has a filter set, respect it and just show the ad.
    if (_activeFilterCount == 0) {
      final matchingAlert = AppState.instance.savedAlerts.value
          .where(
            (a) =>
                (a.district == null || a.district == room!.district) &&
                (a.town == null || a.town == room!.town) &&
                (a.category == null || a.category == room!.category),
          )
          .cast<SavedAlert?>()
          .firstOrNull;
      if (matchingAlert != null) _applyAlertFilter(matchingAlert);
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomDetailPage(room: room!)),
    );
  }

  void _onRoomsChanged() {
    if (!mounted) return;
    final roomList = AppState.instance.rooms.value.cast<Room>();

    // Count rooms that are new (not yet in the displayed list).
    final currentIds = _latestRooms.map((r) => r.id).toSet();
    final newCount =
        roomList
            .where((r) => r.id != null && !currentIds.contains(r.id))
            .length;

    // If the user is scrolled down and there are genuinely new rooms,
    // buffer the update and show a banner instead of disrupting their scroll.
    final isScrolledDown =
        _scrollController.hasClients && _scrollController.offset > 50;

    if (newCount > 0 && isScrolledDown) {
      setState(() {
        _bufferedRoomsUpdate = roomList;
        // Compare against the displayed list each time so the count is
        // accurate even when multiple updates arrive while buffering.
        _bufferedNewCount = newCount;
      });
    } else {
      setState(() {
        _latestRooms = roomList;
        _bufferedRoomsUpdate = null;
        _bufferedNewCount = 0;
        _updateFilterData(roomList);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheRoomThumbnails(_filteredRooms.take(_loadedRoomsCount).toList());
    });
  }

  Future<void> _checkConnectivity() async {
    bool connected = false;
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 5));
      connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      connected = false;
    }

    if (!mounted) return;

    if (connected) {
      if (_isOffline) {
        setState(() {
          _isOffline = false;
          _showBackOnline = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showBackOnline = false;
          });
        });
      }
    } else {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
          _showBackOnline = false;
        });
      }
    }
  }

  Future<void> _retryConnectivity() async {
    await _checkConnectivity();
  }

  void _resetLoadedRooms() {
    setState(() {
      _loadedRoomsCount = _pageSize;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _precacheRoomThumbnails(List<Room> rooms) {
    for (var room in rooms) {
      final firstImage = room.images?.firstWhere(
        (src) => src.startsWith('http'),
        orElse: () => '',
      );
      if (firstImage == null ||
          firstImage.isEmpty ||
          _precachedThumbnails.contains(firstImage)) {
        continue;
      }
      _precachedThumbnails.add(firstImage);
      precacheImage(NetworkImage(firstImage), context).catchError((_) {});
    }
  }

  int? _parsePrice(String? s) {
    if (s == null) return null;
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  void _updatePriceControllers() {
    if (_priceRange != null) {
      _minPriceController.text = _priceRange!.start.round().toString();
      _maxPriceController.text = _priceRange!.end.round().toString();
    } else {
      _minPriceController.clear();
      _maxPriceController.clear();
    }
  }

  void _updatePriceFilterFromInputs() {
    final minText = _minPriceController.text.trim();
    final maxText = _maxPriceController.text.trim();
    final minValue = int.tryParse(minText);
    final maxValue = int.tryParse(maxText);
    if (minText.isEmpty && maxText.isEmpty) {
      setState(() {
        _priceRange = null;
        _resetLoadedRooms();
        _applyFilters();
      });
      return;
    }

    final effectiveMin = minValue ?? _minPrice;
    final effectiveMax = maxValue ?? _maxPrice;
    final clampedMin = effectiveMin.clamp(_minPrice, _maxPrice);
    final clampedMax = effectiveMax.clamp(_minPrice, _maxPrice);
    setState(() {
      _priceRange = RangeValues(
        min(clampedMin, clampedMax).toDouble(),
        max(clampedMin, clampedMax).toDouble(),
      );
      _resetLoadedRooms();
      _applyFilters();
    });
  }

  List<String> get _availableTowns {
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      return [];
    }
    return (List<String>.from(_districtTowns[_selectedDistrict] ?? []))..sort();
  }

  void _applyBufferedRooms() {
    if (_bufferedRoomsUpdate == null) return;
    setState(() {
      _latestRooms = _bufferedRoomsUpdate!;
      _bufferedRoomsUpdate = null;
      _bufferedNewCount = 0;
      _updateFilterData(_latestRooms);
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _applyAlertFilter(SavedAlert alert) {
    setState(() {
      _selectedDistrict = alert.district;
      _selectedTown = alert.town;
      _selectedCategory = alert.category;

      final minP = alert.minPrice;
      final maxP = alert.maxPrice;
      if (minP != null || maxP != null) {
        final lo = (minP ?? _minPrice).clamp(_minPrice, _maxPrice).toDouble();
        final hi = (maxP ?? _maxPrice).clamp(_minPrice, _maxPrice).toDouble();
        _priceRange = RangeValues(
          lo < hi ? lo : hi,
          lo < hi ? hi : lo,
        );
      } else {
        _priceRange = null;
      }

      _loadedRoomsCount = _pageSize;
      _applyFilters();
      _updatePriceControllers();
    });
  }

  void _applyFilters() {
    _filteredRooms = _cachedRooms.where((r) {
      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
        if (r.district != _selectedDistrict) return false;
      }
      if (_selectedTown != null && _selectedTown!.isNotEmpty) {
        if (r.town != _selectedTown) return false;
      }
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (r.category != _selectedCategory) return false;
      }
      final selectedRange = _priceRange;
      if (selectedRange != null) {
        final p = _parsePrice(r.price);
        if (p == null) return false;
        if (p < selectedRange.start.round() || p > selectedRange.end.round()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _updateFilterData(List<Room> rooms) {
    _cachedRooms = rooms.where((r) => r.status == 'approved').toList();

    _categories = [];
    _priceList = [];

    for (var r in _cachedRooms) {
      if (r.category != null && r.category!.trim().isNotEmpty) {
        _categories.add(r.category!.trim());
      }
      final p = _parsePrice(r.price);
      if (p != null) {
        _priceList.add(p);
      }
    }

    _categories = _categories.toSet().toList()..sort();

    if (_priceList.isNotEmpty) {
      _minPrice = _priceList.reduce(min);
      _maxPrice = _priceList.reduce(max);
      _effectivePriceRange = RangeValues(
        _minPrice.toDouble(),
        _maxPrice.toDouble(),
      );
      if (_priceRange != null) {
        _priceRange = RangeValues(
          _priceRange!.start.clamp(_minPrice.toDouble(), _maxPrice.toDouble()),
          _priceRange!.end.clamp(_minPrice.toDouble(), _maxPrice.toDouble()),
        );
      }
    } else {
      _minPrice = 0;
      _maxPrice = 0;
      _effectivePriceRange = null;
      _priceRange = null;
    }

    _applyFilters();
    _updatePriceControllers();
  }

  Color _themeColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.violet => const Color(0xFF7C3AED),
    AppThemeMode.light => const Color(0xFF0EA5E9),
    AppThemeMode.dark => const Color(0xFF1F2937),
  };

  Widget _themeMenuItem(String label, Color color, bool isActive) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isActive ? color : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        if (isActive) ...[const Spacer(), const Icon(Icons.check, size: 16)],
      ],
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) count++;
    if (_selectedTown != null && _selectedTown!.isNotEmpty) count++;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) count++;
    if (_priceRange != null) count++;
    return count;
  }

  void _showFilterSheet(BuildContext context, String languageCode) {
    String t(String key) => AppLocalizations.translate(languageCode, key);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (bsCtx, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          final scheme = Theme.of(bsCtx).colorScheme;
          final surfaceColor = scheme.surface;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bsCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // header row
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: scheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        t('filters'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          update(() {
                            _selectedDistrict = null;
                            _selectedTown = null;
                            _selectedCategory = null;
                            _priceRange = null;
                            _resetLoadedRooms();
                            _applyFilters();
                            _updatePriceControllers();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(t('clearFilters')),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // District + Town
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          dropdownColor: surfaceColor,
                          value:
                              (_selectedDistrict != null &&
                                  _districts.contains(_selectedDistrict))
                              ? _selectedDistrict
                              : null,
                          decoration: InputDecoration(
                            labelText: t('district'),
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          items:
                              <String>[
                                    AppLocalizations.translate(
                                      languageCode,
                                      'all',
                                    ),
                                    ..._districts,
                                  ]
                                  .map(
                                    (d) => DropdownMenuItem<String>(
                                      value:
                                          d ==
                                              AppLocalizations.translate(
                                                languageCode,
                                                'all',
                                              )
                                          ? null
                                          : d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            update(() {
                              _selectedDistrict = v;
                              _selectedTown = null;
                              _resetLoadedRooms();
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          dropdownColor: surfaceColor,
                          value:
                              (_selectedTown != null &&
                                  _availableTowns.contains(_selectedTown))
                              ? _selectedTown
                              : null,
                          decoration: InputDecoration(
                            labelText: t('town'),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          disabledHint: Text(t('selectDistrictFirst')),
                          items:
                              <String>[
                                    AppLocalizations.translate(
                                      languageCode,
                                      'all',
                                    ),
                                    ..._availableTowns,
                                  ]
                                  .map(
                                    (tn) => DropdownMenuItem<String>(
                                      value:
                                          tn ==
                                              AppLocalizations.translate(
                                                languageCode,
                                                'all',
                                              )
                                          ? null
                                          : tn,
                                      child: Text(tn),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _selectedDistrict == null
                              ? null
                              : (v) {
                                  update(() {
                                    _selectedTown = v;
                                    _resetLoadedRooms();
                                    _applyFilters();
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Category
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: surfaceColor,
                    value:
                        (_selectedCategory != null &&
                            _categories.contains(_selectedCategory))
                        ? _selectedCategory
                        : null,
                    decoration: InputDecoration(
                      labelText: t('category'),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items:
                        <String>[
                              AppLocalizations.translate(languageCode, 'all'),
                              ..._categories,
                            ]
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value:
                                    c ==
                                        AppLocalizations.translate(
                                          languageCode,
                                          'all',
                                        )
                                    ? null
                                    : c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      update(() {
                        _selectedCategory = v;
                        _resetLoadedRooms();
                        _applyFilters();
                      });
                    },
                  ),
                  // Price range
                  if (_priceList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Price Range (රු./month)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              prefixText: 'රු. ',
                            ),
                            onChanged: (_) {
                              update(() => _updatePriceFilterFromInputs());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              prefixText: 'රු. ',
                            ),
                            onChanged: (_) {
                              update(() => _updatePriceFilterFromInputs());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Save as Alert button
                  Builder(
                    builder: (_) {
                      final isLoggedIn =
                          AppState.instance.currentUser.value != null &&
                          !AppState.instance.isAnonymous;
                      final canSave = isLoggedIn && _activeFilterCount > 0;
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: Text(t('saveAsAlert')),
                          onPressed: canSave
                              ? () async {
                                  final alertName = SavedAlert.buildName(
                                    _selectedDistrict,
                                    _selectedTown,
                                    _selectedCategory,
                                    _priceRange?.start.round(),
                                    _priceRange?.end.round(),
                                  );
                                  final alert = SavedAlert(
                                    userId:
                                        AppState.instance.currentUserId ?? '',
                                    fcmToken:
                                        AppState.instance.fcmToken ?? '',
                                    district: _selectedDistrict,
                                    town: _selectedTown,
                                    category: _selectedCategory,
                                    minPrice: _priceRange?.start.round(),
                                    maxPrice: _priceRange?.end.round(),
                                    createdAt: DateTime.now(),
                                    name: alertName,
                                  );
                                  Navigator.of(bsCtx).pop();
                                  final result =
                                      await AppState.instance.saveAlert(alert);
                                  if (!context.mounted) return;

                                  if (result == AlertSaveResult.savedWithNotifications) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(t('alertSaved'))),
                                    );
                                  } else if (result == AlertSaveResult.savedWithoutNotifications) {
                                    showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: Text('Notification permission required'),
                                          content: const Text(
                                            'Alert saved, but notification permission is disabled. Open app settings to enable notifications and receive alert pushes.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop();
                                                openAppSettings();
                                              },
                                              child: const Text('Settings'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save alert')),
                                    );
                                  }
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                canSave ? null : Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(bsCtx).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return ValueListenableBuilder<String>(
      valueListenable: app.languageCode,
      builder: (context, languageCode, child) {
        String t(String key) => AppLocalizations.translate(languageCode, key);
        final grad = Theme.of(context).extension<AppGradients>()!;
        final currentMode = AppState.instance.themeMode.value;
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _showGoToTop
              ? FloatingActionButton(
                  onPressed: _scrollToTop,
                  tooltip: 'Go to top',
                  child: const Icon(Icons.arrow_upward),
                )
              : null,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home_work, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'බෝඩිම්.lk',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: grad.barBackground,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              // Theme switcher — single dot opens dropdown
              PopupMenuButton<AppThemeMode>(
                tooltip: 'Theme',
                offset: const Offset(0, 44),
                onSelected: (mode) => AppState.instance.setThemeMode(mode),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: AppThemeMode.violet,
                    child: _themeMenuItem(
                      'Violet',
                      const Color(0xFF7C3AED),
                      currentMode == AppThemeMode.violet,
                    ),
                  ),
                  PopupMenuItem(
                    value: AppThemeMode.light,
                    child: _themeMenuItem(
                      'Light',
                      const Color(0xFF0EA5E9),
                      currentMode == AppThemeMode.light,
                    ),
                  ),
                  PopupMenuItem(
                    value: AppThemeMode.dark,
                    child: _themeMenuItem(
                      'Dark',
                      const Color(0xFF1F2937),
                      currentMode == AppThemeMode.dark,
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _themeColor(currentMode),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor(
                            currentMode,
                          ).withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Filter button with active-count badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: t('filters'),
                    onPressed: () => _showFilterSheet(context, languageCode),
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Language selector (icon)
              PopupMenuButton<String>(
                tooltip: t('language'),
                icon: Text(
                  languageCode == 'si'
                      ? 'සිං'
                      : languageCode == 'ta'
                      ? 'த'
                      : 'En',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onSelected: (value) => AppState.instance.setLanguageCode(value),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'en', child: Text(t('english'))),
                  const PopupMenuItem(value: 'si', child: Text('සිංහල')),
                  const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
                ],
              ),
              IconButton(
                onPressed: () async {
                  if (AppState.instance.currentUser.value == null) {
                    final signed = await AppState.instance.signInAnonymously();
                    if (!signed) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('unableStartAnonymous'))),
                      );
                      return;
                    }
                  }
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddPostPage()),
                  );
                },
                icon: const Icon(Icons.create),
                tooltip: t('createAd'),
                color: Colors.white,
              ),
              ValueListenableBuilder(
                valueListenable: app.currentUser,
                builder: (context, user, child) {
                  if (user == null || app.isAnonymous) {
                    return IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      icon: const Icon(Icons.login),
                      tooltip: t('login'),
                      color: Colors.white,
                    );
                  } else {
                    return ValueListenableBuilder<List<Room>>(
                      valueListenable: app.rooms,
                      builder: (context, rooms, _) {
                        final pendingCount = rooms
                            .where((room) => room.status == 'pending')
                            .length;
                        return PopupMenuButton<int>(
                          onSelected: (v) {
                            if (v == 10) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddPostPage(),
                                ),
                              );
                            } else if (v == 1) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyAdsPage(),
                                ),
                              );
                            } else if (v == 8) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MyAlertsPage(
                                    onApplyAlert: (alert) {
                                      Navigator.of(context).pop();
                                      _applyAlertFilter(alert);
                                    },
                                  ),
                                ),
                              );
                            } else if (v == 2) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                            } else if (v == 3) {
                              app.logout();
                            } else if (v == 4) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PendingAdsPage(),
                                ),
                              );
                            } else if (v == 5) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RejectReasonsPage(),
                                ),
                              );
                            } else if (v == 6) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CategoriesPage(),
                                ),
                              );
                            } else if (v == 7) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ContactUsPage(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user.email.isNotEmpty ? user.email : ''),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t('createAd'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(value: 1, child: Text(t('myAds'))),
                            PopupMenuItem(
                              value: 8,
                              child: Text(t('myAlerts')),
                            ),
                            PopupMenuItem(value: 2, child: Text(t('profile'))),
                            if (user.isAdmin) ...[
                              PopupMenuItem(
                                value: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t('pendingAds')),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$pendingCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 5,
                                child: Text(t('rejectReasons')),
                              ),
                              PopupMenuItem(
                                value: 6,
                                child: Text(t('categories')),
                              ),
                            ],
                            PopupMenuItem(
                              value: 7,
                              child: Text(t('contactUs')),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('logout'),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(Icons.person, color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),

          // body: add location filter above the list
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [grad.bodyStart, grad.bodyEnd],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Stack(
              children: [
                ValueListenableBuilder<List>(
                  valueListenable: app.rooms,
                  builder: (context, rooms, child) {
                    final filtered = _filteredRooms;
                    final isLoadingRooms = AppState.instance.roomsLoading.value;

                    return Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: AppState.instance.updateAvailable,
                          builder: (context, available, _) {
                            if (!available) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.all(12),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.orange.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.system_update,
                                        color: Colors.orange.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'A new version is available!',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final url =
                                              AppState.instance.updateUrl.value;
                                          if (url != null) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Update'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_isOffline || _showBackOnline)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: _isOffline
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isOffline ? Icons.wifi_off : Icons.wifi,
                                      color: _isOffline
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isOffline
                                            ? 'You\'re offline — check your connection'
                                            : 'Back online!',
                                        style: TextStyle(
                                          color: _isOffline
                                              ? Colors.red.shade800
                                              : Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_isOffline)
                                      TextButton(
                                        onPressed: _retryConnectivity,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Active filter chips
                        if (_activeFilterCount > 0)
                          Container(
                            color: Colors.black26,
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_selectedDistrict != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Chip(
                                        label: Text(_selectedDistrict!),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                        onDeleted: () => setState(() {
                                          _selectedDistrict = null;
                                          _selectedTown = null;
                                          _resetLoadedRooms();
                                          _applyFilters();
                                        }),
                                      ),
                                    ),
                                  if (_selectedTown != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Chip(
                                        label: Text(_selectedTown!),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                        onDeleted: () => setState(() {
                                          _selectedTown = null;
                                          _resetLoadedRooms();
                                          _applyFilters();
                                        }),
                                      ),
                                    ),
                                  if (_selectedCategory != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Chip(
                                        label: Text(_selectedCategory!),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                        onDeleted: () => setState(() {
                                          _selectedCategory = null;
                                          _resetLoadedRooms();
                                          _applyFilters();
                                        }),
                                      ),
                                    ),
                                  if (_priceRange != null)
                                    Chip(
                                      label: Text(
                                        'රු.${_priceRange!.start.round()}–${_priceRange!.end.round()}',
                                      ),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 16,
                                      ),
                                      onDeleted: () => setState(() {
                                        _priceRange = null;
                                        _resetLoadedRooms();
                                        _applyFilters();
                                        _updatePriceControllers();
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              isLoadingRooms
                              ? const Center(child: CircularProgressIndicator())
                              : filtered.isEmpty
                              ? Center(
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin: const EdgeInsets.all(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 80,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'No rooms found',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            t('noListingsMessage'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _selectedDistrict = null;
                                                _selectedTown = null;
                                                _selectedCategory = null;
                                                _priceRange = null;
                                                _resetLoadedRooms();
                                                _applyFilters();
                                              });
                                            },
                                            icon: const Icon(Icons.refresh),
                                            label: Text(t('clearFilters')),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics.pixels >=
                                            notification
                                                    .metrics
                                                    .maxScrollExtent -
                                                200 &&
                                        _loadedRoomsCount < filtered.length) {
                                      setState(() {
                                        _loadedRoomsCount = min(
                                          filtered.length,
                                          _loadedRoomsCount + _pageSize,
                                        );
                                      });
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    itemCount:
                                        min(
                                          filtered.length,
                                          _loadedRoomsCount,
                                        ) +
                                        (filtered.length > _loadedRoomsCount
                                            ? 1
                                            : 0),
                                    itemBuilder: (context, index) {
                                      if (index >=
                                          min(
                                            filtered.length,
                                            _loadedRoomsCount,
                                          )) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: RoomCard(
                                          room: filtered[index],
                                          hideTitle: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              if (_bufferedNewCount > 0)
                                Positioned(
                                  top: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: _applyBufferedRooms,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.92),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.arrow_upward,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$_bufferedNewCount new listing'
                                              '${_bufferedNewCount == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                ValueListenableBuilder<bool>(
                  valueListenable: AppState.instance.forceUpdateRequired,
                  builder: (context, forceUpdate, _) {
                    if (!forceUpdate) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: GestureDetector(
                        onTap: () {},
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Colors.white.withOpacity(0.95),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.system_update,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Update Required',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'A mandatory update is available. You must update the app before continuing.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final url =
                                          AppState.instance.updateUrl.value;
                                      if (url != null) {
                                        await launchUrl(
                                          Uri.parse(url),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Update Now'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
