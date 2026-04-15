import "dart:async";

import "package:dio/dio.dart";

import "app_config.dart";
import "token_storage.dart";

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = "Bearer $token";
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final reqPath = err.requestOptions.path;

    final isAuthEndpoint = reqPath.contains("/auth/token/") || reqPath.contains("/auth/token/refresh/");

    if (statusCode != 401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    final retryResult = await _tryRefreshAndRetry(err.requestOptions);
    if (retryResult != null) {
      handler.resolve(retryResult);
      return;
    }

    handler.next(err);
  }

  Future<Response<dynamic>?> _tryRefreshAndRetry(RequestOptions failedRequest) async {
    if (_isRefreshing) {
      final completer = _refreshCompleter;
      if (completer != null) {
        await completer.future;
      }
    } else {
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      try {
        final refreshToken = await _tokenStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _tokenStorage.clear();
          return null;
        }

        final refreshDio = Dio(
          BaseOptions(baseUrl: "${AppConfig.apiBaseUrl}/api"),
        );

        final refreshResponse = await refreshDio.post<dynamic>(
          "/auth/token/refresh/",
          data: <String, dynamic>{"refresh": refreshToken},
        );

        final newAccess = refreshResponse.data["access"] as String?;
        final newRefresh = (refreshResponse.data["refresh"] as String?) ?? refreshToken;

        if (newAccess == null || newAccess.isEmpty) {
          await _tokenStorage.clear();
          return null;
        }

        await _tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
      } catch (_) {
        await _tokenStorage.clear();
        return null;
      } finally {
        _isRefreshing = false;
        _refreshCompleter?.complete();
      }
    }

    final newAccess = await _tokenStorage.readAccessToken();
    if (newAccess == null || newAccess.isEmpty) {
      return null;
    }

    final requestOptions = failedRequest.copyWith(
      headers: <String, dynamic>{
        ...failedRequest.headers,
        "Authorization": "Bearer $newAccess",
      },
    );

    final retryDio = Dio(
      BaseOptions(baseUrl: "${AppConfig.apiBaseUrl}/api"),
    );
    return retryDio.fetch<dynamic>(requestOptions);
  }
}
