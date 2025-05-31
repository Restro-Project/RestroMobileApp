import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _pgr       = PageController();
  final _formKey1  = GlobalKey<FormState>();
  final _formKey2  = GlobalKey<FormState>();

  // step-1
  final _usernameC = TextEditingController();
  final _fullNameC = TextEditingController();
  final _emailC    = TextEditingController();
  final _phoneC    = TextEditingController();
  final _passC     = TextEditingController();
  final _pass2C    = TextEditingController();

  // step-2 (boleh kosong dulu → bisa diubah di profil)
  final _gender    = ValueNotifier<String>('Laki-laki');
  final _btype     = ValueNotifier<String>('A');
  DateTime? _birthDate;
  final _birthPlaceC = TextEditingController();
  final _addressC    = TextEditingController();
  final _companionC  = TextEditingController();
  final _heightC     = TextEditingController();
  final _weightC     = TextEditingController();
  final _medicalC    = TextEditingController();
  final _allergyC    = TextEditingController();

  bool _ob1 = true, _ob2 = true, _loading = false;

  @override
  void dispose() {
    for (final c in [
      _usernameC, _fullNameC, _emailC, _phoneC,
      _passC, _pass2C, _birthPlaceC, _addressC,
      _companionC, _heightC, _weightC, _medicalC, _allergyC
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
          children: [_step1(), _step2()],
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
          },
        ),
      ]),
    ),
  );

  /* ---------------- STEP-2 : data pasien & kesehatan ---------------- */
  Widget _step2() => Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey2,
      child: ListView(children: [
        _dropdown('Jenis Kelamin', _gender, ['Laki-laki', 'Perempuan']),
        _gap(),
        _dateField(),
        _gap(),
        _text(_birthPlaceC, 'Tempat Lahir'),
        _gap(),
        _text(_addressC, 'Alamat', lines: 2),
        _gap(),
        _text(_companionC, 'Nama Pendamping'),
        _gap(),
        _text(_heightC, 'Tinggi Badan (cm)', kb: TextInputType.number),
        _gap(),
        _text(_weightC, 'Berat Badan (kg)', kb: TextInputType.number),
        _gap(),
        _dropdown('Golongan Darah', _btype, ['A', 'B', 'AB', 'O']),
        _gap(),
        _text(_medicalC, 'Riwayat Medis'),
        _gap(),
        _text(_allergyC, 'Riwayat Alergi'),
        _gap(32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pgr.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeuButton(
                label: 'Daftar',
                loading: _loading,
                onTap: () {
                  if (_formKey2.currentState!.validate() && _birthDate != null) {
                    context.read<AuthBloc>().add(SignUpRequested(
                      // akun
                      email      : _emailC.text.trim(),
                      password   : _passC.text,
                      username   : _usernameC.text.trim(),
                      fullName   : _fullNameC.text.trim(),
                      phone      : _phoneC.text.trim(),

                      // pasien
                      gender         : _gender.value,
                      birthDate      : _birthDate!,           // sudah dipastikan != null
                      birthPlace     : _birthPlaceC.text.trim(),
                      address        : _addressC.text.trim(),
                      companionName  : _companionC.text.trim(),

                      // kesehatan
                      height         : int.tryParse(_heightC.text)  ?? 0,
                      weight         : int.tryParse(_weightC.text)  ?? 0,
                      bloodType      : _btype.value,
                      medicalHistory : _medicalC.text.trim(),
                      allergyHistory : _allergyC.text.trim(),
                    ));
                  } else if (_birthDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tanggal lahir wajib diisi')),
                    );
                  }
                },
              ),
            ),
          ],
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

  Widget _dropdown(String label, ValueNotifier<String> vn, List<String> items) =>
      ValueListenableBuilder<String>(
        valueListenable: vn,
        builder: (_, val, __) => DropdownButtonFormField<String>(
          value: val,
          decoration: InputDecoration(labelText: label),
          items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => vn.value = v!,
        ),
      );

  Widget _dateField() => GestureDetector(
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now.subtract(const Duration(days: 7000)),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked != null) setState(() => _birthDate = picked);
    },
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
      child: Text(_birthDate == null
          ? 'Pilih tanggal'
          : '${_birthDate!.day}-${_birthDate!.month}-${_birthDate!.year}'),
    ),
  );

  SizedBox _gap([double h = 16]) => SizedBox(height: h);

  String? _vEmail(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
        ? null
        : 'Format email salah';
  }

  String? _vPass(String? v) =>
      v != null && v.length >= 6 ? null : 'Min. 6 karakter';
}