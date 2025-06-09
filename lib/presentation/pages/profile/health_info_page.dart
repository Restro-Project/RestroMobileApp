import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/api_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class HealthInfoPage extends StatefulWidget {
  const HealthInfoPage({super.key});
  @override
  State<HealthInfoPage> createState() => _HealthInfoPageState();
}

class _HealthInfoPageState extends State<HealthInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightC = TextEditingController();
  final _weightC = TextEditingController();
  final _medicalC = TextEditingController();
  final _allergyC = TextEditingController();
  final _bloodType = ValueNotifier<String>('A');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.dio.get('/api/patient/profile');
    final m = res.data as Map<String, dynamic>;

    _heightC.text = (m['tinggi_badan'] ?? '').toString();
    _weightC.text = (m['berat_badan'] ?? '').toString();
    _medicalC.text = m['riwayat_medis'] ?? '';
    _allergyC.text = m['riwayat_alergi'] ?? '';
    _bloodType.value = m['golongan_darah'] ?? 'A';
    setState(() {});
  }

  @override
  void dispose() {
    _heightC.dispose();
    _weightC.dispose();
    _medicalC.dispose();
    _allergyC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Kesehatan')),
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
              _field(_heightC, 'Tinggi Badan (cm)',
                  kb: TextInputType.number),
              const SizedBox(height: 16),
              _field(_weightC, 'Berat Badan (kg)',
                  kb: TextInputType.number),
              const SizedBox(height: 16),
              _dropdown('Golongan Darah', _bloodType,
                  ['A', 'B', 'AB', 'O']),
              const SizedBox(height: 16),
              _field(_medicalC, 'Riwayat Medis'),
              const SizedBox(height: 16),
              _field(_allergyC, 'Riwayat Alergi'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(TextEditingController c, String l, {TextInputType? kb}) =>
      TextFormField(
        controller: c,
        keyboardType: kb,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: l),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      );

  Widget _dropdown(String l, ValueNotifier<String> vn, List<String> items) =>
      ValueListenableBuilder<String>(
        valueListenable: vn,
        builder: (_, val, __) => DropdownButtonFormField<String>(
          value: items.contains(val) ? val : null,
          decoration: InputDecoration(labelText: l),
          items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => vn.value = v!,
        ),
      );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    context.read<AuthBloc>().add(UpdateProfileRequested({
      'tinggi_badan': int.tryParse(_heightC.text) ?? 0,
      'berat_badan': double.tryParse(_weightC.text) ?? 0,
      'golongan_darah': _bloodType.value,
      'riwayat_medis': _medicalC.text.trim(),
      'riwayat_alergi': _allergyC.text.trim(),
    }));
  }
}
