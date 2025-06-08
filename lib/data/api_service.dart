import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  static final Dio dio = Dio(BaseOptions(
    baseUrl:
    'https://be-restro-api-fnfpghddbka7d4aw.eastasia-01.azurewebsites.net',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    responseType: ResponseType.json,
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (opt, handler) async {
        /* sisipkan bearer token otomatis */
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) opt.headers['Authorization'] = 'Bearer $token';
        return handler.next(opt);
      },
    ));
}
