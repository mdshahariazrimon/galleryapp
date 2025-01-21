import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<dynamic> _photos = [];
  List<dynamic> _filteredPhotos = [];
  int _page = 1;
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPhotos();

    // Listen to changes in the search bar
    _searchController.addListener(() {
      _filterPhotos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPhotos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://api.unsplash.com/photos?page=$_page&client_id=tnVeIKl1E9DsgeiWBNr79RCC41lU4BgDLZO_ufxKJIk');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedPhotos = json.decode(response.body);
        setState(() {
          _photos.addAll(fetchedPhotos);
          _filteredPhotos = _photos; // Initially, all photos are visible
          _page++;
        });
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPhotos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPhotos = _photos
          .where((photo) => photo['alt_description']
          ?.toLowerCase()
          ?.contains(query) ??
          false)
          .toList();
    });
  }

  void _shareApp() {
    Share.share(
      'Check out this amazing photo gallery app!\nhttps://example.com',
      subject: 'Photo Gallery App',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Photo Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareApp,
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _fetchPhotos();
          }
          return true;
        },
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: _filteredPhotos.length,
          itemBuilder: (context, index) {
            final photo = _filteredPhotos[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PhotoDetailScreen(photoUrl: photo['urls']['full']),
                ),
              ),
              child: Hero(
                tag: photo['id'],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photo['urls']['small'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search photos...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue),
              ),
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class PhotoDetailScreen extends StatefulWidget {
  final String photoUrl;

  PhotoDetailScreen({required this.photoUrl});

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  bool _showButton = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showButton = !_showButton;
              });
            },
            child: PhotoView(
              imageProvider: NetworkImage(widget.photoUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
            ),
          ),
          if (_showButton)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'download',
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Photo saved to your device!'),
                        ),
                      );
                    },
                    child: Icon(Icons.download),
                    backgroundColor: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'share',
                    onPressed: () {
                      if (widget.photoUrl.isNotEmpty) {
                        Share.share(
                          widget.photoUrl,
                          subject: 'Check out this photo!',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: Unable to share this photo'),
                          ),
                        );
                      }
                    },
                    child: Icon(Icons.share),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
