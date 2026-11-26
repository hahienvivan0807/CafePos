import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pinvutru_cafe_pos/main.dart';
import 'package:pinvutru_cafe_pos/nen_tang/mang/cong_api.dart';

void main() {
  PosAuthApiClient buildMockApiClient({
    bool initiallyAuthenticatedManager = false,
  }) {
    bool isAuthenticated = initiallyAuthenticatedManager;

    final mockHttp = MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/auth/me') {
        if (!isAuthenticated) {
          return http.Response(
            jsonEncode({
              'isSuccess': false,
              'errorCode': 'UNAUTHORIZED',
              'message': 'Phiên đăng nhập đã hết hạn hoặc chưa đăng nhập.',
            }),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'message': 'Khôi phục phiên đăng nhập thành công.',
            'data': {
              'user': {
                'userId': '11111111-1111-1111-1111-111111111111',
                'username': 'pinvutru',
                'staffCode': 'PINVUTRU',
                'fullName': 'pinvutru',
                'title': 'Quản lý cửa hàng',
                'phoneNumber': '0901234567',
                'roles': ['Manager'],
              },
              'activeShift': null,
              'csrfToken': 'csrf-test-token-123',
              'nextAction': 'ENTER_MANAGER',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (path == '/api/auth/login') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final identifier = (body['identifier'] ?? '').toString();
        final password = (body['password'] ?? '').toString();

        if (identifier.toLowerCase() == 'pinvutru' && password == 'ValidPass123') {
          isAuthenticated = true;
          return http.Response(
            jsonEncode({
              'isSuccess': true,
              'message': 'Đăng nhập thành công.',
              'data': {
                'user': {
                  'userId': '11111111-1111-1111-1111-111111111111',
                  'username': 'pinvutru',
                  'staffCode': 'PINVUTRU',
                  'fullName': 'pinvutru',
                  'title': 'Quản lý cửa hàng',
                  'phoneNumber': '0901234567',
                  'roles': ['Manager'],
                },
                'activeShift': null,
                'csrfToken': 'csrf-test-token-123',
                'nextAction': 'ENTER_MANAGER',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response(
          jsonEncode({
            'isSuccess': false,
            'errorCode': 'INVALID_CREDENTIALS',
            'message': 'Tên đăng nhập hoặc mật khẩu không chính xác.',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (path == '/api/dashboard/manager-overview') {
        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'message': 'Thành công',
            'data': {
              'totalTables': 3,
              'emptyTables': 3,
              'occupiedTables': 0,
              'awaitingQrTables': 0,
              'addOnTables': 0,
              'areas': [
                {'areaName': 'Tầng 1 - Khu phục vụ', 'tableCount': 3},
              ],
              'tables': [
                {
                  'tableId': 1,
                  'tableCode': 'T01',
                  'tableName': 'Bàn 01',
                  'areaName': 'Tầng 1 - Khu phục vụ',
                  'visualStatus': 'EMPTY',
                  'badgeText': 'Bàn trống',
                  'displayAmountVnd': 0,
                  'totalItemsCount': 0,
                },
              ],
              'categories': [
                {'id': 1, 'code': 'COFFEE', 'name': 'Cà phê', 'itemCount': 2},
              ],
              'menuItems': [
                {
                  'id': 1,
                  'categoryId': 1,
                  'categoryCode': 'COFFEE',
                  'categoryName': 'Cà phê',
                  'code': 'CA-PHE-SUA',
                  'name': 'Cà phê sữa',
                  'priceVnd': 30000,
                  'isActive': true,
                },
              ],
              'syncedAt': '2026-11-23T12:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (path == '/api/manager/staff' && request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'message': 'Thành công',
            'data': [
              {
                'id': '22222222-2222-2222-2222-222222222221',
                'staffCode': 'NV01',
                'fullName': 'Nguyễn Minh Khang',
                'phoneNumber': '0909111222',
                'username': 'nv01',
                'role': 'Staff',
                'isActive': true,
              },
              {
                'id': '22222222-2222-2222-2222-222222222222',
                'staffCode': 'NV02',
                'fullName': 'Trần Thảo Vy',
                'phoneNumber': '0909333444',
                'username': 'nv02',
                'role': 'Staff',
                'isActive': true,
              },
              {
                'id': '22222222-2222-2222-2222-222222222223',
                'staffCode': 'NV03',
                'fullName': 'Lê Hoàng Phúc',
                'phoneNumber': '0909555666',
                'username': 'nv03',
                'role': 'Staff',
                'isActive': false,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (path == '/api/auth/logout') {
        isAuthenticated = false;
        return http.Response(
          jsonEncode({
            'isSuccess': true,
            'message': 'Đã đăng xuất khỏi hệ thống POS.',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return http.Response('{}', 404);
    });

    return PosAuthApiClient(
      baseUrl: 'https://localhost:7179',
      httpClient: mockHttp,
    );
  }

  testWidgets(
    'Màn 01 · Đăng nhập kiểm tra trường bắt buộc, báo lỗi tiếng Việt và đi thẳng vào Manager Shell khi đăng nhập thành công',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final apiClient = buildMockApiClient();

      await tester.pumpWidget(
        CafePosApp(apiClient: apiClient, autoRestoreSession: false),
      );

      expect(find.text('Tên đăng nhập'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);

      // 1. Kiểm tra trường bắt buộc khi để trống
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Vui lòng nhập Tên đăng nhập.'), findsOneWidget);
      expect(find.text('Vui lòng nhập Mật khẩu.'), findsOneWidget);

      // 2. Nhập sai mật khẩu -> hiển thị lỗi tiếng Việt từ API
      await tester.enterText(
        find.byKey(const Key('login_username_input')),
        'pinvutru',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_input')),
        'WrongPass',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Tên đăng nhập hoặc mật khẩu không chính xác.'),
        findsOneWidget,
      );

      // 3. Nhập đúng tài khoản Manager -> đi thẳng vào giao diện Quản lý (ManagerShellScreen)
      await tester.enterText(
        find.byKey(const Key('login_password_input')),
        'ValidPass123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Tổng quan quản lý'), findsOneWidget);
      expect(find.text('Điểm vào POS / Sơ đồ bàn'), findsOneWidget);
      expect(find.text('Đối soát & Duyệt hủy món'), findsOneWidget);
      expect(find.text('Báo cáo & Dự báo'), findsOneWidget);
      expect(find.text('Trợ lý AI tiếng Việt'), findsOneWidget);
      expect(find.text('Cà phê sữa'), findsOneWidget);

      // 4. Kiểm tra Màn 24 (Quản lý nhân viên) hiển thị 3 nhân sự + Modal 25 (Thêm) + Modal 26 (Chỉnh sửa)
      await tester.tap(find.byKey(const Key('nav_manager_staff')));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Khang'), findsOneWidget);
      expect(find.text('Trần Thảo Vy'), findsOneWidget);
      expect(find.text('Lê Hoàng Phúc'), findsOneWidget);
      expect(find.text('Hiển thị 3 trên tổng số 3 nhân sự'), findsOneWidget);

      // Mở Modal 25 · Thêm nhân viên
      await tester.tap(find.byKey(const Key('nv_btn_them_moi')));
      await tester.pumpAndSettle();
      expect(find.text('1. THÔNG TIN NHÂN VIÊN'), findsOneWidget);
      expect(find.text('2. TÀI KHOẢN POS'), findsOneWidget);
      await tester.tap(find.byKey(const Key('modal_them_nv_huy')));
      await tester.pumpAndSettle();

      // Mở Modal 26 · Chỉnh sửa nhân viên từ dòng dữ liệu thật nv01
      await tester.tap(find.byKey(const Key('nv_btn_sua_nv01')));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa nhân viên'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('modal_sua_nv_huy')));
      await tester.pumpAndSettle();

      // 5. Kiểm tra chuyển tab sang Đối soát và Đăng xuất
      await tester.tap(find.byKey(const Key('nav_manager_reconciliation')));
      await tester.pumpAndSettle();
      expect(
        find.text('Đối soát VietQR, Thu dư & Duyệt yêu cầu hủy món'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('manager_logout_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_username_input')), findsOneWidget);
    },
  );

  testWidgets(
    'Bảo vệ đường dẫn /manager khi chưa đăng nhập và không bị tràn ngang ở kích thước màn hình nhỏ 320px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final apiClient = buildMockApiClient(initiallyAuthenticatedManager: false);

      await tester.pumpWidget(
        CafePosApp(
          apiClient: apiClient,
          autoRestoreSession: true,
          initialRoutePath: '/manager',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Phiên Quản lý chưa đăng nhập hoặc đã hết hạn'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
