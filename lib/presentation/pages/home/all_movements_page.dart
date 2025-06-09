import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../data/api_service.dart';
import '../../../data/models/movement_model.dart';
import 'movement_detail_page.dart';

class AllMovementsPage extends StatefulWidget {
  const AllMovementsPage({Key? key}) : super(key: key);

  @override
  State<AllMovementsPage> createState() => _AllMovementsPageState();
}

class _AllMovementsPageState extends State<AllMovementsPage> {
  List<Movement> _movements = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchMovements();
  }

  Future<void> _fetchMovements() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await ApiService.dio.get('/api/gerakan');
      if (response.statusCode == 200) {
        final List<dynamic> gerakanData = response.data['gerakan'];
        setState(() {
          _movements = gerakanData.map((json) => Movement.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _error = 'Failed to load movements: ${response.statusCode}';
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = 'Failed to connect to server. Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Gerakan', style: TextStyle(color: Colors.white)), // Title color changed to white
        backgroundColor: Colors.green.shade700, // AppBar background changed to green
        iconTheme: const IconThemeData(color: Colors.white), // Back button color changed to white
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green)) // Progress indicator color
          : _error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          final movement = _movements[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white, // Card background changed to white
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovementDetailPage(movement: movement),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.namaGerakan,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900, // Movement name color changed to dark green
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (movement.urlFoto != null && movement.urlFoto!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                            return const Text('Gambar tidak dapat dimuat');
                          },
                        ),
                      )
                    else
                      const Text('Tidak ada gambar tersedia', style: TextStyle(color: Colors.grey)), // Text color changed
                    const SizedBox(height: 8),
                    Text(
                      movement.deskripsi,
                      style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}