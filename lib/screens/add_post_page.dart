import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/room.dart';
import '../services/app_state.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

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
  String? _selectedDistrict;
  String? _selectedTown;

  static const Map<String, List<String>> _districtTowns = {
    'Colombo': [
      'Colombo 1',
      'Colombo 2',
      'Colombo 3',
      'Colombo 4',
      'Colombo 5',
      'Colombo 6',
      'Colombo 7',
      'Colombo 8',
      'Colombo 9',
      'Colombo 10',
      'Colombo 11',
      'Colombo 12',
      'Colombo 13',
      'Colombo 14',
      'Colombo 15',
    ],
    'Gampaha': [
      'Negombo',
      'Gampaha',
      'Veyangoda',
      'Minuwangoda',
      'Wattala',
      'Ja-Ela',
      'Katunayake',
      'Divulapitiya',
      'Nittambuwa',
      'Kiribathgoda',
      'Kelaniya',
      'Kadawatha',
      'Mahara',
      'Dompe',
      'Attanagalla',
    ],
    'Kalutara': [
      'Kalutara',
      'Panadura',
      'Horana',
      'Beruwala',
      'Alutgama',
      'Matugama',
      'Wadduwa',
      'Bandaragama',
      'Ingiriya',
      'Bulathsinhala',
      'Millaniya',
      'Dodanduwa',
      'Palindanuwara',
      'Walallawita',
    ],
    'Kandy': [
      'Kandy',
      'Gampola',
      'Nawalapitiya',
      'Warakapola',
      'Kadugannawa',
      'Galagedara',
      'Harispattuwa',
      'Pilimatalawa',
      'Akurana',
      'Yatinuwara',
      'Udunuwara',
      'Pathadumbara',
      'Udadumbara',
      'Doluwa',
      'Hatharaliyadda',
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

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;

    final appDir = await getApplicationDocumentsDirectory();
    for (final p in picked) {
      final filename = '${DateTime.now().millisecondsSinceEpoch}-${p.name}';
      final saved = await File(p.path).copy('${appDir.path}/$filename');
      _localImagePaths.add(saved.path);
    }
    setState(() {});
  }

  void _submit() {
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
    AppState.instance.addRoom(
      Room(
        title: t,
        price: p,
        contact: c,
        creatorEmail: AppState.instance.currentUser.value!.email,
        createdAt: DateTime.now(),
        images: _localImagePaths.isNotEmpty
            ? List.from(_localImagePaths)
            : null,
        description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
        district: _selectedDistrict,
        town: _selectedTown,
      ),
    );
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
      appBar: AppBar(title: const Text('Add Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtl,
              decoration: const InputDecoration(labelText: 'Price (LKR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtl,
              decoration: const InputDecoration(labelText: 'Contact number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'District'),
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
              decoration: const InputDecoration(labelText: 'Town'),
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
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _localImagePaths.length,
                  itemBuilder: (context, i) {
                    final p = _localImagePaths[i];
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(File(p), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              color: Colors.white,
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _localImagePaths.removeAt(i)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Images'),
                ),
                const SizedBox(width: 12),
                if (_localImagePaths.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _localImagePaths.clear()),
                    child: const Text('Remove all'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text('Post')),
          ],
        ),
      ),
    );
  }
}
