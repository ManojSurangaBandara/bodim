import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import '../widgets/pressable_scale.dart';
import 'login_page.dart';
import 'add_post_page.dart';
import 'my_ads_page.dart';
import 'pending_ads_page.dart';
import 'reject_reasons_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedDistrict;
  String? _selectedTown;
  RangeValues? _priceRange;
  bool _isOffline = false;
  bool _showBackOnline = false;
  bool _filtersExpanded = true;
  final int _pageSize = 10;
  int _loadedRoomsCount = 10;
  Timer? _connectivityTimer;

  List<Room> _latestRooms = [];
  List<Room> _cachedRooms = [];
  List<String> _districts = [];
  List<String> _towns = [];
  List<Room> _filteredRooms = [];
  List<int> _priceList = [];
  int _minPrice = 0;
  int _maxPrice = 0;
  RangeValues? _effectivePriceRange;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _checkConnectivity(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool connected = false;
    try {
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
      );
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

  int? _parsePrice(String? s) {
    if (s == null) return null;
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  void _applyFilters() {
    _filteredRooms = _cachedRooms.where((r) {
      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
        if (r.district != _selectedDistrict) return false;
      }
      if (_selectedTown != null && _selectedTown!.isNotEmpty) {
        if (r.town != _selectedTown) return false;
      }
      if (_effectivePriceRange != null) {
        final p = _parsePrice(r.price);
        if (p == null) return false;
        if (p < _effectivePriceRange!.start.round() || p > _effectivePriceRange!.end.round()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _updateFilterData(List<Room> rooms) {
    _cachedRooms = rooms.where((r) => r.status == 'approved').toList();

    final districts = <String>{};
    final towns = <String>{};
    _priceList = [];

    for (var r in _cachedRooms) {
      if (r.district != null && r.district!.trim().isNotEmpty) {
        districts.add(r.district!);
      }
      if (r.town != null && r.town!.trim().isNotEmpty) {
        towns.add(r.town!);
      }
      final p = _parsePrice(r.price);
      if (p != null) {
        _priceList.add(p);
      }
    }

    _districts = districts.toList()..sort();
    _towns = towns.toList()..sort();

    if (_priceList.isNotEmpty) {
      _minPrice = _priceList.reduce(min);
      _maxPrice = _priceList.reduce(max);
      if (_effectivePriceRange == null) {
        _effectivePriceRange = RangeValues(_minPrice.toDouble(), _maxPrice.toDouble());
      } else {
        _effectivePriceRange = RangeValues(
          _effectivePriceRange!.start.clamp(_minPrice.toDouble(), _maxPrice.toDouble()),
          _effectivePriceRange!.end.clamp(_minPrice.toDouble(), _maxPrice.toDouble()),
        );
      }
    } else {
      _minPrice = 0;
      _maxPrice = 0;
      _effectivePriceRange = null;
    }

    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.home_work,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'බෝඩිම්.lk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [

          ValueListenableBuilder(
            valueListenable: app.currentUser,
            builder: (context, user, child) {
              if (user == null) {
                return TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              } else {
                return PopupMenuButton<int>(
                  onSelected: (v) {
                    if (v == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyAdsPage()),
                      );
                    } else if (v == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    } else if (v == 3) {
                      app.logout();
                    } else if (v == 4) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PendingAdsPage()),
                      );
                    } else if (v == 5) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RejectReasonsPage()),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(user.email),
                        ],
                      ),
                    ),
                    const PopupMenuItem(value: 1, child: Text('My Ads')),
                    const PopupMenuItem(value: 2, child: Text('Profile')),
                    if (user.isAdmin) ...[
                      const PopupMenuItem(value: 4, child: Text('Pending Ads')),
                      const PopupMenuItem(value: 5, child: Text('Reject Reasons')),
                    ],
                    const PopupMenuItem(value: 3, child: Text('Logout')),
                  ],
                  icon: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }
            },
          ),
        ],
      ),

      // body: add location filter above the list
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ValueListenableBuilder<List>(
              valueListenable: app.rooms,
              builder: (context, rooms, child) {
                final roomList = rooms.cast<Room>();
                if (!identical(roomList, _latestRooms)) {
                  _latestRooms = roomList;
                  _updateFilterData(roomList);
                }

                final filtered = _filteredRooms;
                final districts = _districts;
                final towns = _towns;
                final effectivePriceRange = _effectivePriceRange;

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
                                      final url = AppState.instance.updateUrl.value;
                                      if (url != null) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: _isOffline ? Colors.red.shade50 : Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  _isOffline ? Icons.wifi_off : Icons.wifi,
                                  color: _isOffline ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isOffline ? 'You\'re offline — check your connection' : 'Back online!',
                                    style: TextStyle(
                                      color: _isOffline ? Colors.red.shade800 : Colors.green.shade800,
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
                    // Modern filter card
                    Card(
                      margin: const EdgeInsets.all(12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _filtersExpanded = !_filtersExpanded;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Clear filters',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDistrict = null;
                                        _selectedTown = null;
                                        _priceRange = null;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    tooltip: _filtersExpanded ? 'Collapse filters' : 'Expand filters',
                                    icon: Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more),
                                    onPressed: () {
                                      setState(() {
                                        _filtersExpanded = !_filtersExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _filtersExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  isExpanded: true,
                                                  value:
                                                      (_selectedDistrict != null &&
                                                          districts.contains(_selectedDistrict))
                                                      ? _selectedDistrict
                                                      : null,
                                                  decoration: InputDecoration(
                                                    labelText: 'District',
                                                    prefixIcon: const Icon(Icons.location_city),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  items: ['All', ...districts]
                                                      .map(
                                                        (d) => DropdownMenuItem(
                                                          value: d == 'All' ? null : d,
                                                          child: Text(d),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (v) {
                                                    setState(() {
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
                                                  value:
                                                      (_selectedTown != null &&
                                                          towns.contains(_selectedTown))
                                                      ? _selectedTown
                                                      : null,
                                                  decoration: InputDecoration(
                                                    labelText: 'Town',
                                                    prefixIcon: const Icon(Icons.location_on),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  items: ['All', ...towns]
                                                      .map(
                                                        (t) => DropdownMenuItem(
                                                          value: t == 'All' ? null : t,
                                                          child: Text(t),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _selectedTown = v;
                                                      _resetLoadedRooms();
                                                      _applyFilters();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Price filter (RangeSlider) — visible only when numeric prices exist
                                          if (_priceList.isNotEmpty) ...[
                                            const SizedBox(height: 20),
                                            Text(
                                              'Price Range (රු./month)',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            RangeSlider(
                                              values: effectivePriceRange!,
                                              min: _minPrice.toDouble(),
                                              max: _maxPrice.toDouble(),
                                              labels: RangeLabels(
                                                'රු. ${effectivePriceRange.start.round()}',
                                                'රු. ${effectivePriceRange.end.round()}',
                                              ),
                                              onChanged: (v) {
                                                setState(() {
                                                  _priceRange = v;
                                                  _resetLoadedRooms();
                                                  _applyFilters();
                                                });
                                              },
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Min: රු. ${effectivePriceRange.start.round()}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                Text(
                                                  'Max: රු. ${effectivePriceRange.end.round()}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
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
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'No rooms found',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your filters or check back later for new listings.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                            _priceRange = null;
                                            _resetLoadedRooms();
                                            _applyFilters();
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Clear Filters'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
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
                                        notification.metrics.maxScrollExtent -
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                itemCount: min(filtered.length, _loadedRoomsCount) +
                                    (filtered.length > _loadedRoomsCount ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= min(filtered.length, _loadedRoomsCount)) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: RoomCard(room: filtered[index]),
                                  );
                                },
                              ),
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
                  child: AbsorbPointer(
                    absorbing: true,
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Update Required',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A mandatory update is available. You must update the app before continuing.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final url = AppState.instance.updateUrl.value;
                                  if (url != null) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

            ValueListenableBuilder<bool>(
              valueListenable: AppState.instance.forceUpdateRequired,
              builder: (context, forceUpdate, _) {
                if (!forceUpdate) return const SizedBox.shrink();
                return Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Update Required',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A mandatory update is available. You must update the app before continuing.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final url = AppState.instance.updateUrl.value;
                                  if (url != null) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

      floatingActionButton: ValueListenableBuilder(
        valueListenable: app.currentUser,
        builder: (context, user, child) {
          if (user == null) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PressableScale(
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPostPage()),
                ),
                tooltip: 'Add New Room Listing',
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Bodim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
