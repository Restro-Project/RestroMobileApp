import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _futureProfile = _fetchProfile();
  }

  /* ───── HTTP ─────────────────────────────────────────────── */
  Future<Map<String, dynamic>> _fetchProfile() async {
    try {
      final res = await ApiService.dio.get('/api/patient/profile');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      // 422/404 -> profil belum ada
      if (e.response?.statusCode == 422 || e.response?.statusCode == 404) {
        return {};
      }
      if ([401, 403].contains(e.response?.statusCode)) {
        if (mounted) context.read<AuthBloc>().add(SignOutRequested());
      }
      rethrow;
    }
  }

  /* ───── UI ──────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _futureProfile,
    builder: (_, snap) {
      /* LOADING */
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      /* ERROR */
      if (snap.hasError) {
        return _errorLayout();
      }

      /* DATA */
      final data  = snap.data ?? {};
      final uname = (data['username']      ?? '').toString();
      final fname = (data['nama_lengkap']  ?? '').toString();
      final email = (data['email']         ?? '').toString();

      return RefreshIndicator(
        onRefresh: () {
          final newFuture = _fetchProfile();
          setState(() => _futureProfile = newFuture);
          return newFuture;
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  (uname.isNotEmpty ? uname[0] : '?').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 40, color: Colors.white),
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
                        style: const TextStyle(
                            color: Colors.green, fontSize: 14)),
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

  /* ───── Helper Widget ───────────────────────────────────── */
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

  Widget _errorLayout() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat profil'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
            onPressed: () {
              setState(() {
                _futureProfile = _fetchProfile();
              });
            },
          ),
        ],
      ),
    ),
  );
}
