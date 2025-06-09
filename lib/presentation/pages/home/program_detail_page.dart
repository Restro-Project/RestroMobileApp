import 'package:flutter/material.dart';

import '../../../data/models/program_model.dart';

class ProgramDetailPage extends StatelessWidget {
  final Program program;

  const ProgramDetailPage({Key? key, required this.program}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(program.namaProgram, style: const TextStyle(color: Colors.white)), // Title color changed to white
        backgroundColor: Colors.green.shade700, // AppBar background changed to green
        iconTheme: const IconThemeData(color: Colors.white), // Back button color changed to white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.namaProgram,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tanggal Program:', program.tanggalProgram),
            _buildInfoRow('Status Program:', program.status),
            const SizedBox(height: 16),
            const Text(
              'Catatan Terapis:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            Text(
              program.catatanTerapis.isNotEmpty
                  ? program.catatanTerapis
                  : 'Tidak ada catatan.',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            const SizedBox(height: 24),
            const Text(
              'Dibuat untuk Pasien:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            Text(
              'Nama Lengkap: ${program.pasien.namaLengkap}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            Text(
              'Username: ${program.pasien.username}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            const SizedBox(height: 24),
            const Text(
              'Dibuat oleh Terapis:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            Text(
              'Nama Lengkap: ${program.terapis.namaLengkap}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            Text(
              'Username: ${program.terapis.username}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Gerakan Direncanakan:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            if (program.listGerakanDirencanakan.isEmpty)
              const Text('Tidak ada gerakan yang direncanakan.', style: TextStyle(fontSize: 16, color: Colors.black87)) // Text color changed
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: program.listGerakanDirencanakan.length,
                itemBuilder: (context, index) {
                  final plannedMovement = program.listGerakanDirencanakan[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.white, // Card background changed to white
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${plannedMovement.namaGerakan}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700, // Text color changed to green
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Repetisi yang Direncanakan: ${plannedMovement.jumlahRepetisiDirencanakan}', style: const TextStyle(color: Colors.black87)), // Text color changed
                          const SizedBox(height: 8),
                          if (plannedMovement.urlFoto != null && plannedMovement.urlFoto!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                plannedMovement.urlFoto!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.green, // Progress indicator color
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('Gambar tidak dapat dimuat');
                                },
                              ),
                            )
                          else
                            const Text('Tidak ada gambar tersedia', style: TextStyle(color: Colors.grey)), // Text color changed
                          const SizedBox(height: 8),
                          Text(
                            'Deskripsi: ${plannedMovement.deskripsi}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54), // Text color changed
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black), // Text color explicitly black
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
          ),
        ],
      ),
    );
  }
}