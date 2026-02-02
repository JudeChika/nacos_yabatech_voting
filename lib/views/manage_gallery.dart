import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ManageGalleryScreen extends StatefulWidget {
  const ManageGalleryScreen({super.key});

  @override
  State<ManageGalleryScreen> createState() => _ManageGalleryScreenState();
}

class _ManageGalleryScreenState extends State<ManageGalleryScreen> {
  final _captionController = TextEditingController();

  File? _mobileImage;
  Uint8List? _webImage;
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        var bytes = await picked.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _mobileImage = File(picked.path));
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_mobileImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a photo first!")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = "gallery/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask task;

      if (kIsWeb) {
        task = ref.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(_mobileImage!);
      }

      String imageUrl = await (await task).ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('gallery').add({
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(), // Optional caption
        'timestamp': FieldValue.serverTimestamp(),
      });

      _captionController.clear();
      setState(() {
        _mobileImage = null;
        _webImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo Added to Gallery!"), backgroundColor: Colors.green));
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
    ImageProvider? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (_mobileImage != null) imageProvider = FileImage(_mobileImage!);

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Event Photo"), backgroundColor: const Color(0xFF006400), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                ),
                child: imageProvider == null ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey), Text("Tap to select photo")])) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _captionController, decoration: const InputDecoration(labelText: "Caption (Optional)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadPhoto,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400)),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("UPLOAD TO GALLERY", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}