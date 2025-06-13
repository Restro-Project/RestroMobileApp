import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _pgr       = PageController();
  final _form  = GlobalKey<FormState>();

  final _usernameC = TextEditingController();
  final _fullNameC = TextEditingController();
  final _emailC    = TextEditingController();
  final _phoneC    = TextEditingController();
  final _passC     = TextEditingController();
  final _pass2C    = TextEditingController();

  bool _ob1 = true, _ob2 = true, _loading = false;

  @override
  void dispose() {
    for (final c in [
      _usernameC, _fullNameC, _emailC, _phoneC,
      _passC, _pass2C
    ]) { c.dispose(); }
    _pgr.dispose();
    super.dispose();
  }

  /* ────────── UI ────────── */
  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        context.go('/login');
        return false;
      },
      child: Scaffold(
    body: BlocConsumer<AuthBloc, AuthState>(
      listener: (c, s) {
        setState(() => _loading = s is AuthLoading);
        if (s is AuthSuccess) {
          ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
              content: Text('Registrasi berhasil, silakan login')));
          context.go('/login');
        }
        if (s is AuthFailure) {
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(s.msg)));
        }
      },
      builder: (_, __) => Stack(
        children: [
          Container(height: 100, color: const Color(0xFF2F3026)),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 40, bottom: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text('Daftar',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F3026))),
                      ),
                      const SizedBox(height: 24),
                      _field(_usernameC, 'Username'),
                      const SizedBox(height: 16),
                      _field(_fullNameC, 'Nama Lengkap'),
                      const SizedBox(height: 16),
                      _field(_emailC, 'Email',
                          kb: TextInputType.emailAddress,
                          validator: _vEmail),
                      const SizedBox(height: 16),
                      _field(_phoneC, 'Nomor Telepon',
                          kb: TextInputType.phone),
                      const SizedBox(height: 16),
                      _field(_passC, 'Password',
                          obscure: _ob1,
                          suffix: IconButton(
                              icon: Icon(
                                  _ob1 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _ob1 = !_ob1)),
                          validator: _vPass),
                      const SizedBox(height: 16),
                      _field(_pass2C, 'Ulangi Password',
                          obscure: _ob2,
                          suffix: IconButton(
                              icon: Icon(
                                  _ob2 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _ob2 = !_ob2)),
                          validator: (v) =>
                          v != _passC.text ? 'Password tidak sama' : _vPass(v)),
                      const SizedBox(height: 32),
                      _button(
                        label: 'Daftar',
                        onTap: _loading
                            ? null
                            : () {
                          if (_form.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              SignUpRequested(
                                username: _usernameC.text.trim(),
                                fullName: _fullNameC.text.trim(),
                                email: _emailC.text.trim(),
                                password: _passC.text,
                                phone: _phoneC.text.trim(),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text.rich(TextSpan(children: [
                          TextSpan(
                            text: 'Anda sudah memiliki akun?\n',
                            style: TextStyle(
                              color: Color(0xFF2F3026), // Warna sama dengan tombol
                                ),
                          ),
                          TextSpan(
                              text: 'Silahkan Masuk',
                              style: TextStyle(
                                  decoration: TextDecoration.underline))
                        ]), textAlign: TextAlign.center),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    ),
  )
);

  /* ────────── helper ────────── */
  Widget _field(TextEditingController c, String l,
      {bool obscure = false,
        Widget? suffix,
        String? Function(String?)? validator,
        TextInputType? kb}) =>
      TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: c,
        obscureText: obscure,
        keyboardType: kb,
        validator:
        validator ?? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
        decoration: InputDecoration(
          labelText: l,
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          suffixIcon: suffix,
        ),
      );

  Widget _button({required String label, VoidCallback? onTap}) => SizedBox(
    height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F3026),
        foregroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onTap,
      child: Text(label,
          style:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );

  String? _vEmail(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
        ? null
        : 'Format email salah';
  }

  String? _vPass(String? v) =>
      v != null && v.length >= 8 ? null : 'Min. 8 karakter';
}