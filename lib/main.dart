import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share/share.dart';

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
  int _page = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
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
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
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
  bool _showButtons = true;

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
              // Toggle the visibility of the floating buttons when tapped.
              setState(() {
                _showButtons = !_showButtons;
              });
            },
            child: PhotoView(
              imageProvider: NetworkImage(widget.photoUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
            ),
          ),
          if (_showButtons)
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Logic to save/download the photo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Photo saved to your device!'),
                    ),
                  );
                },
                child: Icon(Icons.download),
                backgroundColor: Colors.blue,
              ),
            ),
          if (_showButtons)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  // Logic to share the photo
                  Share.share(widget.photoUrl, subject: 'Check out this photo!');
                },
                child: Icon(Icons.share),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}
