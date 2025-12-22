import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageExecutivesScreen extends StatefulWidget {
  const ManageExecutivesScreen({super.key});

  @override
  State<ManageExecutivesScreen> createState() => _ManageExecutivesScreenState();
}

class _ManageExecutivesScreenState extends State<ManageExecutivesScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Predefined Order List
  final List<String> _positions = [
    "President", "Vice President", "General Secretary 1", "General Secretary 2",
    "Financial Secretary", "Treasurer", "Welfare Officer 1", "Welfare Officer 2",
    "Public Relations Officer 1", "Public Relations Officer 2", "Librarian 1", "Librarian 2",
    "Sports Director 1", "Sports Director 2", "Social Director 1", "Social Director 2"
  ];
  String? _selectedPosition;

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

  Future<void> _addExecutive() async {
    if (_nameController.text.isEmpty || _selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Position are required!")));
      return;
    }

    setState(() => _isUploading = true);
    String? imageUrl;

    try {
      if (_mobileImage != null || _webImage != null) {
        String fileName = "executives/${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask task = kIsWeb
            ? ref.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'))
            : ref.putFile(_mobileImage!);

        imageUrl = await (await task).ref.getDownloadURL();
      }

      // Calculate Rank based on list index (Ensures correct sorting order)
      int rank = _positions.indexOf(_selectedPosition!) + 1;

      await FirebaseFirestore.instance.collection('executives').add({
        'name': _nameController.text.trim(),
        'position': _selectedPosition,
        'phone': _phoneController.text.trim(),
        'imageUrl': imageUrl ?? "",
        'rank': rank, // Used for sorting
      });

      _nameController.clear();
      _phoneController.clear();
      setState(() {
        _mobileImage = null;
        _webImage = null;
        _selectedPosition = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Executive Added Successfully!"), backgroundColor: Colors.green));
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
    if (_webImage != null) imageProvider = MemoryImage(_webImage!);
    else if (_mobileImage != null) imageProvider = FileImage(_mobileImage!);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Executive"), backgroundColor: const Color(0xFF006400), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                    border: Border.all(color: Colors.grey)
                ),
                child: imageProvider == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),

            // Dropdown ensures they pick from the exact list
            DropdownButtonFormField<String>(
              value: _selectedPosition,
              decoration: const InputDecoration(labelText: "Position", border: OutlineInputBorder(), prefixIcon: Icon(Icons.work_outline)),
              items: _positions.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedPosition = newValue),
            ),

            const SizedBox(height: 15),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _addExecutive,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400)),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE EXECUTIVE", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}