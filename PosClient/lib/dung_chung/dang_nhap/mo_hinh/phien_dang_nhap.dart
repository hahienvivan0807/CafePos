class UserProfileModel {
  final String userId;
  final String username;
  final String staffCode;
  final String fullName;
  final String title;
  final String? phoneNumber;
  final List<String> roles;

  const UserProfileModel({
    required this.userId,
    required this.username,
    required this.staffCode,
    required this.fullName,
    required this.title,
    this.phoneNumber,
    required this.roles,
  });

  bool get isManager =>
      roles.any((r) => r.toLowerCase() == 'manager');

  bool get isStaff =>
      roles.any((r) => r.toLowerCase() == 'staff');

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final parsedRoles = <String>[];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        if (item != null) {
          parsedRoles.add(item.toString());
        }
      }
    }

    return UserProfileModel(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      staffCode: (json['staffCode'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      roles: parsedRoles,
    );
  }
}

class ShiftModel {
  final String shiftId;
  final String userId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? openNote;
  final String? closeNote;

  const ShiftModel({
    required this.shiftId,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.openNote,
    this.closeNote,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      shiftId: (json['shiftId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt:
          DateTime.tryParse((json['startedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())?.toLocal()
          : null,
      openNote: json['openNote']?.toString(),
      closeNote: json['closeNote']?.toString(),
    );
  }
}

class AuthSessionModel {
  final UserProfileModel user;
  final ShiftModel? activeShift;
  final String csrfToken;
  final String nextAction;

  const AuthSessionModel({
    required this.user,
    this.activeShift,
    required this.csrfToken,
    required this.nextAction,
  });

  bool get isManager => user.isManager;

  AuthSessionModel copyWith({
    UserProfileModel? user,
    ShiftModel? activeShift,
    bool clearActiveShift = false,
    String? csrfToken,
    String? nextAction,
  }) {
    return AuthSessionModel(
      user: user ?? this.user,
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      csrfToken: csrfToken ?? this.csrfToken,
      nextAction: nextAction ?? this.nextAction,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? const {};
    final shiftMap = json['activeShift'] as Map<String, dynamic>?;

    return AuthSessionModel(
      user: UserProfileModel.fromJson(userMap),
      activeShift: shiftMap != null ? ShiftModel.fromJson(shiftMap) : null,
      csrfToken: (json['csrfToken'] ?? '').toString(),
      nextAction: (json['nextAction'] ?? '').toString(),
    );
  }
}

class ApiResult<T> {
  final bool isSuccess;
  final int statusCode;
  final String errorCode;
  final String message;
  final T? data;

  const ApiResult({
    required this.isSuccess,
    required this.statusCode,
    this.errorCode = '',
    required this.message,
    this.data,
  });

  factory ApiResult.success(
    T data, {
    String message = 'Thành công',
    int statusCode = 200,
  }) {
    return ApiResult<T>(
      isSuccess: true,
      statusCode: statusCode,
      message: message,
      data: data,
    );
  }

  factory ApiResult.failure(
    String message, {
    String errorCode = 'ERROR',
    int statusCode = 400,
  }) {
    return ApiResult<T>(
      isSuccess: false,
      statusCode: statusCode,
      errorCode: errorCode,
      message: message,
    );
  }
}
