import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/api_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});
  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _unameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.dio.get('/api/patient/profile');
    final m = res.data as Map<String, dynamic>;
    _unameC.text = m['username'] ?? '';
    _emailC.text = m['email'] ?? '';
    _phoneC.text = m['nomor_telepon'] ?? '';
    setState(() {});
  }

  @override
  void dispose() {
    _unameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Akun')),
    body: BlocListener<AuthBloc, AuthState>(
      listener: (ctx, s) {
        if (s is AuthSuccess && mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(const SnackBar(content: Text('Data tersimpan')));
          Navigator.pop(context);
        }
        if (s is AuthFailure && mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(SnackBar(content: Text(s.msg)));
          setState(() => _saving = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
            ],
          ),
        ),
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
    final re = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return re.hasMatch(v) ? null : 'Format email salah';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    context.read<AuthBloc>().add(UpdateProfileRequested({
      'username': _unameC.text.trim(),
      'email': _emailC.text.trim(),
      'nomor_telepon': _phoneC.text.trim(),
    }));
  }
}
