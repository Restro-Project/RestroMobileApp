import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});
  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _unameC  = TextEditingController();
  final _emailC  = TextEditingController();
  final _phoneC  = TextEditingController();
  bool  _saving  = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((d) {
      final m = d.data()!;
      _unameC.text = m['username'] ?? '';
      _emailC.text = m['email'] ?? '';
      _phoneC.text = m['phone'] ?? '';
    });
  }

  @override
  void dispose() {
    _unameC.dispose(); _emailC.dispose(); _phoneC.dispose();
    super.dispose();
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Akun')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(children: [
          _field(_unameC, 'Username'),
          const SizedBox(height: 16),
          _field(_emailC, 'Email',
              kb: TextInputType.emailAddress, v: _vEmail),
          const SizedBox(height: 16),
          _field(_phoneC, 'Nomor Telepon', kb: TextInputType.phone),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Simpan'),
          ),
        ]),
      ),
    ),
  );

  Widget _field(TextEditingController c, String l,
      {TextInputType? kb, String? Function(String?)? v}) =>
      TextFormField(
        controller: c,
        keyboardType: kb,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: l),
        validator: v ?? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      );

  String? _vEmail(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
        ? null
        : 'Format email salah';
  }

  /* ---------------- SIMPAN ---------------- */
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;
    final uid  = user.uid;
    final newEmail = _emailC.text.trim();

    try {
      /* re-auth + updateEmail (bila berubah) */
      if (newEmail != user.email) {
        final ok = await _reauthIfNeeded();
        if (!ok) throw 'Re-auth dibatalkan';
        await user.updateEmail(newEmail);
      }

      await user.updateDisplayName(_unameC.text.trim());

      /* sinkron ke Firestore */
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _unameC.text.trim(),
        'email'   : newEmail,
        'phone'   : _phoneC.text.trim(),
      });

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (_) {
      // batal / error lain
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* -- contoh re-auth sederhana (email/password) -- */
  Future<bool> _reauthIfNeeded() async {
    final pass = await showDialog<String>(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Re-autentikasi'),
          content: TextField(
            controller: c,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password saat ini'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('OK')),
          ],
        );
      },
    );
    if (pass == null || pass.isEmpty) return false;

    try {
      final cred = EmailAuthProvider.credential(
          email: FirebaseAuth.instance.currentUser!.email!, password: pass);
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password salah')));
      return false;
    }
  }
}
