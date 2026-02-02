import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  // Track loading state for each specific candidate ID
  final Map<String, bool> _votingStates = {};

  Future<void> _castVote(BuildContext context, String candidateId, String position, String candidateName) async {
    // 1. Set Loading State to TRUE for this button
    setState(() => _votingStates[candidateId] = true);

    final user = FirebaseAuth.instance.currentUser;
    final db = FirebaseFirestore.instance;

    try {
      await db.runTransaction((transaction) async {
        DocumentReference userRef = db.collection('users').doc(user!.uid);
        DocumentSnapshot userDoc = await transaction.get(userRef);

        Map<String, dynamic> votedPositions = {};
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('votedPositions')) {
            votedPositions = Map<String, dynamic>.from(data['votedPositions']);
          }
        }

        // Check if already voted for this position
        if (votedPositions.containsKey(position)) {
          throw Exception("You have already voted for the office of $position!");
        }

        DocumentReference candRef = db.collection('candidates').doc(candidateId);
        transaction.update(candRef, {'voteCount': FieldValue.increment(1)});

        votedPositions[position] = candidateId;
        transaction.update(userRef, {'votedPositions': votedPositions});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Vote for $candidateName cast successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      }
    } finally {
      // 2. Set Loading State back to FALSE when done (success or error)
      if (mounted) {
        setState(() => _votingStates[candidateId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color yabaGreen = Color(0xFF006400);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text("CAST YOUR VOTE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: yabaGreen)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: yabaGreen),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          Map<String, dynamic> userVotes = {};
          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('votedPositions')) {
            userVotes = Map<String, dynamic>.from(userData['votedPositions']);
          }

          return StreamBuilder<QuerySnapshot>(
            // We order by RANK so the groups appear in the correct hierarchy (President first, etc.)
            stream: FirebaseFirestore.instance
                .collection('candidates')
                .orderBy('rank')
                .snapshots(),
            builder: (context, candSnapshot) {
              if (!candSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: yabaGreen));

              final docs = candSnapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No candidates found."));

              // --- GROUPING LOGIC ---
              // Group candidates by their Position Name
              // Since 'docs' comes sorted by Rank, this map will naturally preserve that order.
              Map<String, List<DocumentSnapshot>> groupedCandidates = {};
              for (var doc in docs) {
                String position = doc['position'];
                if (!groupedCandidates.containsKey(position)) {
                  groupedCandidates[position] = [];
                }
                groupedCandidates[position]!.add(doc);
              }

              // --- BUILD LIST OF SECTIONS ---
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 50),
                itemCount: groupedCandidates.length,
                itemBuilder: (context, index) {
                  String positionName = groupedCandidates.keys.elementAt(index);
                  List<DocumentSnapshot> candidates = groupedCandidates[positionName]!;

                  return _buildPositionSection(context, positionName, candidates, yabaGreen, userVotes);
                },
              );
            },
          );
        },
      ),
    );
  }

  // A Widget to build the Header + Grid for ONE position
  Widget _buildPositionSection(BuildContext context, String positionName, List<DocumentSnapshot> candidates, Color primaryColor, Map<String, dynamic> userVotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. CATEGORY HEADER
        Container(
          margin: const EdgeInsets.fromLTRB(15, 25, 15, 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(
            positionName, // e.g. "THE PRESIDENT"
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 2. CANDIDATES GRID FOR THIS POSITION
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shrinkWrap: true, // IMPORTANT: Allows GridView to exist inside ListView
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling for grid, let parent ListView scroll
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.70,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            return _buildCandidateCard(context, candidates[index], primaryColor, userVotes);
          },
        ),
      ],
    );
  }

  Widget _buildCandidateCard(BuildContext context, DocumentSnapshot doc, Color primaryColor, Map<String, dynamic> userVotes) {
    String position = doc['position'];
    String candidateId = doc.id;

    bool hasVotedForThisPosition = userVotes.containsKey(position);
    bool votedForThisCandidate = hasVotedForThisPosition && userVotes[position] == candidateId;

    bool isLoading = _votingStates[candidateId] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: votedForThisCandidate ? Border.all(color: const Color(0xFFFFD700), width: 3) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                doc['photoUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[200], child: const Icon(Icons.person, size: 50, color: Colors.grey)),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc['name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: votedForThisCandidate
                            ? const Color(0xFFFFD700)
                            : (hasVotedForThisPosition ? Colors.grey[300] : primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (hasVotedForThisPosition || isLoading)
                          ? null
                          : () => _castVote(context, candidateId, position, doc['name']),

                      child: isLoading
                          ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                          : Text(
                        votedForThisCandidate ? "VOTED" : (hasVotedForThisPosition ? "LOCKED" : "VOTE"),
                        style: TextStyle(
                            color: votedForThisCandidate ? Colors.black : (hasVotedForThisPosition ? Colors.grey : Colors.white),
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}