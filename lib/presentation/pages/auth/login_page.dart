import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../widgets/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocConsumer<AuthBloc, AuthState>(
      listener: (c, s) {
        setState(() => _loading = s is AuthLoading);
        if (s is AuthSuccess) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('Login berhasil')),
          );
          context.go('/home');
        }
        if (s is AuthFailure) {
          ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.msg)));
        }
      },
      builder: (_, __) => AbsorbPointer(
        absorbing: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('Log In',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passC,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 8) return 'Min. 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                NeuButton(
                  label: 'Masuk',
                  loading: _loading,
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                          SignInRequested(_emailC.text.trim(), _passC.text));
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Belum punya akun? Daftar'),
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    final re = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return re.hasMatch(v) ? null : 'Format email salah';
  }
}
