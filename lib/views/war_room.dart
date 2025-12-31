import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WarRoom extends StatelessWidget {
  const WarRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("LIVE RESULTS",
            style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Make sure your folder is named "assets/images/" (plural) in your project
                image: AssetImage("assets/images/war_room_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. DARK OVERLAY (Updated Opacity)
          // I reduced the opacity from 0.9 to 0.5 so the background image is actually visible
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8), // Was 0.8
                  const Color(0xFF006400).withOpacity(0.9), // Was 0.9 (Too thick!)
                  Colors.black.withOpacity(0.95), // Was 0.95
                ],
              ),
            ),
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('candidates').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No candidates found.", style: TextStyle(color: Colors.white)));

                // --- GROUPING LOGIC ---
                Map<String, List<DocumentSnapshot>> groupedCandidates = {};

                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String position = data['position'] ?? "Unknown";

                  if (!groupedCandidates.containsKey(position)) {
                    groupedCandidates[position] = [];
                  }
                  groupedCandidates[position]!.add(doc);
                }

                // Convert map to list for display
                List<String> positions = groupedCandidates.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    String positionTitle = positions[index];
                    List<DocumentSnapshot> candidates = groupedCandidates[positionTitle]!;

                    // Sort candidates: Highest votes first
                    candidates.sort((a, b) => (b['voteCount'] ?? 0).compareTo(a['voteCount'] ?? 0));

                    // Calculate Total Votes for this position
                    int totalVotesInPosition = 0;
                    for (var c in candidates) {
                      totalVotesInPosition += (c['voteCount'] as int);
                    }

                    return _buildPositionSection(positionTitle, candidates, totalVotesInPosition);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSection(String title, List<DocumentSnapshot> candidates, int totalVotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POSITION HEADER
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Row(
            children: [
              Container(width: 5, height: 25, color: const Color(0xFFFFD700)),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(color: Colors.black, blurRadius: 10)]
                ),
              ),
            ],
          ),
        ),

        // LIST OF CANDIDATES
        ...candidates.map((doc) {
          return _buildCandidateCard(doc, totalVotes);
        }).toList(),

        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.1)),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCandidateCard(DocumentSnapshot doc, int totalVotes) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int votes = data['voteCount'] ?? 0;
    String name = data['name'] ?? "Unknown";

    // --- FIX 2: IMAGE KEY CORRECTION ---
    // Changed from 'imageUrl' to 'photoUrl' to match ManageCandidatesScreen
    String imageUrl = data['photoUrl'] ?? "";

    // Calculate Percentage
    double percentage = totalVotes == 0 ? 0 : (votes / totalVotes);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // 1. CANDIDATE IMAGE
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover, alignment: Alignment.topCenter)
                  : null,
            ),
            child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
          ),

          const SizedBox(width: 15),

          // 2. NAME & PROGRESS BAR
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Progress Bar Container
                Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(5)),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              const Color(0xFF006400),
                              percentage > 0.5 ? const Color(0xFFFFD700) : const Color(0xFF32CD32)
                            ]),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                  color: percentage > 0.5 ? Colors.yellow.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                                  blurRadius: 6, spreadRadius: 1
                              )
                            ]
                        ),
                      ),
                    ).animate().slideX(duration: 1.seconds, curve: Curves.easeOutExpo),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          // 3. VOTE COUNT BADGE
          Column(
            children: [
              Text(
                "$votes",
                style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(percentage * 100).toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          )
        ],
      ),
    );
  }
}