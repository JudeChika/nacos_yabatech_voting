import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class WarRoom extends StatelessWidget {
  const WarRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("LIVE WAR ROOM", style: GoogleFonts.orbitron(color: Colors.yellow))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('candidates').orderBy('voteCount', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return ListView.builder(
            padding: const EdgeInsets.all(30),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var cand = snapshot.data!.docs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${cand['name']} - ${cand['voteCount']} Votes", style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      height: 30,
                      width: (cand['voteCount'] * 10).toDouble(), // Scale based on votes
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.yellow : const Color(0xFF006400),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}