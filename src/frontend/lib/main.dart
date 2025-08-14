import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Homework Solver',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  XFile? _image;
  String _solution =
      '📚 Welcome to Math Homework Solver!\n\nTap the camera button below to take a photo of your math problem and get instant help with step-by-step solutions!';
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _isLoading = true;
      });
      _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() {
      _solution =
          '🔍 Analyzing your math problem...\n\nPlease wait while our AI examines the image and prepares a detailed solution for you!';
    });

    // Use localhost for web and 10.0.2.2 for Android emulator
    final uri = kIsWeb
        ? Uri.parse('http://localhost:5000/upload')
        : Uri.parse('http://10.0.2.2:5000/upload');

    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      var bytes = await image.readAsBytes();
      var multipartFile =
          http.MultipartFile.fromBytes('file', bytes, filename: image.name);
      request.files.add(multipartFile);
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decodedData = jsonDecode(responseData);
        setState(() {
          _solution = '✅ **Solution Found!**\n\n${decodedData['solution']}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _solution =
              '❌ **Oops! Something went wrong**\n\nError: ${response.reasonPhrase}\n\nPlease try again with a clearer image of your math problem.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _solution =
            '❌ **Connection Error**\n\nUnable to connect to the server. Please check your internet connection and try again.\n\nError details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 28),
            SizedBox(width: 8),
            Text('Math Homework Solver',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_image != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: kIsWeb
                                    ? Image.network(_image!.path,
                                        fit: BoxFit.cover)
                                    : Image.file(File(_image!.path),
                                        fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading
                                      ? 'Analyzing...'
                                      : 'Analysis Complete',
                                  style: TextStyle(
                                    color: _isLoading
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera,
                                      size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the camera button to get started!',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Solution Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.deepPurple),
                                SizedBox(width: 8),
                                Text(
                                  'Solution',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: MarkdownBody(
                                data: _solution,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 16, height: 1.5),
                                  h1: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                  h2: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                  h3: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                  strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey.shade100,
                                    color: Colors.deepPurple,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom padding
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickImage,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.camera_alt),
        label: Text(_isLoading ? 'Processing...' : 'Take Photo'),
        backgroundColor: _isLoading ? Colors.grey : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
