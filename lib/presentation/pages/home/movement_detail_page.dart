import 'package:flutter/material.dart';

import '../../../data/models/movement_model.dart';

class MovementDetailPage extends StatelessWidget {
  final Movement movement;

  const MovementDetailPage({Key? key, required this.movement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movement.namaGerakan, style: const TextStyle(color: Colors.white)), // Title color changed to white
        backgroundColor: Colors.green.shade700, // AppBar background changed to green
        iconTheme: const IconThemeData(color: Colors.white), // Back button color changed to white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movement.namaGerakan,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 16),
            if (movement.urlFoto != null && movement.urlFoto!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    movement.urlFoto!,
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
                      return const Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.red));
                    },
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  'Tidak ada gambar GIF tersedia',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            Text(
              movement.deskripsi,
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            const SizedBox(height: 24),
            const Text(
              'Dibuat oleh Terapis:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Text color explicitly black
            ),
            const SizedBox(height: 8),
            Text(
              'Nama Lengkap: ${movement.createdByTerapis.namaLengkap}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            Text(
              'Username: ${movement.createdByTerapis.username}',
              style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
            ),
            const SizedBox(height: 16),
            // You can add more details here if needed, like TFLite model URL or video URL
            if (movement.urlModelTflite != null && movement.urlModelTflite!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('URL Model TFLite: ${movement.urlModelTflite}', style: TextStyle(fontSize: 14, color: Colors.green.shade700)), // Link color changed to green
              ),
            if (movement.urlVideo != null && movement.urlVideo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('URL Video: ${movement.urlVideo}', style: TextStyle(fontSize: 14, color: Colors.green.shade700)), // Link color changed to green
              ),
          ],
        ),
      ),
    );
  }
}