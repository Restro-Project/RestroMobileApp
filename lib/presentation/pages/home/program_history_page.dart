import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../data/api_service.dart';
import '../../../data/models/program_model.dart';
import 'program_detail_page.dart';

class ProgramHistoryPage extends StatefulWidget {
  const ProgramHistoryPage({Key? key}) : super(key: key);

  @override
  State<ProgramHistoryPage> createState() => _ProgramHistoryPageState();
}

class _ProgramHistoryPageState extends State<ProgramHistoryPage> {
  List<Program> _programs = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchProgramHistory();
  }

  Future<void> _fetchProgramHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await ApiService.dio.get('/api/program/pasien/history');
      if (response.statusCode == 200) {
        final List<dynamic> programData = response.data['programs'];
        setState(() {
          _programs = programData.map((json) => Program.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _error = 'Failed to load program history: ${response.statusCode}';
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
        title: const Text('Riwayat Program', style: TextStyle(color: Colors.white)), // Title color changed to white
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
        itemCount: _programs.length,
        itemBuilder: (context, index) {
          final program = _programs[index];
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
                    builder: (context) => ProgramDetailPage(program: program),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.namaProgram,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900, // Program name color changed to dark green
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tanggal: ${program.tanggalProgram}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87), // Text color changed
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${program.status}',
                      style: TextStyle(
                        fontSize: 16,
                        color: program.status == 'selesai'
                            ? Colors.green.shade700 // Green for 'selesai'
                            : Colors.green.shade700, // Changed from orange to green for consistency
                      ),
                    ),
                    if (program.listGerakanDirencanakan.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Gerakan Direncanakan:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black), // Text color changed
                      ),
                      ...program.listGerakanDirencanakan.map((movement) =>
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text(
                              '- ${movement.namaGerakan} (${movement.jumlahRepetisiDirencanakan} repetisi)',
                              style: const TextStyle(fontSize: 14, color: Colors.black87), // Text color changed
                            ),
                          )),
                    ]
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