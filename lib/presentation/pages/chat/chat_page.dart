// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/* ────────────────────────────────────────────────────────── */
/*  Halaman daftar kontak + pencarian                       */
/* ────────────────────────────────────────────────────────── */
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _searchC = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext c)=>const Center(child:Text('Calendar'));
//     final uid   = FirebaseAuth.instance.currentUser!.uid;
//     final users = FirebaseFirestore.instance
//         .collection('users')
//         .orderBy('fullName')
//         .snapshots();                                         // ➜ ambil semua
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Pesan')),
//       body: Column(
//         children: [
//           /* ---------- field pencarian ---------- */
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchC,
//               onChanged: (v) => setState(() => _keyword = v.trim().toLowerCase()),
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText  : 'Cari Kontak',
//                 filled    : true,
//                 fillColor : Colors.orange.shade50,
//                 border    : OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(32),
//                   borderSide  : BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//
//           /* ---------- daftar kontak ---------- */
//           Expanded(
//             child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//               stream: users,
//               builder: (_, snap) {
//                 if (!snap.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final docs = snap.data!.docs
//                     .where((d) => d.id != uid)               // sembunyikan akun sendiri
//                     .where((d) => (d['fullName'] as String)
//                     .toLowerCase()
//                     .contains(_keyword))                 // filter keyword
//                     .toList();
//
//                 if (docs.isEmpty) {
//                   return const Center(child: Text('Tidak ada kontak'));
//                 }
//
//                 return ListView.builder(
//                   itemCount: docs.length,
//                   itemBuilder: (_, i) {
//                     final d   = docs[i].data();
//                     final rid = docs[i].id;
//                     return _ContactTile(
//                       remoteUid: rid,
//                       fullName : d['fullName'] ?? '',
//                       photoUrl : d['photoUrl'],
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /* ────────────────────────────────────────────────────────── */
// /*  Tile kontak + pratinjau pesan terakhir                  */
// /* ────────────────────────────────────────────────────────── */
// class _ContactTile extends StatelessWidget {
//   const _ContactTile({
//     required this.remoteUid,
//     required this.fullName,
//     this.photoUrl,
//   });
//
//   final String remoteUid, fullName;
//   final String? photoUrl;
//
//   /* id room = dua uid digabung lexicographically */
//   String _chatId(String a, String b) =>
//       (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';
//
//   /* -------- GET dokumen room sekali         --------
//      kalau belum ada / permission-denied → kembalikan null.             */
//   Future<DocumentSnapshot<Map<String, dynamic>>?> _safeGetRoom(String cid) async {
//     try {
//       return await FirebaseFirestore.instance.collection('chats').doc(cid).get();
//     } on FirebaseException catch (e) {
//       if (e.code == 'permission-denied') return null;
//       rethrow;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final myUid = FirebaseAuth.instance.currentUser!.uid;
//     final cid   = _chatId(myUid, remoteUid);
//
//     return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
//       future: _safeGetRoom(cid),
//       builder: (_, snap) {
//         /* nilai default */
//         String preview = 'Mari mulai berkomunikasi satu sama lain !';
//         String timeTxt = '';
//
//         if (snap.hasData && snap.data != null && snap.data!.exists) {
//           final m = snap.data!.data()!;
//           preview = m['lastMessage'] ?? preview;
//
//           final t = (m['lastTime'] as Timestamp?)?.toDate();
//           if (t != null) timeTxt = TimeOfDay.fromDateTime(t).format(context);
//         }
//
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundImage:
//             photoUrl == null ? null : NetworkImage(photoUrl!),
//             child: photoUrl == null
//                 ? Text(fullName.isEmpty ? '?' : fullName[0])
//                 : null,
//           ),
//           title   : Text(fullName),
//           subtitle: Text(preview,
//               maxLines: 1, overflow: TextOverflow.ellipsis),
//           trailing: Text(timeTxt, style: const TextStyle(fontSize: 12)),
//           onTap: () => context.push('/chat/$cid', extra: {
//             'peerUid' : remoteUid,
//             'fullName': fullName,
//             'photo'   : photoUrl,
//           }),
//         );
//       },
//     );
//   }
}
