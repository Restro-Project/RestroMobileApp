import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../widgets/common.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _pgr       = PageController();
  final _formKey1  = GlobalKey<FormState>();

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrasi')),
    body: BlocConsumer<AuthBloc, AuthState>(
      listener: (c, s) {
        setState(() => _loading = s is AuthLoading);
        if (s is AuthSuccess) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('Registrasi berhasil, silakan login')),
          );
          context.go('/login');
        }
        if (s is AuthFailure) {
          ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.msg)));
        }
      },
      builder: (_, __) => AbsorbPointer(
        absorbing: _loading,
        child: PageView(
          controller: _pgr,
          physics: const NeverScrollableScrollPhysics(),
          children: [_step1()],
        ),
      ),
    ),
  );

  /* ---------------- STEP-1 : akun ---------------- */
  Widget _step1() => Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey1,
      child: ListView(children: [
        _text(_usernameC, 'Username'),
        _gap(),
        _text(_fullNameC, 'Nama Lengkap'),
        _gap(),
        _text(_emailC, 'Email', kb: TextInputType.emailAddress, v: _vEmail),
        _gap(),
        _text(_phoneC, 'Nomor Telepon', kb: TextInputType.phone),
        _gap(),
        _text(_passC, 'Password',
            obs: _ob1,
            toggle: () => setState(() => _ob1 = !_ob1),
            v: _vPass),
        _gap(),
        _text(_pass2C, 'Ulangi Password',
            obs: _ob2,
            toggle: () => setState(() => _ob2 = !_ob2),
            v: (v) =>
            v != _passC.text ? 'Password tidak sama' : _vPass(v)),
        _gap(32),
        NeuButton(
          label: 'Lanjutkan',
          loading: _loading,
          onTap: () {
            if (_formKey1.currentState!.validate()) _pgr.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);
            if (_formKey1.currentState!.validate()) {
              context.read<AuthBloc>().add(SignUpRequested(
                // akun
                email      : _emailC.text.trim(),
                password   : _passC.text,
                username   : _usernameC.text.trim(),
                fullName   : _fullNameC.text.trim(),
                phone      : _phoneC.text.trim(),
              ));
            }
          },
        ),
      ]),
    ),
  );

  /* ---------- widget helper ---------- */
  Widget _text(TextEditingController c, String l,
      {bool obs = false,
        VoidCallback? toggle,
        String? Function(String?)? v,
        TextInputType? kb,
        int lines = 1}) =>
      TextFormField(
        controller: c,
        obscureText: obs,
        keyboardType: kb,
        maxLines: lines,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: l,
          suffixIcon: toggle == null
              ? null
              : IconButton(
            icon: Icon(obs ? Icons.visibility : Icons.visibility_off),
            onPressed: toggle,
          ),
        ),
        validator: v ?? (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      );

  SizedBox _gap([double h = 16]) => SizedBox(height: h);

  String? _vEmail(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
        ? null
        : 'Format email salah';
  }

  String? _vPass(String? v) =>
      v != null && v.length >= 8 ? null : 'Min. 8 karakter';
}