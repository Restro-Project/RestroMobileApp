import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'detect_page.dart'; // Sesuaikan nama package Anda

class ExerciseSelectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ExerciseSelectionPage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  List<String> _actions = [];
  List<Map<String, dynamic>> _plannedExercises = []; // {actionName: String, targetReps: int}
  int _maxDuration = 20; // Default max duration per repetition

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    try {
      final String response = await rootBundle.loadString('assets/actions.txt');
      setState(() {
        _actions = response.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      });
    } catch (e) {
      print('Error loading actions.txt: $e');
      // Handle error, e.g., show a dialog
    }
  }

  void _addExercise(String actionName) {
    setState(() {
      _plannedExercises.add({'actionName': actionName, 'targetReps': 1});
    });
  }

  void _updateReps(int index, int reps) {
    setState(() {
      _plannedExercises[index]['targetReps'] = reps;
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _plannedExercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Latihan Rehabilitasi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durasi Maksimal per Repetisi (detik): $_maxDuration',
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              value: _maxDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: _maxDuration.toString(),
              onChanged: (double value) {
                setState(() {
                  _maxDuration = value.round();
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Gerakan:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return ListTile(
                    title: Text(action),
                    trailing: ElevatedButton(
                      onPressed: () => _addExercise(action),
                      child: const Text('Tambah'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Latihan Terpilih:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _plannedExercises.isEmpty
                  ? const Center(child: Text('Belum ada latihan yang dipilih.'))
                  : ListView.builder(
                itemCount: _plannedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _plannedExercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exercise['actionName'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () {
                                  if (exercise['targetReps'] > 1) {
                                    _updateReps(index, exercise['targetReps'] - 1);
                                  }
                                },
                              ),
                              Text(
                                '${exercise['targetReps']} repetisi',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () {
                                  _updateReps(index, exercise['targetReps'] + 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _removeExercise(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _plannedExercises.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetectPage(
                        cameras: widget.cameras,
                        plannedExercises: _plannedExercises,
                        maxDurationPerRep: _maxDuration,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Mulai Latihan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}