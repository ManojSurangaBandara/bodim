import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/pressable_scale.dart';

import '../models/room.dart';
import '../services/app_state.dart';

class AddPostPage extends StatefulWidget {
  final Room? roomToEdit;
  const AddPostPage({super.key, this.roomToEdit});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _titleCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _contactCtl = TextEditingController();
  final List<String> _localImagePaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _selectedDistrict;
  String? _selectedTown;

  @override
  void initState() {
    super.initState();
    if (widget.roomToEdit != null) {
      final room = widget.roomToEdit!;
      _titleCtl.text = room.title;
      _priceCtl.text = room.price;
      _descCtl.text = room.description ?? '';
      _contactCtl.text = room.contact ?? '';
      _localImagePaths.addAll(room.images ?? []);
      _selectedDistrict = room.district;
      _selectedTown = room.town;
    }
  }

  static const Map<String, List<String>> _districtTowns = {
    'Colombo': [
      'Nugegoda',
      'Maharagama',
      'Piliyandala',
      'Colombo 3',
      'Dehiwala',
      'Boralesgamuwa',
      'Kottawa',
      'Battaramulla',
      'Homagama',
      'Athurugiriya',
      'Moratuwa',
      'Colombo 6',
      'Rajagiriya',
      'Malabe',
      'Talawatugoda',
      'Colombo 4',
      'Pannipitiya',
      'Kaduwela',
      'Wellampitiya',
      'Ratmalana',
      'Colombo 5',
      'Kotte',
      'Mount Lavinia',
      'Colombo 10',
      'Kohuwala',
      'Colombo 8',
      'Angoda',
      'Colombo 12',
      'Colombo 2',
      'Colombo 13',
      'Avissawella',
      'Colombo 11',
      'Kolonnawa',
      'Nawala',
      'Colombo 9',
      'Colombo 7',
      'Meegoda',
      'Colombo 15',
      'Kesbewa',
      'Colombo 14',
      'Hanwella',
      'Padukka',
      'Godagama',
      'Colombo 1',
      'Polgasowita',
      'Kalubowila',
      'Kotikawatta',
      'Ranala',
      'Nawagamuwa',
      'Olaboduwa',
      'Embulgama',
    ],
    'Gampaha': [
      'Gampaha City',
      'Negombo',
      'Kadawatha',
      'Kiribathgoda',
      'Wattala',
      'Ja-Ela',
      'Kelaniya',
      'Nittambuwa',
      'Minuwangoda',
      'Kandana',
      'Ragama',
      'Delgoda',
      'Katunayake',
      'Veyangoda',
      'Seeduwa',
      'Ganemulla',
      'Mirigama',
      'Divulapitiya',
      'Biyagama',
      'Kalagedihena',
      'Kirindiwela',
      'Peliyagoda',
      'Dompe',
      'Miriswatta',
      'Bopitiya',
      'Pugoda',
      'Gonawala',
      'Mawaramandiya',
      'Walikatiya',
      'Delathura',
      'Nilsirigama',
    ],
    'Kalutara': [
      'Panadura',
      'Horana',
      'Kalutara City',
      'Bandaragama',
      'Alutgama',
      'Matugama',
      'Wadduwa',
      'Beruwala',
      'Ingiriya',
      'Gonapola',
      'Talagala',
      'Awittawa',
      'Ittapane',
      'Pitipana',
      'Meegahathenna',
      'Kevitiyagala',
      'Moragala',
      'Walallavita',
      'Polgampola',
      'Uthumgama',
    ],
    'Kandy': [
      'Kandy City',
      'Gampola',
      'Katugastota',
      'Akurana',
      'Peradeniya',
      'Pilimatalawa',
      'Digana',
      'Kundasale',
      'Nawalapitiya',
      'Gelioya',
      'Galagedara',
      'Kadugannawa',
      'Ampitiya',
      'Madawala Bazaar',
      'Wattegama',
      'Pussellawa',
      'Menikhinna',
      'Galaha',
      'Danthure',
      'Deltota',
      'Pallekele',
      'Udunuwara',
      'Urapola',
      'Doluwa',
      'Dodamwala',
      'Poththapitiya',
      'Pathahewaheta',
      'Rattapitiya',
      'Tawalantenne',
    ],
    'Matale': [
      'Matale',
      'Dambulla',
      'Sigiriya',
      'Galewela',
      'Ukuwela',
      'Rattota',
      'Yatawatta',
      'Pallepola',
      'Naula',
      'Laggala-Pallegama',
    ],
    'Nuwara Eliya': [
      'Nuwara Eliya',
      'Hatton',
      'Talawakele',
      'Ginigathena',
      'Walapane',
      'Madulla',
      'Kundasale',
      'Hanguranketha',
      'Nuwara Eliya-Maskeliya',
      'Kotagala',
      'Ramboda',
      'Ambewela',
      'Pundaluoya',
      'Haputale',
      'Welimada',
    ],
    'Galle': [
      'Galle',
      'Hikkaduwa',
      'Ambalangoda',
      'Elpitiya',
      'Bentota',
      'Baddegama',
      'Balapitiya',
      'Ahangama',
      'Urubokka',
      'Nagoda',
      'Neluwa',
      'Udugama',
      'Imaduwa',
      'Habaraduwa',
      'Karandeniya',
    ],
    'Matara': [
      'Matara',
      'Weligama',
      'Akuressa',
      'Hakmana',
      'Kamburupitiya',
      'Dickwella',
      'Deniyaya',
      'Devinuwara',
      'Kekanadura',
      'Pitabeddara',
      'Thihagoda',
      'Malimbada',
      'Pasgoda',
      'Mulatiyana',
      'Welihinda',
    ],
    'Hambantota': [
      'Hambantota',
      'Tangalle',
      'Beliatta',
      'Tissamaharama',
      'Kataragama',
      'Ambalantota',
      'Weeraketiya',
      'Angunakolapelessa',
      'Hambantota',
      'Lunugamvehera',
      'Okewela',
      'Walasmulla',
      'Sooriyawewa',
      'Middeniya',
      'Rajagalatenna',
    ],
    'Jaffna': [
      'Jaffna',
      'Chavakachcheri',
      'Point Pedro',
      'Valvettithurai',
      'Karainagar',
      'Kayts',
      'Nallur',
      'Tellippalai',
      'Uduvil',
      'Chankanai',
      'Sandilipay',
      'Maruthankerny',
      'Velanai',
      'Delft',
      'Kopay',
    ],
    'Kilinochchi': [
      'Kilinochchi',
      'Poonakary',
      'Paranthan',
      'Mullaitivu',
      'Mankulam',
      'Vavuniya',
      'Mannar',
      'Mulliyawalai',
      'Oddusuddan',
      'Madhu',
      'Nanattan',
      'Murunkan',
      'Adampan',
      'Puthukkudiyiruppu',
      'Iranamadu',
    ],
    'Mannar': [
      'Mannar',
      'Vankalai',
      'Pesalai',
      'Madhu',
      'Nanattan',
      'Murunkan',
      'Adampan',
      'Puthukkudiyiruppu',
      'Iranamadu',
      'Talaimannar',
      'Erukkalampiddy',
      'Sillalai',
      'Uttukulam',
      'Marichchikaddi',
      'Kallikulam',
    ],
    'Vavuniya': [
      'Vavuniya',
      'Cheddikulam',
      'Nedunkeni',
      'Mullaitivu',
      'Mannar',
      'Kilinochchi',
      'Anuradhapura',
      'Trincomalee',
      'Batticaloa',
      'Ampara',
      'Polonnaruwa',
      'Kurunegala',
      'Puttalam',
      'Matale',
      'Nuwara Eliya',
    ],
    'Mullaitivu': [
      'Mullaitivu',
      'Kilinochchi',
      'Mannar',
      'Vavuniya',
      'Oddusuddan',
      'Puthukkudiyiruppu',
      'Mankulam',
      'Maritimepattu',
      'Thunukkai',
      'Poonakary',
      'Paranthan',
      'Mulliyawalai',
      'Nanattan',
      'Madhu',
      'Iranamadu',
    ],
    'Batticaloa': [
      'Batticaloa',
      'Eravur',
      'Valachchenai',
      'Kattankudy',
      'Oddamavadi',
      'Kalmunai',
      'Sainthamaruthu',
      'Pottuvil',
      'Arayampathy',
      'Chenkalady',
      'Vakarai',
      'Manmunai',
      'Porativu',
      'Kiran',
      'Koralai Pattu',
    ],
    'Ampara': [
      'Ampara',
      'Akkaraipattu',
      'Kalmunai',
      'Sainthamaruthu',
      'Pottuvil',
      'Uhana',
      'Maha Oya',
      'Navithanveli',
      'Lahugala',
      'Dehiattakandiya',
      'Sammanthurai',
      'Irakkamam',
      'Addalachchenai',
      'Alayadiwembu',
      'Damana',
    ],
    'Trincomalee': [
      'Trincomalee',
      'Kinniya',
      'Muttur',
      'Kuchchaveli',
      'Seruvila',
      'Thampalakamam',
      'Gomarankadawala',
      'Padavi Sri Pura',
      'Kantalai',
      'Moratuwa',
      'Verugal',
      'Eachchilampattu',
      'Nilaveli',
      'Pulmoddai',
      'Sampur',
    ],
    'Kurunegala': [
      'Kurunegala',
      'Kuliyapitiya',
      'Narammala',
      'Polgahawela',
      'Wariyapola',
      'Pannala',
      'Alawwa',
      'Mawathagama',
      'Nikaweratiya',
      'Ibbagamuwa',
      'Ganewatta',
      'Pothuhera',
      'Katugampola',
      'Bingiriya',
      'Dambadeniya',
    ],
    'Puttalam': [
      'Puttalam',
      'Chilaw',
      'Wennappuwa',
      'Marawila',
      'Dankotuwa',
      'Nattandiya',
      'Anamaduwa',
      'Kalpitiya',
      'Arachchikattuwa',
      'Madampe',
      'Vanathavilluwa',
      'Nawagattegama',
      'Pallama',
      'Lunuwila',
      'Mundalama',
    ],
    'Anuradhapura': [
      'Anuradhapura',
      'Kekirawa',
      'Medawachchiya',
      'Tambuttegama',
      'Mihintale',
      'Nochchiyagama',
      'Galnewa',
      'Rambewa',
      'Thalawa',
      'Rajanganaya',
      'Horowpothana',
      'Ipalogama',
      'Palagala',
      'Kahatagasdigiliya',
      'Nachchadoowa',
    ],
    'Polonnaruwa': [
      'Polonnaruwa',
      'Kaduruwela',
      'Hingurakgoda',
      'Medirigiriya',
      'Dimbulagala',
      'Elahera',
      'Lankapura',
      'Welikanda',
      'Aralaganwila',
      'Manampitiya',
      'Giritale',
      'Thamankaduwa',
      'Bakamuna',
      'Dehiattakandiya',
      'Jayantipura',
    ],
    'Badulla': [
      'Badulla',
      'Bandarawela',
      'Haputale',
      'Welimada',
      'Mahiyanganaya',
      'Rideegama',
      'Girandurukotte',
      'Hali-Ela',
      'Uva-Paranagama',
      'Kandaketiya',
      'Ella',
      'Passara',
      'Lunugala',
      'Sorabora',
      'Madulsima',
    ],
    'Moneragala': [
      'Moneragala',
      'Wellawaya',
      'Bibile',
      'Kataragama',
      'Buttala',
      'Siyambalanduwa',
      'Medagama',
      'Thanamalvila',
      'Sevanagala',
      'Badalkumbura',
      'Dambagalla',
      'Pitabeddara',
      'Okkampitiya',
      'Nakkala',
      'Hulandawa',
    ],
    'Ratnapura': [
      'Ratnapura',
      'Embilipitiya',
      'Balangoda',
      'Pelmadulla',
      'Eheliyagoda',
      'Kuruwita',
      'Kiriella',
      'Opanayaka',
      'Nivithigala',
      'Ayagama',
      'Kalawana',
      'Imbulpe',
      'Godakawela',
      'Kahawatta',
      'Weligepola',
    ],
    'Kegalle': [
      'Kegalle',
      'Mawanella',
      'Warakapola',
      'Rambukkana',
      'Galigamuwa',
      'Yatiyanthota',
      'Deraniyagala',
      'Bulathkohupitiya',
      'Aranayaka',
      'Kitulgala',
      'Hemmathagama',
      'Dehiovita',
      'Ruwanwella',
      'Weligalla',
      'Udapotha',
    ],
  };

  static const double _imageMaxWidth = 800.0;
  static const double _imageMaxHeight = 800.0;
  static const int _imageQuality = 70;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: _imageMaxWidth,
      maxHeight: _imageMaxHeight,
      imageQuality: _imageQuality,
    );
    if (picked.isEmpty) return;

    for (final p in picked) {
      _localImagePaths.add(p.path);
    }
    setState(() {});
  }

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _imageMaxWidth,
      maxHeight: _imageMaxHeight,
      imageQuality: _imageQuality,
    );
    if (picked == null) return;

    _localImagePaths.add(picked.path);
    setState(() {});
  }

  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<File> _compressImageFile(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}-${file.path.split(Platform.pathSeparator).last}';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50,
        minWidth: 720,
        minHeight: 720,
        keepExif: false,
      );
      if (compressedFile == null) return file;
      return File((compressedFile as dynamic).path);
    } catch (e, st) {
      debugPrint('Image compression failed, using original file: $e\n$st');
      return file;
    }
  }

  Future<String?> _uploadLocalImage(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final uploadFile = await _compressImageFile(file);
    final filename = 'rooms/${DateTime.now().millisecondsSinceEpoch}-${uploadFile.path.split(Platform.pathSeparator).last}';
    final ref = FirebaseStorage.instance.ref(filename);
    await ref.putFile(uploadFile).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException('Image upload timed out'),
    );
    return await ref.getDownloadURL().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Failed to get image URL'),
    );
  }

  Future<List<String>> _resolveImageUrls() async {
    final uploadPaths = <String>[];
    for (final path in _localImagePaths) {
      if (path.startsWith('http')) {
        uploadPaths.add(path);
        continue;
      }
      final url = await _uploadLocalImage(path);
      if (url != null) {
        uploadPaths.add(url);
      }
    }
    return uploadPaths;
  }

  Future<void> _submit() async {
    final t = _titleCtl.text.trim();
    final p = _priceCtl.text.trim();
    final c = _contactCtl.text.trim();
    if (t.isEmpty ||
        p.isEmpty ||
        c.isEmpty ||
        _selectedDistrict == null ||
        _selectedTown == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final currentUser = AppState.instance.currentUser.value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a post')),
      );
      return;
    }

    final hasNetwork = await _hasNetworkConnection();
    if (!hasNetwork) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please try again when you are online.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    late final List<String> imageUrls;
    try {
      imageUrls = await _resolveImageUrls();
    } catch (e, st) {
      debugPrint('Image upload failed: $e\n$st');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to upload images. Check your connection and try again.'),
        ),
      );
      return;
    }

    final newRoom = Room(
      title: t,
      price: p,
      contact: c,
      creatorEmail: currentUser.email,
      createdAt: widget.roomToEdit?.createdAt ?? DateTime.now(),
      images: imageUrls.isNotEmpty ? imageUrls : null,
      description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      district: _selectedDistrict,
      town: _selectedTown,
      status: 'pending',
      id: widget.roomToEdit?.id,
    );

    final success = widget.roomToEdit != null
        ? await AppState.instance.updateRoom(widget.roomToEdit!, newRoom)
        : await AppState.instance.addRoom(newRoom);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the ad. Please check your internet connection and try again.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _priceCtl.dispose();
    _contactCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomToEdit == null ? 'Add Bodim' : 'Edit Bodim'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            stops: [0.0, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.roomToEdit?.status == 'rejected' && widget.roomToEdit?.rejectionReason != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14.0),
                          margin: const EdgeInsets.only(bottom: 14.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejected reason',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.roomToEdit!.rejectionReason!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please update the ad and submit again.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _titleCtl,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _priceCtl,
                        decoration: const InputDecoration(
                          labelText: 'Price (LKR)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contactCtl,
                        decoration: const InputDecoration(
                          labelText: 'Contact number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                        ),
                        items: _districtTowns.keys
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedDistrict = v;
                            _selectedTown = null; // reset town when district changes
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedTown,
                        decoration: const InputDecoration(
                          labelText: 'Town',
                          border: OutlineInputBorder(),
                        ),
                        items: _selectedDistrict != null
                            ? _districtTowns[_selectedDistrict]!
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                  .toList()
                            : [],
                        onChanged: _selectedDistrict == null
                            ? null
                            : (v) => setState(() => _selectedTown = v),
                      ),
                      const SizedBox(height: 12),
                      if (_localImagePaths.isNotEmpty)
                        SizedBox(
                          height: 160,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = _localImagePaths.removeAt(oldIndex);
                                _localImagePaths.insert(newIndex, item);
                              });
                            },
                            itemCount: _localImagePaths.length,
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, i) {
                              final p = _localImagePaths[i];
                              final imageWidget = p.startsWith('http')
                                  ? Image.network(
                                      p,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          child: const Center(child: Icon(Icons.broken_image)),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(p),
                                      fit: BoxFit.cover,
                                      cacheWidth: 400,
                                      cacheHeight: 400,
                                    );
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey('$p-$i'),
                                index: i,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 140,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(child: imageWidget),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor:
                                                Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              icon: const Icon(Icons.close),
                                              onPressed: () => setState(() => _localImagePaths.removeAt(i)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          PressableScale(
                            child: ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          PressableScale(
                            child: ElevatedButton.icon(
                              onPressed: _captureImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                          if (_localImagePaths.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() => _localImagePaths.clear()),
                              child: const Text('Remove all'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: PressableScale(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(widget.roomToEdit == null ? 'Post' : 'Update'),
                          ),
                        ),
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
