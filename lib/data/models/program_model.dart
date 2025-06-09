class Program {
  final int id;
  final String namaProgram;
  final String tanggalProgram;
  final String catatanTerapis;
  final String status;
  final Pasien pasien;
  final Terapis terapis;
  final List<PlannedMovement> listGerakanDirencanakan;

  Program({
    required this.id,
    required this.namaProgram,
    required this.tanggalProgram,
    required this.catatanTerapis,
    required this.status,
    required this.pasien,
    required this.terapis,
    required this.listGerakanDirencanakan,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    var list = json['list_gerakan_direncanakan'] as List;
    List<PlannedMovement> plannedMovementsList =
    list.map((i) => PlannedMovement.fromJson(i)).toList();

    return Program(
      id: json['id'],
      namaProgram: json['nama_program'],
      tanggalProgram: json['tanggal_program'],
      catatanTerapis: json['catatan_terapis'],
      status: json['status'],
      pasien: Pasien.fromJson(json['pasien']),
      terapis: Terapis.fromJson(json['terapis']),
      listGerakanDirencanakan: plannedMovementsList,
    );
  }
}

class PlannedMovement {
  final int id;
  final String namaGerakan;
  final String deskripsi;
  final String? urlFoto;
  final String? urlModelTflite;
  final String? urlVideo;
  final int jumlahRepetisiDirencanakan;
  final int urutanDalamProgram;
  final Terapis createdByTerapis; // Renamed from Terapis to avoid conflict if Terapis is a top-level class. If Terapis is nested, this is fine. Assuming it's the same Terapis model.

  PlannedMovement({
    required this.id,
    required this.namaGerakan,
    required this.deskripsi,
    this.urlFoto,
    this.urlModelTflite,
    this.urlVideo,
    required this.jumlahRepetisiDirencanakan,
    required this.urutanDalamProgram,
    required this.createdByTerapis,
  });

  factory PlannedMovement.fromJson(Map<String, dynamic> json) {
    return PlannedMovement(
      id: json['id'],
      namaGerakan: json['nama_gerakan'],
      deskripsi: json['deskripsi'],
      urlFoto: json['url_foto'],
      urlModelTflite: json['url_model_tflite'],
      urlVideo: json['url_video'],
      jumlahRepetisiDirencanakan: json['jumlah_repetisi_direncanakan'],
      urutanDalamProgram: json['urutan_dalam_program'],
      createdByTerapis: Terapis.fromJson(json['created_by_terapis']),
    );
  }
}

class Pasien {
  final int id;
  final String email;
  final String namaLengkap;
  final String role;
  final String username;

  Pasien({
    required this.id,
    required this.email,
    required this.namaLengkap,
    required this.role,
    required this.username,
  });

  factory Pasien.fromJson(Map<String, dynamic> json) {
    return Pasien(
      id: json['id'],
      email: json['email'],
      namaLengkap: json['nama_lengkap'],
      role: json['role'],
      username: json['username'],
    );
  }
}

// Re-using the Terapis class from movement_model.dart if it's the same structure.
// If it's not exactly the same, you might need a separate Terapis model for programs.
// For now, assuming it's the same or a very similar structure.
// If you want to put this in a shared file for models, that's a good practice.
// For simplicity, I'll include it here and assume it's okay for now.
class Terapis {
  final int id;
  final String email;
  final String namaLengkap;
  final String role;
  final String username;

  Terapis({
    required this.id,
    required this.email,
    required this.namaLengkap,
    required this.role,
    required this.username,
  });

  factory Terapis.fromJson(Map<String, dynamic> json) {
    return Terapis(
      id: json['id'],
      email: json['email'],
      namaLengkap: json['nama_lengkap'],
      role: json['role'],
      username: json['username'],
    );
  }
}