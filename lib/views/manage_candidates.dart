import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageCandidatesScreen extends StatefulWidget {
  const ManageCandidatesScreen({super.key});

  @override
  State<ManageCandidatesScreen> createState() => _ManageCandidatesScreenState();
}

class _ManageCandidatesScreenState extends State<ManageCandidatesScreen> {
  final TextEditingController _nameController = TextEditingController();

  // Replaced Position Controller with a selected value for Dropdown
  String? _selectedPosition;

  // The strict hierarchy list (Do not remove this, it is needed for new candidates)
  final List<String> _positionHierarchy = [
    "THE PRESIDENT",
    "THE VICE PRESIDENT 1",
    "THE VICE PRESIDENT 2",
    "GENERAL SECRETARY 1",
    "GENERAL SECRETARY 2",
    "GENERAL SECRETARY 3",
    "THE FINANCIAL SECRETARY",
    "THE TREASURER",
    "THE WELFARE OFFICER 1",
    "THE WELFARE OFFICER 2",
    "THE PUBLIC RELATIONS OFFICER 1",
    "THE PUBLIC RELATIONS OFFICER 2",
    "THE PUBLIC RELATIONS OFFICER 3",
    "THE LIBRARIAN 1",
    "THE LIBRARIAN 2",
    "THE LIBRARIAN 3",
    "SPORTS DIRECTOR 1",
    "SPORTS DIRECTOR 2",
    "SPORTS DIRECTOR 3",
    "SOCIAL DIRECTOR 1",
    "SOCIAL DIRECTOR 2"
  ];

  // Image Handling Variables
  File? _mobileImage;       // For Android/iOS
  Uint8List? _webImage;     // For Web
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // --- 1. Unified Image Picker (Works on Web & Mobile) ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // On Web: Read as bytes
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _mobileImage = null; // Clear mobile file if exists
        });
      } else {
        // On Mobile: Use File path
        setState(() {
          _mobileImage = File(pickedFile.path);
          _webImage = null; // Clear web bytes if exists
        });
      }
    }
  }

  // --- 2. Main Function to Upload Image & Save Candidate ---
  Future<void> _addCandidate() async {
    if (_nameController.text.isEmpty || _selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Position are required")));
      return;
    }

    // Check if an image is selected (either Web or Mobile)
    if (_mobileImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a candidate photo")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // A. Create Storage Reference
      String fileName = "candidates/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask;

      // B. Upload based on Platform
      if (kIsWeb) {
        // Web: Upload raw bytes
        uploadTask = storageRef.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Mobile: Upload file
        uploadTask = storageRef.putFile(_mobileImage!);
      }

      // Wait for upload to finish
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // C. Calculate Rank based on Hierarchy List
      // This ensures new candidates are inserted in the correct order automatically
      int rank = _positionHierarchy.indexOf(_selectedPosition!);
      if (rank == -1) rank = 99; // Fallback for safety

      // D. Save Candidate Data to Firestore with RANK
      await FirebaseFirestore.instance.collection('candidates').add({
        'name': _nameController.text.trim(),
        'position': _selectedPosition, // Save the strict name
        'rank': rank,                  // Save the rank for sorting
        'photoUrl': downloadUrl,
        'voteCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // E. Cleanup UI
      _nameController.clear();
      setState(() {
        _selectedPosition = null;
        _mobileImage = null;
        _webImage = null;
      });
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Candidate Added Successfully!"), backgroundColor: Colors.green));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {

            // Helper to display the image preview based on platform
            ImageProvider? imageProvider;
            if (_webImage != null) {
              imageProvider = MemoryImage(_webImage!);
            } else if (_mobileImage != null) {
              imageProvider = FileImage(_mobileImage!);
            }

            return AlertDialog(
              title: const Text("Add New Candidate"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _pickImage();
                        setDialogState(() {}); // Refresh local dialog state
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey),
                          image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageProvider == null
                            ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                            Text("Tap to Upload", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))
                    ),

                    const SizedBox(height: 15),

                    // Dropdown for Strict Hierarchy Selection
                    DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: const InputDecoration(
                        labelText: "Select Position",
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _positionHierarchy.map((String position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(
                            position,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          // Update the state variable in the parent class
                          _selectedPosition = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    setDialogState(() => _isUploading = true);
                    await _addCandidate();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400)),
                  child: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text("Add Candidate", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Candidates", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFFD700),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Candidate", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // SORT BY RANK (Hierarchical Order)
        stream: FirebaseFirestore.instance.collection('candidates').orderBy('rank').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No candidates yet. Click 'Add Candidate'."));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(doc['photoUrl']),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['position']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('candidates').doc(doc.id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}