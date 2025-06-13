import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/api_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _futureProfile;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;

    try {
      final url = await ApiService.uploadProfilePicture(xFile.path);   // ← url baru
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Foto berhasil di-update')));
      setState(() async {
        _futureProfile = Future.value({
          ... await _futureProfile,
          'url_foto_profil': url,
        });
      });
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['msg'] ?? 'Gagal upload')));
    }
  }

  @override
  void initState() {
    super.initState();
    _futureProfile = _fetchProfile();
  }

  /* ---------------- HTTP ---------------- */
  Future<Map<String, dynamic>> _fetchProfile() async {
    try {
      final res = await ApiService.dio.get('/api/patient/profile');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      if ([401, 403].contains(e.response?.statusCode)) {
        if (mounted) context.read<AuthBloc>().add(SignOutRequested());
      }
      return {};
    }
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _futureProfile,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final data = snap.data ?? {};
      final uname = data['username'] ?? '';
      final fname = data['nama_lengkap'] ?? '';
      final email = data['email'] ?? '';

      return RefreshIndicator(
        onRefresh: () {
          final f = _fetchProfile();
          setState(() => _futureProfile = f);
          return f;
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _pickAndUpload,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: ClipOval(
                    child: data['url_foto_profil'] != null
                        ? Image.network(
                      // tambahkan query param supaya cache di-bypass
                      '${data['url_foto_profil']}?v=${DateTime.now().millisecondsSinceEpoch}',
                      fit: BoxFit.contain,
                    )
                        : Container(
                      alignment: Alignment.center,
                      color: Colors.grey.shade300,
                      child: Text(
                        (uname.isNotEmpty ? uname[0] : '?').toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      fname.isEmpty ? email : fname,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(uname,
                        style:
                        const TextStyle(color: Colors.green, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _tile(Icons.phone_iphone, 'Informasi Akun', () async {
                await context.push('/account-info');
                setState(() => _futureProfile = _fetchProfile());
              }),
              _tile(Icons.person, 'Informasi Pasien', () async {
                await context.push('/patient-info');
                setState(() => _futureProfile = _fetchProfile());
              }),
              _tile(Icons.health_and_safety, 'Informasi Kesehatan',
                      () async {
                    await context.push('/health-info');
                    setState(() => _futureProfile = _fetchProfile());
                  }),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  onPressed: () =>
                      context.read<AuthBloc>().add(SignOutRequested()),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _tile(IconData icon, String label, VoidCallback onTap) => ListTile(
    leading: CircleAvatar(
      radius: 20,
      backgroundColor: Colors.orange.shade100,
      child: Icon(icon, color: Colors.green),
    ),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right, color: Colors.green),
    onTap: onTap,
  );
}
