import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../dung_chung/dich_vu_ban/mo_hinh/du_lieu_ban.dart';
import 'may_khach_http.dart'
    if (dart.library.js_interop) 'may_khach_http_web.dart';

/// Client kết nối HTTPS tới CafePos.Api với Cookie Authentication (withCredentials = true)
/// và tự động đính kèm mã chống CSRF (X-CSRF-TOKEN) cho mọi thao tác thay đổi dữ liệu.
class PosAuthApiClient {
  static const String _envBaseUrl = String.fromEnvironment(
    'POS_API_BASE_URL',
    defaultValue: '',
  );

  final String baseUrl;
  final http.Client _http;
  String csrfToken;

  PosAuthApiClient({
    String? baseUrl,
    http.Client? httpClient,
    String initialCsrfToken = '',
  }) : baseUrl = baseUrl ?? _resolveDefaultBaseUrl(),
       _http = httpClient ?? createPlatformHttpClient(),
       csrfToken = initialCsrfToken;

  static String _resolveDefaultBaseUrl() {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    final currentUri = Uri.base;
    if (currentUri.port == 7179 || currentUri.port == 5180) {
      return currentUri.origin;
    }

    return 'https://localhost:7179';
  }

  Map<String, String> _buildHeaders({bool includeCsrf = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (includeCsrf && csrfToken.isNotEmpty) {
      headers['X-CSRF-TOKEN'] = csrfToken;
    }
    return headers;
  }

  /// Khôi phục phiên đăng nhập từ Cookie (GET /api/auth/me)
  Future<ApiResult<AuthSessionModel>> restoreSession() async {
    try {
      final response = await _http
          .get(Uri.parse('$baseUrl/api/auth/me'), headers: _buildHeaders())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = _decodeJson(response.body);
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = AuthSessionModel.fromJson(data);
          csrfToken = session.csrfToken;
          return ApiResult.success(
            session,
            message: (body['message'] ?? 'Khôi phục phiên đăng nhập thành công.')
                .toString(),
          );
        }
      }

      final errBody = _decodeJson(response.body);
      return ApiResult.failure(
        (errBody['message'] ?? 'Chưa có phiên đăng nhập hợp lệ.').toString(),
        errorCode: (errBody['errorCode'] ?? 'UNAUTHORIZED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ POS ($baseUrl).',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Đăng nhập (POST /api/auth/login)
  Future<ApiResult<AuthSessionModel>> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await _http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: _buildHeaders(),
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
              'rememberMe': rememberMe,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = AuthSessionModel.fromJson(data);
          csrfToken = session.csrfToken;
          return ApiResult.success(
            session,
            message: (body['message'] ?? 'Đăng nhập thành công.').toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Tên đăng nhập hoặc mật khẩu không chính xác.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'LOGIN_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ POS ($baseUrl). Vui lòng kiểm tra Backend HTTPS.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Làm mới mã chống CSRF (GET /api/auth/antiforgery)
  Future<String?> refreshAntiforgeryToken() async {
    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl/api/auth/antiforgery'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = _decodeJson(response.body);
        final token = (body['csrfToken'] ?? '').toString();
        if (token.isNotEmpty) {
          csrfToken = token;
          return token;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureCsrfToken() async {
    if (csrfToken.isEmpty) {
      await refreshAntiforgeryToken();
    }
  }

  /// Đăng xuất và xóa Cookie phiên (POST /api/auth/logout)
  Future<ApiResult<bool>> logout() async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/auth/logout'),
            headers: _buildHeaders(includeCsrf: true),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 400) {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/auth/logout'),
              headers: _buildHeaders(includeCsrf: true),
            )
            .timeout(const Duration(seconds: 6));
      }

      csrfToken = '';
      if (response.statusCode == 200) {
        final body = _decodeJson(response.body);
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã đăng xuất khỏi hệ thống POS.')
              .toString(),
        );
      }

      return ApiResult.success(
        true,
        message: 'Đã đăng xuất khỏi phiên làm việc.',
      );
    } catch (_) {
      csrfToken = '';
      return ApiResult.failure(
        'Không thể kết nối máy chủ khi đăng xuất.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Cập nhật hồ sơ người dùng (PUT /api/profile)
  Future<ApiResult<UserProfileModel>> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .put(
            Uri.parse('$baseUrl/api/profile'),
            headers: _buildHeaders(includeCsrf: true),
            body: jsonEncode({
              'fullName': fullName.trim(),
              'phoneNumber': phoneNumber?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 400) {
        await refreshAntiforgeryToken();
        response = await _http
            .put(
              Uri.parse('$baseUrl/api/profile'),
              headers: _buildHeaders(includeCsrf: true),
              body: jsonEncode({
                'fullName': fullName.trim(),
                'phoneNumber': phoneNumber?.trim(),
              }),
            )
            .timeout(const Duration(seconds: 6));
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            UserProfileModel.fromJson(data),
            message: (body['message'] ?? 'Cập nhật hồ sơ thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể cập nhật hồ sơ.').toString(),
        errorCode: (body['errorCode'] ?? 'UPDATE_PROFILE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi cập nhật hồ sơ.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Bắt đầu ca làm việc (POST /api/shifts/start)
  Future<ApiResult<ShiftModel>> startShift({String? note}) async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/shifts/start'),
            headers: _buildHeaders(includeCsrf: true),
            body: jsonEncode({'note': note}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 400) {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/shifts/start'),
              headers: _buildHeaders(includeCsrf: true),
              body: jsonEncode({'note': note}),
            )
            .timeout(const Duration(seconds: 6));
      }

      final body = _decodeJson(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            ShiftModel.fromJson(data),
            message: (body['message'] ?? 'Bắt đầu ca làm việc thành công.')
                .toString(),
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể bắt đầu ca làm việc.').toString(),
        errorCode: (body['errorCode'] ?? 'START_SHIFT_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi bắt đầu ca làm việc.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Kết thúc ca làm việc (POST /api/shifts/end)
  Future<ApiResult<ShiftModel>> endShift({String? note}) async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/shifts/end'),
            headers: _buildHeaders(includeCsrf: true),
            body: jsonEncode({'note': note}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 400) {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/shifts/end'),
              headers: _buildHeaders(includeCsrf: true),
              body: jsonEncode({'note': note}),
            )
            .timeout(const Duration(seconds: 6));
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            ShiftModel.fromJson(data),
            message: (body['message'] ?? 'Kết thúc ca làm việc thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể kết thúc ca làm việc.').toString(),
        errorCode: (body['errorCode'] ?? 'END_SHIFT_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi kết thúc ca làm việc.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy tổng quan dành cho Quản lý (GET /api/dashboard/manager-overview, yêu cầu role Manager ở backend)
  Future<ApiResult<DashboardOverviewModel>> getManagerOverview() async {
    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl/api/dashboard/manager-overview'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            DashboardOverviewModel.fromJson(data),
            message: (body['message'] ?? 'Đồng bộ dữ liệu thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải dữ liệu tổng quan quản lý.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'DASHBOARD_LOAD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ để tải dữ liệu tổng quan.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Mở bàn hoặc ghi thêm món vào bàn (POST /api/dashboard/tables/open-or-order)
  Future<ApiResult<TableCardModel>> openTableOrAddItems({
    required int tableId,
    List<OrderItemInputModel>? items,
    int? orderId,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = <String, dynamic>{
        'tableId': tableId,
        'orderId': ?orderId,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      };

      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/dashboard/tables/open-or-order'),
            headers: _buildHeaders(includeCsrf: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 400) {
        final err = _decodeJson(response.body);
        if (err['errorCode'] == 'INVALID_CSRF_TOKEN') {
          await refreshAntiforgeryToken();
          response = await _http
              .post(
                Uri.parse('$baseUrl/api/dashboard/tables/open-or-order'),
                headers: _buildHeaders(includeCsrf: true),
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 8));
        }
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            TableCardModel.fromJson(data),
            message: (body['message'] ?? 'Thao tác bàn thành công.').toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể mở bàn hoặc ghi món.').toString(),
        errorCode: (body['errorCode'] ?? 'TABLE_ACTION_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi thao tác với bàn.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Phát hành mã VietQR cho đơn trên bàn (POST /api/dashboard/tables/{tableId}/request-vietqr)
  Future<ApiResult<TableCardModel>> requestVietQr({
    required int tableId,
    int? orderId,
  }) async {
    try {
      await _ensureCsrfToken();
      final query = orderId != null ? '?orderId=$orderId' : '';
      final url = '$baseUrl/api/dashboard/tables/$tableId/request-vietqr$query';

      var response = await _http
          .post(Uri.parse(url), headers: _buildHeaders(includeCsrf: true))
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            TableCardModel.fromJson(data),
            message: (body['message'] ?? 'Đã tạo mã VietQR.').toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tạo mã VietQR.').toString(),
        errorCode: (body['errorCode'] ?? 'REQUEST_QR_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi yêu cầu tạo VietQR.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Xác nhận đơn đã thanh toán VietQR (POST /api/dashboard/tables/{tableId}/confirm-paid)
  Future<ApiResult<TableCardModel>> confirmVietQrPaid({
    required int tableId,
    int? orderId,
  }) async {
    try {
      await _ensureCsrfToken();
      final query = orderId != null ? '?orderId=$orderId' : '';
      final url = '$baseUrl/api/dashboard/tables/$tableId/confirm-paid$query';

      var response = await _http
          .post(Uri.parse(url), headers: _buildHeaders(includeCsrf: true))
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            TableCardModel.fromJson(data),
            message: (body['message'] ?? 'Đã xác nhận thanh toán.').toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể xác nhận thanh toán.').toString(),
        errorCode: (body['errorCode'] ?? 'CONFIRM_PAID_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi xác nhận thanh toán.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Trả bàn (POST /api/dashboard/tables/{tableId}/close-table)
  Future<ApiResult<TableCardModel>> closeTableSession({
    required int tableId,
  }) async {
    try {
      await _ensureCsrfToken();
      final url = '$baseUrl/api/dashboard/tables/$tableId/close-table';

      var response = await _http
          .post(Uri.parse(url), headers: _buildHeaders(includeCsrf: true))
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            TableCardModel.fromJson(data),
            message: (body['message'] ?? 'Đã trả bàn thành công.').toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Chưa thể trả bàn.').toString(),
        errorCode: (body['errorCode'] ?? 'CLOSE_TABLE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi thực hiện trả bàn.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy danh sách nhân sự (GET /api/manager/staff)
  Future<ApiResult<List<Map<String, dynamic>>>> getStaffListRaw({
    String? search,
    String? role,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (role != null && role.trim().isNotEmpty) {
        queryParams['role'] = role.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/manager/staff',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final rawList = body['data'] as List? ?? const [];
        final parsed = rawList.whereType<Map<String, dynamic>>().toList();
        return ApiResult.success(
          parsed,
          message: (body['message'] ?? 'Tải danh sách nhân viên thành công.')
              .toString(),
        );
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải danh sách nhân viên.').toString(),
        errorCode: (body['errorCode'] ?? 'GET_STAFF_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải danh sách nhân viên.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Thêm nhân viên mới (POST /api/manager/staff)
  Future<ApiResult<Map<String, dynamic>>> createStaffRaw({
    String? staffCode,
    required String fullName,
    required String phoneNumber,
    required String username,
    required String role,
    required bool isActive,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({
        'staffCode': staffCode,
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'username': username.trim(),
        'role': role,
        'isActive': isActive,
      });

      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/staff'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 400) {
        final err = _decodeJson(response.body);
        if (err['errorCode'] == 'INVALID_CSRF_TOKEN') {
          await refreshAntiforgeryToken();
          response = await _http
              .post(
                Uri.parse('$baseUrl/api/manager/staff'),
                headers: _buildHeaders(includeCsrf: true),
                body: payload,
              )
              .timeout(const Duration(seconds: 8));
        }
      }

      final body = _decodeJson(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã thêm nhân viên thành công.')
                .toString(),
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể thêm nhân viên mới.').toString(),
        errorCode: (body['errorCode'] ?? 'CREATE_STAFF_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi thêm nhân viên mới.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Cập nhật hồ sơ nhân viên (PUT /api/manager/staff/{id})
  Future<ApiResult<Map<String, dynamic>>> updateStaffRaw({
    required String staffUserId,
    required String fullName,
    required String phoneNumber,
    required String role,
    required bool isActive,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'role': role,
        'isActive': isActive,
      });

      var response = await _http
          .put(
            Uri.parse('$baseUrl/api/manager/staff/$staffUserId'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 400) {
        final err = _decodeJson(response.body);
        if (err['errorCode'] == 'INVALID_CSRF_TOKEN') {
          await refreshAntiforgeryToken();
          response = await _http
              .put(
                Uri.parse('$baseUrl/api/manager/staff/$staffUserId'),
                headers: _buildHeaders(includeCsrf: true),
                body: payload,
              )
              .timeout(const Duration(seconds: 8));
        }
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã cập nhật hồ sơ nhân viên.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể cập nhật thông tin nhân viên.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'UPDATE_STAFF_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi cập nhật hồ sơ nhân viên.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Xóa tài khoản nhân viên (DELETE /api/manager/staff/{id})
  Future<ApiResult<bool>> deleteStaffRaw({required String staffUserId}) async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .delete(
            Uri.parse('$baseUrl/api/manager/staff/$staffUserId'),
            headers: _buildHeaders(includeCsrf: true),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 400) {
        final err = _decodeJson(response.body);
        if (err['errorCode'] == 'INVALID_CSRF_TOKEN') {
          await refreshAntiforgeryToken();
          response = await _http
              .delete(
                Uri.parse('$baseUrl/api/manager/staff/$staffUserId'),
                headers: _buildHeaders(includeCsrf: true),
              )
              .timeout(const Duration(seconds: 8));
        }
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã xóa tài khoản nhân viên.')
              .toString(),
        );
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể xóa tài khoản nhân viên.').toString(),
        errorCode: (body['errorCode'] ?? 'DELETE_STAFF_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi xóa tài khoản nhân viên.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Đặt lại mật khẩu cho nhân viên (POST /api/manager/staff/{id}/reset-password)
  Future<ApiResult<bool>> resetStaffPasswordRaw({
    required String staffUserId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/staff/$staffUserId/reset-password'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 400) {
        final err = _decodeJson(response.body);
        if (err['errorCode'] == 'INVALID_CSRF_TOKEN') {
          await refreshAntiforgeryToken();
          response = await _http
              .post(
                Uri.parse(
                  '$baseUrl/api/manager/staff/$staffUserId/reset-password',
                ),
                headers: _buildHeaders(includeCsrf: true),
                body: payload,
              )
              .timeout(const Duration(seconds: 8));
        }
      }

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã đặt lại mật khẩu thành công.')
              .toString(),
        );
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể đặt lại mật khẩu.').toString(),
        errorCode: (body['errorCode'] ?? 'RESET_PASSWORD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi đặt lại mật khẩu nhân viên.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy báo cáo kết quả vận hành (GET /api/manager/reports/revenue-analytics)
  Future<ApiResult<Map<String, dynamic>>> getRevenueAnalyticsRaw({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to'] = toDate;
      }

      final uri = Uri.parse(
        '$baseUrl/api/manager/reports/revenue-analytics',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Tải báo cáo vận hành thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải dữ liệu báo cáo vận hành.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'REPORT_LOAD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải báo cáo kinh doanh.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy dữ liệu dự báo Daylight AI (GET /api/manager/reports/ai-forecast)
  Future<ApiResult<Map<String, dynamic>>> getAiForecastRaw({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to'] = toDate;
      }

      final uri = Uri.parse(
        '$baseUrl/api/manager/reports/ai-forecast',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Tải dự báo Daylight AI thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải dữ liệu dự báo Daylight AI.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'FORECAST_LOAD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải dữ liệu dự báo AI.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy danh sách hóa đơn theo khung ca (GET /api/manager/reports/shift-orders)
  Future<ApiResult<Map<String, dynamic>>> getShiftOrdersRaw({
    required String slot,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, String>{'slot': slot};
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['from'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['to'] = toDate;
      }

      final uri = Uri.parse(
        '$baseUrl/api/manager/reports/shift-orders',
      ).replace(queryParameters: queryParams);

      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Tải danh sách hóa đơn ca thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải danh sách hóa đơn trong ca.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'SHIFT_ORDERS_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải danh sách hóa đơn theo ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy chi tiết một hóa đơn (GET /api/dashboard/orders/{orderId})
  Future<ApiResult<Map<String, dynamic>>> getOrderDetailsRaw(
    int orderId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/dashboard/orders/$orderId');
      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Tải chi tiết hóa đơn thành công.')
                .toString(),
          );
        }
      }

      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải chi tiết hóa đơn.').toString(),
        errorCode: (body['errorCode'] ?? 'ORDER_DETAIL_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải chi tiết hóa đơn.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy danh mục khung ca (GET /api/manager/shift-schedule/templates)
  Future<ApiResult<List<Map<String, dynamic>>>> getShiftTemplatesRaw({
    String? search,
    String? status,
  }) async {
    try {
      final q = <String, String>{};
      if (search != null && search.trim().isNotEmpty) q['search'] = search.trim();
      if (status != null && status.trim().isNotEmpty) q['status'] = status.trim();
      final uri = Uri.parse(
        '$baseUrl/api/manager/shift-schedule/templates',
      ).replace(queryParameters: q.isEmpty ? null : q);

      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final list = (body['data'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        return ApiResult.success(
          list,
          message: (body['message'] ?? 'Tải danh mục khung ca thành công.')
              .toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải danh mục khung ca.').toString(),
        errorCode: (body['errorCode'] ?? 'TEMPLATES_LOAD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải danh mục khung ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Tạo mới khung ca (POST /api/manager/shift-schedule/templates)
  Future<ApiResult<Map<String, dynamic>>> createShiftTemplateRaw(
    Map<String, dynamic> payloadMap,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode(payloadMap);
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/shift-schedule/templates'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/manager/shift-schedule/templates'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['isSuccess'] == true &&
          body['data'] is Map<String, dynamic>) {
        return ApiResult.success(
          body['data'] as Map<String, dynamic>,
          message: (body['message'] ?? 'Đã tạo khung ca thành công.').toString(),
          statusCode: response.statusCode,
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tạo khung ca.').toString(),
        errorCode: (body['errorCode'] ?? 'CREATE_TEMPLATE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tạo khung ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Cập nhật khung ca (PUT /api/manager/shift-schedule/templates/{code})
  Future<ApiResult<Map<String, dynamic>>> updateShiftTemplateRaw(
    String code,
    Map<String, dynamic> payloadMap,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode(payloadMap);
      final url = '$baseUrl/api/manager/shift-schedule/templates/$code';
      var response = await _http
          .put(
            Uri.parse(url),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .put(
              Uri.parse(url),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 &&
          body['isSuccess'] == true &&
          body['data'] is Map<String, dynamic>) {
        return ApiResult.success(
          body['data'] as Map<String, dynamic>,
          message: (body['message'] ?? 'Đã cập nhật khung ca.').toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể cập nhật khung ca.').toString(),
        errorCode: (body['errorCode'] ?? 'UPDATE_TEMPLATE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi cập nhật khung ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Xóa hoặc ngừng sử dụng khung ca (DELETE /api/manager/shift-schedule/templates/{code})
  Future<ApiResult<bool>> deleteShiftTemplateRaw(
    String code, {
    String? reason,
  }) async {
    try {
      await _ensureCsrfToken();
      final uri = Uri.parse(
        '$baseUrl/api/manager/shift-schedule/templates/$code',
      ).replace(
        queryParameters: reason != null && reason.trim().isNotEmpty
            ? {'reason': reason.trim()}
            : null,
      );
      var response = await _http
          .delete(uri, headers: _buildHeaders(includeCsrf: true))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .delete(uri, headers: _buildHeaders(includeCsrf: true))
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã xử lý khung ca thành công.')
              .toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể xóa/ngừng dùng khung ca.').toString(),
        errorCode: (body['errorCode'] ?? 'DELETE_TEMPLATE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi xóa khung ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Tải lịch phân ca tuần (GET /api/manager/shift-schedule/week)
  Future<ApiResult<Map<String, dynamic>>> getWeeklyScheduleRaw({
    String? weekStart,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/manager/shift-schedule/week',
      ).replace(
        queryParameters: weekStart != null && weekStart.isNotEmpty
            ? {'weekStart': weekStart}
            : null,
      );
      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 &&
          body['isSuccess'] == true &&
          body['data'] is Map<String, dynamic>) {
        return ApiResult.success(
          body['data'] as Map<String, dynamic>,
          message: (body['message'] ?? 'Tải lịch phân ca tuần thành công.')
              .toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải lịch phân ca tuần.').toString(),
        errorCode: (body['errorCode'] ?? 'WEEK_LOAD_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải lịch phân ca tuần.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Gán nhân viên vào ca (POST /api/manager/shift-schedule/assignments)
  Future<ApiResult<Map<String, dynamic>>> assignStaffToShiftRaw(
    Map<String, dynamic> payloadMap,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode(payloadMap);
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/shift-schedule/assignments'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/manager/shift-schedule/assignments'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['isSuccess'] == true &&
          body['data'] is Map<String, dynamic>) {
        return ApiResult.success(
          body['data'] as Map<String, dynamic>,
          message: (body['message'] ?? 'Đã phân công nhân viên thành công.')
              .toString(),
          statusCode: response.statusCode,
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể phân công nhân viên vào ca.').toString(),
        errorCode: (body['errorCode'] ?? 'ASSIGN_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi phân công nhân viên.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Hủy phân công nhân viên (DELETE /api/manager/shift-schedule/assignments/{id})
  Future<ApiResult<bool>> cancelShiftAssignmentRaw(
    int id, {
    String? reason,
  }) async {
    try {
      await _ensureCsrfToken();
      final uri = Uri.parse(
        '$baseUrl/api/manager/shift-schedule/assignments/$id',
      ).replace(
        queryParameters: reason != null && reason.trim().isNotEmpty
            ? {'reason': reason.trim()}
            : null,
      );
      var response = await _http
          .delete(uri, headers: _buildHeaders(includeCsrf: true))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .delete(uri, headers: _buildHeaders(includeCsrf: true))
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã hủy phân công ca.').toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể hủy phân công ca.').toString(),
        errorCode: (body['errorCode'] ?? 'CANCEL_ASSIGN_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi hủy phân công ca.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Công bố lịch tuần (POST /api/manager/shift-schedule/week/publish)
  Future<ApiResult<bool>> publishWeekScheduleRaw(String weekStartIso) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({'weekStart': weekStartIso});
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/shift-schedule/week/publish'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/manager/shift-schedule/week/publish'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          true,
          message: (body['message'] ?? 'Đã công bố lịch phân ca tuần.')
              .toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể công bố lịch tuần.').toString(),
        errorCode: (body['errorCode'] ?? 'PUBLISH_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi công bố lịch tuần.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Sao chép lịch từ tuần trước (POST /api/manager/shift-schedule/week/copy-previous)
  Future<ApiResult<int>> copyPreviousWeekScheduleRaw(
    String weekStartIso,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({'weekStart': weekStartIso});
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/shift-schedule/week/copy-previous'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse(
                '$baseUrl/api/manager/shift-schedule/week/copy-previous',
              ),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 8));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ApiResult.success(
          (body['data'] as num?)?.toInt() ?? 0,
          message: (body['message'] ?? 'Đã sao chép lịch tuần trước.')
              .toString(),
        );
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể sao chép lịch tuần trước.').toString(),
        errorCode: (body['errorCode'] ?? 'COPY_WEEK_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi sao chép lịch tuần trước.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy trạng thái Ollama & ngữ cảnh cửa hàng (GET /api/manager/ai-assistant/status)
  Future<ApiResult<Map<String, dynamic>>> getAiAssistantStatusRaw() async {
    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl/api/manager/ai-assistant/status'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã đồng bộ trạng thái Daylight AI.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể kiểm tra trạng thái Daylight AI.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'AI_STATUS_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi kiểm tra trạng thái Daylight AI.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Gửi tin nhắn chat tới Daylight AI qua Ollama local (POST /api/manager/ai-assistant/chat)
  Future<ApiResult<Map<String, dynamic>>> sendAiChatMessageRaw(
    Map<String, dynamic> payloadMap,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode(payloadMap);
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/ai-assistant/chat'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 125));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/manager/ai-assistant/chat'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 125));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Daylight AI đã phản hồi.').toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Daylight AI không thể phản hồi lúc này.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'AI_CHAT_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Hết thời gian chờ hoặc mất kết nối với Daylight AI.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Xác nhận áp dụng Mini-Form của Daylight AI (POST /api/manager/ai-assistant/confirm)
  Future<ApiResult<Map<String, dynamic>>> confirmAiMiniFormRaw(
    Map<String, dynamic> payloadMap,
  ) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode(payloadMap);
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/ai-assistant/confirm'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/manager/ai-assistant/confirm'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 15));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã xác nhận áp dụng thay đổi.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể xác nhận áp dụng bản nháp.').toString(),
        errorCode: (body['errorCode'] ?? 'AI_CONFIRM_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi xác nhận Mini-Form.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy trạng thái thanh toán VietQR & giao dịch của 1 đơn (GET /api/payments/orders/{orderId})
  Future<ApiResult<Map<String, dynamic>>> getOrderPaymentStateRaw(
    int orderId,
  ) async {
    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl/api/payments/orders/$orderId'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã tải trạng thái thanh toán.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải trạng thái thanh toán.').toString(),
        errorCode: (body['errorCode'] ?? 'PAYMENT_STATE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải trạng thái thanh toán.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Sinh hoặc làm mới mã VietQR cho đơn (POST /api/payments/orders/{orderId}/vietqr)
  Future<ApiResult<Map<String, dynamic>>> generateOrderVietQrRaw(
    int orderId,
  ) async {
    try {
      await _ensureCsrfToken();
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/payments/orders/$orderId/vietqr'),
            headers: _buildHeaders(includeCsrf: true),
            body: '{}',
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/payments/orders/$orderId/vietqr'),
              headers: _buildHeaders(includeCsrf: true),
              body: '{}',
            )
            .timeout(const Duration(seconds: 10));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã tạo mã VietQR.').toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tạo mã VietQR.').toString(),
        errorCode: (body['errorCode'] ?? 'VIETQR_CREATE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tạo mã VietQR.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Ghi nhận thu tiền mặt cho đơn (POST /api/payments/orders/{orderId}/cash)
  Future<ApiResult<Map<String, dynamic>>> recordCashPaymentRaw(
    int orderId, {
    int? receivedAmountVnd,
    String? note,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({
        'receivedAmountVnd': receivedAmountVnd,
        'note': note,
      });
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/payments/orders/$orderId/cash'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/payments/orders/$orderId/cash'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 10));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã thu tiền mặt thành công.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể ghi nhận thanh toán tiền mặt.')
            .toString(),
        errorCode: (body['errorCode'] ?? 'CASH_PAYMENT_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi thu tiền mặt.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Giả lập webhook ngân hàng báo nhận tiền (Dev only - POST /api/payments/demo/simulate-webhook)
  Future<ApiResult<Map<String, dynamic>>> simulateVietQrWebhookRaw({
    required String referenceCode,
    required int amountVnd,
    String? bankTransactionId,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({
        'referenceCode': referenceCode,
        'amountVnd': amountVnd,
        'bankTransactionId': bankTransactionId,
        'gateway': 'MBBank (Demo)',
      });
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/payments/demo/simulate-webhook'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse('$baseUrl/api/payments/demo/simulate-webhook'),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 10));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã xử lý webhook giả lập.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể giả lập webhook.').toString(),
        errorCode: (body['errorCode'] ?? 'SIMULATE_WEBHOOK_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi giả lập webhook.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Lấy danh sách đối soát giao dịch (GET /api/manager/reconciliation)
  Future<ApiResult<Map<String, dynamic>>> getReconciliationRaw({
    String filter = 'all',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/manager/reconciliation',
      ).replace(queryParameters: {'filter': filter});
      final response = await _http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã tải danh sách đối soát.')
                .toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể tải danh sách đối soát.').toString(),
        errorCode: (body['errorCode'] ?? 'RECONCILIATION_LOAD_FAILED')
            .toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi tải danh sách đối soát.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  /// Xác nhận đã xử lý đối soát giao dịch (POST /api/manager/reconciliation/{id}/resolve)
  Future<ApiResult<Map<String, dynamic>>> resolveReconciliationRaw(
    int transactionId, {
    required String resolutionNote,
  }) async {
    try {
      await _ensureCsrfToken();
      final payload = jsonEncode({'resolutionNote': resolutionNote});
      var response = await _http
          .post(
            Uri.parse('$baseUrl/api/manager/reconciliation/$transactionId/resolve'),
            headers: _buildHeaders(includeCsrf: true),
            body: payload,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 400 &&
          _decodeJson(response.body)['errorCode'] == 'INVALID_CSRF_TOKEN') {
        await refreshAntiforgeryToken();
        response = await _http
            .post(
              Uri.parse(
                '$baseUrl/api/manager/reconciliation/$transactionId/resolve',
              ),
              headers: _buildHeaders(includeCsrf: true),
              body: payload,
            )
            .timeout(const Duration(seconds: 10));
      }
      final body = _decodeJson(response.body);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ApiResult.success(
            data,
            message: (body['message'] ?? 'Đã hoàn tất đối soát.').toString(),
          );
        }
      }
      return ApiResult.failure(
        (body['message'] ?? 'Không thể xác nhận đối soát.').toString(),
        errorCode: (body['errorCode'] ?? 'RECONCILE_RESOLVE_FAILED').toString(),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResult.failure(
        'Lỗi kết nối khi xác nhận đối soát.',
        errorCode: 'NETWORK_ERROR',
        statusCode: 503,
      );
    }
  }

  static Map<String, dynamic> _decodeJson(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
