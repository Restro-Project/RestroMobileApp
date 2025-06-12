import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/api_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class PatientInfoPage extends StatefulWidget {
  const PatientInfoPage({super.key});
  @override
  State<PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<PatientInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullC = TextEditingController();
  final _placeC = TextEditingController();
  final _addrC = TextEditingController();
  final _compC = TextEditingController();
  final _gender = ValueNotifier('Laki-laki');
  DateTime? _dob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.dio.get('/api/patient/profile');
    final m = res.data as Map<String, dynamic>;

    _fullC.text = m['nama_lengkap'] ?? '';
    _placeC.text = m['tempat_lahir'] ?? '';
    _addrC.text = m['alamat'] ?? '';
    _compC.text = m['nama_pendamping'] ?? '';
    _gender.value = m['jenis_kelamin'] ?? 'Laki-laki';
    if (m['tanggal_lahir'] != null && m['tanggal_lahir'].toString().isNotEmpty) {
      _dob = DateTime.parse(m['tanggal_lahir']);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _fullC.dispose();
    _placeC.dispose();
    _addrC.dispose();
    _compC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informasi Pasien')),
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
              _field(_fullC, 'Nama Lengkap'),
              const SizedBox(height: 16),
              _dropdown('Jenis Kelamin', _gender,
                  ['Laki-laki', 'Perempuan']),
              const SizedBox(height: 16),
              _dateField(),
              const SizedBox(height: 16),
              _field(_placeC, 'Tempat Lahir'),
              const SizedBox(height: 16),
              _field(_addrC, 'Alamat', lines: 2),
              const SizedBox(height: 16),
              _field(_compC, 'Nama Pendamping'),
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

  Widget _field(TextEditingController c, String l,
      {int lines = 1, TextInputType? kb}) =>
      TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: kb,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: l),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      );

  Widget _dropdown(String l, ValueNotifier<String> vn, List<String> items) =>
      ValueListenableBuilder(
        valueListenable: vn,
        builder: (_, val, __) => DropdownButtonFormField<String>(
          value: items.contains(val) ? val : null,
          decoration: InputDecoration(labelText: l),
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
        initialDate: _dob ?? DateTime(now.year - 17),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (picked != null) setState(() => _dob = picked);
    },
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
      child: Text(
        _dob == null
            ? 'Pilih tanggal'
            : DateFormat('d MMMM y', 'id').format(_dob!),
      ),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    context.read<AuthBloc>().add(UpdateProfileRequested({
      'nama_lengkap': _fullC.text.trim(),
      'jenis_kelamin': _gender.value,
      'tanggal_lahir'  : _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
      'tempat_lahir': _placeC.text.trim(),
      'alamat': _addrC.text.trim(),
      'nama_pendamping': _compC.text.trim(),
    }));
  }
}

