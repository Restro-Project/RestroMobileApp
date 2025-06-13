import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl:
      'https://be-restro-api-fnfpghddbka7d4aw.eastasia-01.azurewebsites.net',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (opt, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          opt.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(opt);
      },
    ),
  );

  /* ────────────────────── ► PROFIL  ────────────────────── */
  static Future<String> uploadProfilePicture(String path) async {
    final filename = path.split('/').last;
    final form = FormData.fromMap({
      'foto_profil': await MultipartFile.fromFile(path, filename: filename),
    });

    final res = await dio.post(
      '/api/patient/profile/picture',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data['url_foto_profil'] as String;
  }

  /* ────────────────────── ► DIET PLAN  ────────────────────── */
  static Future<Map<String, dynamic>?> getDietPlan(String date) async {
    final res = await dio.get('/api/patient/diet-plan/$date');
    return Map<String, dynamic>.from(res.data);
  }

  /* ────────────────────── ► KALENDER PROGRAM  ────────────────────── */
  static Future<List<Map<String, dynamic>>> getCalendarPrograms({
    String? start,
    String? end,
  }) async {
    final res = await dio.get(
      '/api/patient/calendar-programs',
      queryParameters: {
        if (start != null) 'start_date': start,
        if (end != null) 'end_date': end,
      },
    );
    final list = res.data['programs'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /* ────────────────────── ► PROGRAM ───────────────────── */
  static Future<List<Map<String, dynamic>>> getProgramHistory(
      {int page = 1, int perPage = 10}) async {
    final res = await dio.get('/api/program/pasien/history', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
    return (res.data['programs'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getProgramDetail(int id) async {
    final res = await dio.get('/api/program/$id');
    return Map<String, dynamic>.from(res.data['program']);
  }

  static Future<void> updateProgramStatus(int id, String status) async {
    await dio.put('/api/program/$id/update-status',
        data: {'status': status});
  }

  /* ────────────────────── ► LAPORAN  ────────────────────── */
  /// Dapatkan _history_ laporan pasien (paginasi).
  static Future<List<Map<String, dynamic>>> getReportHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    final res =
    await dio.get('/api/laporan/pasien/history', queryParameters: {
      'page': page,
      'per_page': perPage,
    });
    return (res.data['laporan'] as List).cast<Map<String, dynamic>>();
  }

  /// Detail satu laporan berdasar ID.
  static Future<Map<String, dynamic>> getReportDetail(int laporanId) async {
    final res = await dio.get('/api/laporan/$laporanId');
    // respons langsung berupa objek detil (tanpa key “laporan”), lihat dokumentasi
    return Map<String, dynamic>.from(res.data);
  }

  /// Submit laporan (dipanggil DetectPage).
  static Future<void> submitReport(Map<String, dynamic> body) async {
    await dio.post('/api/laporan/submit', data: body);
  }

  /* ────────────────────── ► TODAY PROGRAM (bottom-sheet) */
  static Future<Map<String, dynamic>?> getTodayProgram() async {
    final res = await dio.get('/api/program/pasien/today');
    return Map<String, dynamic>.from(res.data);
  }
}