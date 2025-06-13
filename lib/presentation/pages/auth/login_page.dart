import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _emailC  = TextEditingController();
  final _passC   = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  /* ────────── UI ────────── */
  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocConsumer<AuthBloc, AuthState>(
      listener: (c, s) {
        setState(() => _loading = s is AuthLoading);
        if (s is AuthSuccess) {
          ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text('Login berhasil')));
          context.go('/home');
        }
        if (s is AuthFailure) {
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(s.msg)));
        }
      },
      builder: (_, __) => Stack(
        children: [
          /* header background */
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2F3026),
              image: DecorationImage(
                image: AssetImage('assets/login_bg.png'),
                repeat: ImageRepeat.repeat,
                opacity: 0.05,
                // fit: BoxFit.cover,
              ),
            ),
          ),
          /* card form */
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 120, bottom: 24),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 0),
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
                        child: Text('Log In',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F3026))),
                      ),
                      const SizedBox(height: 32),
                      _field(
                        controller: _emailC,
                        label: 'Email',
                        kb: TextInputType.emailAddress,
                        validator: _vEmail,
                      ),
                      const SizedBox(height: 20),
                      _field(
                        controller: _passC,
                        label: 'Password',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) =>
                        v != null && v.length >= 8 ? null : 'Min. 8 karakter',
                      ),
                      const SizedBox(height: 32),
                      _button(
                        label: 'Masuk',
                        onTap: _loading
                            ? null
                            : () {
                          if (_form.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                                SignInRequested(_emailC.text.trim(),
                                    _passC.text));
                          }
                        },
                      ),
                      const SizedBox(height: 48),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text.rich(TextSpan(children: [
                          TextSpan(text: 'Anda belum memiliki akun?\n',
                            style: TextStyle(
                              color: Color(0xFF2F3026),
                            ),
                          ),
                          TextSpan(
                              text: 'Silahkan Daftar',
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
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    ),
  );

  /* ────────── helper ────────── */
  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputType? kb,
  }) =>
      TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: controller,
        obscureText: obscure,
        validator: validator ??
                (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
        keyboardType: kb,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
    final re = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return re.hasMatch(v) ? null : 'Format email salah';
  }
}
