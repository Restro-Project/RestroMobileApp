import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/* ────────────────────────────────────────────────────────── */
/*  Halaman detail / percakapan                             */
/* ────────────────────────────────────────────────────────── */
class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.peerUid,
    required this.peerName,
    required this.peerPhoto,
  });

  final String chatId, peerUid, peerName;
  final String? peerPhoto;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  late final String            _myUid;
  late final DocumentReference _chat;   // /chats/{chatId}
  late final CollectionReference _msgs; // /chats/{chatId}/messages
  final _msgC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _chat  = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    _msgs  = _chat.collection('messages');

    _ensureRoomExists();                //  ⟵  penting!
  }

  /* ---------------------------------------------------------- */
  /*  Buat dokumen room TANPA melakukan read terlebih dahulu     */
  /* ---------------------------------------------------------- */
  Future<void> _ensureRoomExists() async {
    await _chat.set({
      'participants': FieldValue.arrayUnion([_myUid, widget.peerUid]),
      'lastMessage' : '',
      'lastTime'    : null,
      'lastSender'  : null,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _msgC.dispose();
    super.dispose();
  }

  /* ------------------------ UI ------------------------------ */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _buildBar(),
    body : Column(
      children: [
        Expanded(child: _buildMessages()),
        const Divider(height: 1),
        _buildInput(),
      ],
    ),
  );

  /*  App-Bar dengan foto & nama lawan bicara */
  PreferredSizeWidget _buildBar() => AppBar(
    titleSpacing: 0,
    title: Row(children: [
      CircleAvatar(
        backgroundImage: widget.peerPhoto == null
            ? null
            : NetworkImage(widget.peerPhoto!),
        child: widget.peerPhoto == null
            ? Text(widget.peerName[0])
            : null,
      ),
      const SizedBox(width: 8),
      Text(widget.peerName, style: const TextStyle(fontSize: 16)),
    ]),
  );

  /*  Daftar pesan (real-time stream) */
  Widget _buildMessages() => StreamBuilder<QuerySnapshot>(
    stream: _msgs.orderBy('time', descending: true).snapshots(),
    builder: (_, snap) {
      if (snap.hasError)   { return const Center(child: Text('Error')); }
      if (!snap.hasData)   { return const Center(child: CircularProgressIndicator()); }

      final docs = snap.data!.docs;
      if (docs.isEmpty) {
        return const Center(child: Text('— belum ada pesan —'));
      }

      return ListView.builder(
        reverse: true,
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final m    = docs[i].data()! as Map<String, dynamic>;
          final isMe = m['sender'] == _myUid;
          return _Bubble(
            isMe : isMe,
            text : m['text'] ?? '',
            time : (m['time'] as Timestamp).toDate(),
          );
        },
      );
    },
  );

  /* ---------------------------------------------------------- */
  /*  Input + kirim pesan                                       */
  /* ---------------------------------------------------------- */
  Widget _buildInput() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller : _msgC,
            minLines    : 1,
            maxLines    : 4,
            decoration  : const InputDecoration(
              hintText       : 'Tulis pesan…',
              border         : OutlineInputBorder(),
              contentPadding : EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon    : const Icon(Icons.send, color: Colors.green),
          onPressed: _sendMessage,
        )
      ]),
    ),
  );

  Future<void> _sendMessage() async {
    final txt = _msgC.text.trim();
    if (txt.isEmpty) return;
    _msgC.clear();

    final now = DateTime.now();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(_chat, {
        'participants': FieldValue.arrayUnion([_myUid, widget.peerUid]),
        'lastMessage' : txt,
        'lastTime'    : now,
        'lastSender'  : _myUid,
      }, SetOptions(merge: true));

      tx.set(_msgs.doc(), {
        'sender': _myUid,
        'text'  : txt,
        'time'  : now,
      });
    });
  }
}

/* ────────────────────────────────────────────────────────── */
/*  Widget bubble percakapan                                 */
/* ────────────────────────────────────────────────────────── */
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.isMe,
    required this.text,
    required this.time,
    super.key,
  });

  final bool isMe;
  final String text;
  final DateTime time;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color       : isMe ? Colors.orange.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text),
        ),
        const SizedBox(height: 4),
        Text(
          TimeOfDay.fromDateTime(time).format(context),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    ),
  );
}
