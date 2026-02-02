import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart'; // For downloading bytes
import 'package:image_gallery_saver/image_gallery_saver.dart'; // For mobile saving
import 'package:universal_html/html.dart' as html; // <--- NEW: For Web Downloads

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isDownloading = false;

  Future<void> _downloadImage(BuildContext context, String url) async {
    setState(() => _isDownloading = true);

    try {
      // 1. WEB DIRECT DOWNLOAD LOGIC
      if (kIsWeb) {
        // Fetch the image bytes
        var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));

        // Create a "Blob" (Binary Large Object) from the bytes
        final blob = html.Blob([response.data]);

        // Create a temporary URL for this blob
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        // Create a hidden HTML link, set it to download, and click it programmatically
        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute("download", "nacos_event_${DateTime.now().millisecondsSinceEpoch}.jpg")
          ..click();

        // Cleanup
        html.Url.revokeObjectUrl(blobUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download Started! Check your browser downloads."), backgroundColor: Colors.green));
        }
        return;
      }

      // 2. MOBILE LOGIC (Save to Gallery)
      // A. Show "Downloading" Feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading... Please wait.")));

      // B. Fetch the image bytes using Dio
      var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));

      // C. Save bytes to Gallery
      final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          name: "nacos_event_${DateTime.now().millisecondsSinceEpoch}"
      );

      // D. Success Feedback
      if (result['isSuccess'] == true || result != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Gallery Successfully!"), backgroundColor: Colors.green));
        }
      } else {
        throw Exception("Failed to save");
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text("EVENT GALLERY", style: GoogleFonts.orbitron(color: const Color(0xFF006400), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006400)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gallery').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No photos in gallery yet."));

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return GestureDetector(
                onTap: () => _showFullImage(context, doc['imageUrl'], doc['caption'] ?? ""),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                    image: DecorationImage(image: NetworkImage(doc['imageUrl']), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String url, String caption) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(15),
              child: SingleChildScrollView( // Fix for overflow error
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(url, fit: BoxFit.contain),
                          ),
                        ),
                        IconButton(
                          icon: const CircleAvatar(backgroundColor: Colors.white, radius: 15, child: Icon(Icons.close, color: Colors.black, size: 20)),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (caption.isNotEmpty)
                      Text(caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : () => _downloadImage(context, url),
                        icon: _isDownloading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.download),
                        label: Text(_isDownloading ? "Downloading..." : "Download Image"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }
}