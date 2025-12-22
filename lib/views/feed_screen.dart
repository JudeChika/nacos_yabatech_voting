import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for User ID
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  // --- FUNCTION 1: HANDLE LIKES ---
  Future<void> _toggleLike(String docId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('news').doc(docId);

    if (currentLikes.contains(uid)) {
      // Unlike: Remove UID from array
      await docRef.update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      // Like: Add UID to array
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

  // --- FUNCTION 2: HANDLE SHARE (COPY LINK) ---
  Future<void> _sharePost(BuildContext context, String docId, String title) async {
    // Generate a simulated deep link (Update domain to your actual site later)
    final String shareLink = "https://nacos-vote.web.app/feed?id=$docId";

    // Copy to Clipboard
    await Clipboard.setData(ClipboardData(text: shareLink));

    // Show Feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text("Link copied: $shareLink")),
            ],
          ),
          backgroundColor: const Color(0xFF006400),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text("NACOS NEWS FEED", style: GoogleFonts.orbitron(color: const Color(0xFF006400), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006400)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('news').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No updates yet. Check back later!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _buildNewsCard(context, snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    // Date Formatting
    String date = "Just now";
    if (data['timestamp'] != null) {
      Timestamp t = data['timestamp'];
      date = DateFormat.yMMMd().add_jm().format(t.toDate());
    }

    // Like Logic Preparation
    List<dynamic> likes = (data['likes'] ?? []) as List<dynamic>;
    bool isLiked = user != null && likes.contains(user.uid);
    int likeCount = likes.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF006400),
                  child: Icon(Icons.campaign, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['author'] ?? "NACOS Admin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),

          // 2. PORTRAIT IMAGE (Using AspectRatio 4:5 for vertical look)
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
            AspectRatio(
              aspectRatio: 0.8, // 0.8 = 4:5 Portrait Ratio (Standard for social feeds)
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  image: DecorationImage(
                      image: NetworkImage(data['imageUrl']),
                      fit: BoxFit.cover
                  ),
                ),
              ),
            ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? "No Title", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(data['body'] ?? "", style: GoogleFonts.poppins(color: Colors.black87)),
              ],
            ),
          ),

          // 4. FUNCTIONAL INTERACTION BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // LIKE BUTTON
                InkWell(
                  onTap: () => _toggleLike(doc.id, likes),
                  child: Row(
                    children: [
                      Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey
                      ),
                      const SizedBox(width: 5),
                      Text(
                          "$likeCount",
                          style: TextStyle(
                              color: isLiked ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 30),

                // SHARE BUTTON
                InkWell(
                  onTap: () => _sharePost(context, doc.id, data['title'] ?? "News"),
                  child: const Row(
                    children: [
                      Icon(Icons.share, color: Colors.grey),
                      SizedBox(width: 5),
                      Text("Share Link", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}