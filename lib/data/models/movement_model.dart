class Movement {
  final int id;
  final String namaGerakan;
  final String deskripsi;
  final String? urlFoto;
  final String? urlModelTflite;
  final String? urlVideo;
  final Terapis createdByTerapis;

  Movement({
    required this.id,
    required this.namaGerakan,
    required this.deskripsi,
    this.urlFoto,
    this.urlModelTflite,
    this.urlVideo,
    required this.createdByTerapis,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['id'],
      namaGerakan: json['nama_gerakan'],
      deskripsi: json['deskripsi'],
      urlFoto: json['url_foto'],
      urlModelTflite: json['url_model_tflite'],
      urlVideo: json['url_video'],
      createdByTerapis: Terapis.fromJson(json['created_by_terapis']),
    );
  }
}

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