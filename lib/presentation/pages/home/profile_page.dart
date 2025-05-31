import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = s.data!.data()!;
        final uname = d['username'] ?? '';
        final fname = d['fullName'] ?? '';

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  uname.isEmpty ? '?' : uname[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(fname,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(uname,
                        style:
                        const TextStyle(color: Colors.green, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              /* ---------- menu ---------- */
              _tile(
                icon: Icons.phone_iphone,
                label: 'Informasi Akun',
                onTap: () => context.push('/account-info'),
              ),
              _tile(
                icon: Icons.person,
                label: 'Informasi Pasien',
                onTap: () => context.push('/patient-info'),
              ),
              _tile(
                icon: Icons.health_and_safety,
                label: 'Informasi Kesehatan',
                onTap: () => context.push('/health-info'),
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  onPressed: () =>
                      FirebaseAuth.instance.signOut(), // router akan redirect
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _tile(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) =>
      ListTile(
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