import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({super.key});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Image Variables
  File? _mobileImage;
  Uint8List? _webImage;
  final _picker = ImagePicker();
  bool _isUploading = false;

  // 1. Unified Image Picker
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        var bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _mobileImage = null;
        });
      } else {
        setState(() {
          _mobileImage = File(picked.path);
          _webImage = null;
        });
      }
    }
  }

  // 2. Upload Logic
  Future<void> _postNews() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Headline and Content are required!")));
      return;
    }

    setState(() => _isUploading = true);
    String? imageUrl;

    try {
      // A. Upload Image (If selected)
      if (_mobileImage != null || _webImage != null) {
        String fileName = "news/${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask task;

        if (kIsWeb) {
          task = ref.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          task = ref.putFile(_mobileImage!);
        }

        imageUrl = await (await task).ref.getDownloadURL();
      }

      // B. Save to Firestore
      await FirebaseFirestore.instance.collection('news').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'imageUrl': imageUrl ?? "", // Empty string if no image
        'author': 'NACOS Admin',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // C. Reset UI
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _mobileImage = null;
        _webImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("News Published Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color yabaGreen = Color(0xFF006400);

    // Image Preview Helper
    ImageProvider? imageProvider;
    if (_webImage != null) imageProvider = MemoryImage(_webImage!);
    else if (_mobileImage != null) imageProvider = FileImage(_mobileImage!);

    return Scaffold(
      appBar: AppBar(
        title: Text("Create News Post", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: yabaGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? const Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 5),
                          Text("Tap to add Cover Photo", style: TextStyle(color: Colors.grey))
                        ]
                    )
                )
                    : null,
              ),
            ),
            const SizedBox(height: 25),

            const Text("Headline", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    hintText: "e.g., Election Results Delayed",
                    border: OutlineInputBorder()
                )
            ),

            const SizedBox(height: 20),

            const Text("Content Body", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
                controller: _bodyController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Type the full details here...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                )
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _postNews,
                style: ElevatedButton.styleFrom(backgroundColor: yabaGreen),
                icon: _isUploading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send, color: Colors.white),
                label: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PUBLISH TO FEED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}