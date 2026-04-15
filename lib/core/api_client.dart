import "package:dio/dio.dart";

import "app_config.dart";
import "auth_interceptor.dart";
import "token_storage.dart";

class ApiClient {
  ApiClient._();

  static final TokenStorage _tokenStorage = TokenStorage();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "${AppConfig.apiBaseUrl}/api",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.add(AuthInterceptor(_tokenStorage));
}
