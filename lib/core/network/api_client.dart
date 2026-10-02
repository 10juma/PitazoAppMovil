import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.loadToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.token}';
    }
    handler.next(options);
  }
}
