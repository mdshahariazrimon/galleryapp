import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galleryapp/main.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
// Replace with the correct import for your app

// Mock the HTTP client for testing API calls
class MockClient extends Mock implements http.Client {}

class MockGallerySaver extends Mock {
  Future<void> savePhoto(String photoUrl);
}

void main() {
  // Test 1: Fetch photos from API
  test('fetch photos from API', () async {
    final client = MockClient();
    final url = Uri.parse('https://api.unsplash.com/photos?page=1&client_id=YOUR_ACCESS_KEY');

    // Mocking the response from the API
    when(client.get(url)).thenAnswer(
          (_) async => http.Response(
        json.encode([{'id': '1', 'urls': {'small': 'image_url', 'full': 'full_image_url'}, 'alt_description': 'description'}]),
        200,
      ),
    );

    final response = await client.get(url);

    // Expecting a successful API call
    expect(response.statusCode, 200);
    final List<dynamic> photos = json.decode(response.body);
    expect(photos, isNotEmpty);
    expect(photos[0]['id'], '1');
  });

  // Test 2: Tap on a photo and navigate to full-screen view
  testWidgets('tap on a photo and navigate to full-screen view', (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(MyApp());

    // Simulate tapping on the first photo in the gallery
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // Verify that the PhotoDetailScreen is shown
    expect(find.byType(PhotoDetailScreen), findsOneWidget);

    // Verify that the photo is displayed in full-screen
    expect(find.byType(PhotoView), findsOneWidget);
  });

  // Test 3: Infinite scroll loads more photos
  testWidgets('infinite scroll loads more photos', (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(MyApp());

    // Simulate scrolling to the bottom of the GridView
    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify that a loading indicator appears
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // Test 4: Save photo to local gallery
  testWidgets('save photo to local gallery', (WidgetTester tester) async {
    // Create a mock instance for gallery saver
    final mockGallerySaver = MockGallerySaver();

    // Initialize the app and go to the PhotoDetailScreen
    await tester.pumpWidget(MaterialApp(
      home: PhotoDetailScreen(photoUrl: 'https://example.com/photo.jpg'),
    ));

    // Tap on the save button
    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();

    // Verify that the savePhoto method was called
    verify(mockGallerySaver.savePhoto('https://example.com/photo.jpg')).called(1);
  });

  // Test 5: Search functionality works correctly
  testWidgets('search functionality works', (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(MyApp());

    // Input a search query
    await tester.enterText(find.byType(TextField), 'sunset');
    await tester.pumpAndSettle();

    // Check if the photos are filtered based on the search term
    final filteredPhotos = find.text('sunset');
    expect(filteredPhotos, findsOneWidget);
  });

  // Test 6: Share app functionality
  testWidgets('share app works', (WidgetTester tester) async {
    // Initialize the app
    await tester.pumpWidget(MyApp());

    // Simulate tapping on the share button
    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();

    // Verify if the share dialog is opened
    expect(find.byType(Share), findsOneWidget);
  });
}
