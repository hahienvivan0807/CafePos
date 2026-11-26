using CafePosTracker.Models;
using Microsoft.EntityFrameworkCore;

namespace CafePosTracker.Data;

/// <summary>
/// Seed dữ liệu nghiệp vụ từ PROJECT.md theo cơ chế idempotent:
/// không nhân đôi bản ghi và không ghi đè IsCompleted / CompletedAt / UpdatedAt đã lưu.
/// </summary>
public static class TrackerSeeder
{
    public static async Task SeedAsync(TrackerDbContext db, CancellationToken cancellationToken = default)
    {
        var groupDefs = new List<(string Code, string Name, string Description, int Order)>
        {
            ("STAFF", "Nhân viên", "Các màn hình phục vụ tại bàn, ghi món, yêu cầu hủy và thanh toán VietQR cho nhân viên.", 1),
            ("MANAGER", "Quản lý", "Các màn hình quản trị menu, duyệt hủy món, đối soát giao dịch, báo cáo, dự báo và trợ lý AI.", 2),
            ("BACKEND", "Backend", "API ASP.NET Core, xử lý nghiệp vụ, webhook VietQR, mô hình dự báo Python và trợ lý AI local.", 3)
        };

        var existingGroups = await db.WorkGroups.ToDictionaryAsync(g => g.Code, cancellationToken);
        foreach (var def in groupDefs)
        {
            if (!existingGroups.TryGetValue(def.Code, out var group))
            {
                group = new WorkGroup
                {
                    Code = def.Code,
                    Name = def.Name,
                    Description = def.Description,
                    DisplayOrder = def.Order
                };
                db.WorkGroups.Add(group);
                existingGroups[def.Code] = group;
            }
            else
            {
                group.Name = def.Name;
                group.Description = def.Description;
                group.DisplayOrder = def.Order;
            }
        }

        await db.SaveChangesAsync(cancellationToken);

        var now = DateTime.UtcNow;
        var itemDefs = new List<(string GroupCode, string Code, string Title, string ShortDesc, string Criteria, string? StatusNote, bool IsOpenDecision, int Order)>
        {
            // ===== NHÂN VIÊN =====
            (
                "STAFF",
                "STAFF_TABLE_MAP",
                "Sơ đồ bàn",
                "Hiển thị trạng thái Trống / Đang có khách theo thời gian thực và thao tác mở bàn tạo lượt sử dụng mới.",
                "• Phân biệt rõ trạng thái bàn Trống và Đang có khách.\n• Chạm bàn Trống để mở bàn và khởi tạo một lượt sử dụng mới.\n• Chạm bàn Đang có khách để đi thẳng vào Chi tiết lượt sử dụng.",
                null,
                false,
                1
            ),
            (
                "STAFF",
                "STAFF_SESSION_DETAIL",
                "Chi tiết lượt sử dụng bàn",
                "Hiển thị các đơn trong cùng một lượt (nhiều đơn đã trả, tối đa 1 đơn mở/chờ thanh toán) và xử lý đủ 4 thời điểm ca B07.",
                "• Hiển thị danh sách đơn thuộc lượt hiện tại và món trong từng đơn.\n• Đảm bảo tối đa 1 đơn đang mở hoặc chờ thanh toán trên cùng lượt.\n• Đặc tả rõ nút khả dụng và điều kiện thao tác ở 4 thời điểm ca B07: đơn A đang mở, A chờ thanh toán, A đã trả khi khách còn ngồi, và đơn B được tạo.",
                null,
                false,
                2
            ),
            (
                "STAFF",
                "STAFF_TEMP_CART",
                "Giỏ tạm & chỉnh sửa trước khi ghi",
                "Cho phép nhân viên thêm món, tăng/giảm số lượng, xóa hoặc ghi chú món trong giỏ tạm trước khi gửi ghi món.",
                "• Nhân viên tự do thêm, sửa, xóa món khi còn ở giỏ tạm.\n• Không tạo bản ghi lịch sử hủy khi chỉnh sửa trong giỏ tạm.\n• Tính tạm tính rõ ràng trước khi bấm Ghi món.",
                null,
                false,
                3
            ),
            (
                "STAFF",
                "STAFF_ORDER_RECORD",
                "Ghi món vào đơn",
                "Xác nhận ghi món từ giỏ tạm vào đơn đang mở, lưu snapshot đơn giá tại thời điểm bán, người ghi và thời điểm.",
                "• Lưu đúng món, số lượng, đơn giá tại thời điểm bán (không bị lệch nếu menu đổi giá sau đó).\n• Ghi nhận người ghi và timestamp đầy đủ.\n• Sau khi ghi thành công, món chuyển sang trạng thái đã ghi trên đơn.",
                null,
                false,
                4
            ),
            (
                "STAFF",
                "STAFF_CANCEL_REQUEST",
                "Yêu cầu hủy món đã ghi",
                "Gửi yêu cầu hủy đối với món đã ghi kèm lý do bắt buộc để chuyển cho quản lý duyệt.",
                "• Không cho nhân viên xóa thẳng món đã ghi.\n• Bắt buộc nhập lý do hủy món.\n• Hiển thị trạng thái Chờ duyệt hủy trên dòng món và giữ nguyên dòng gốc.",
                null,
                false,
                5
            ),
            (
                "STAFF",
                "STAFF_VIETQR_DISPLAY",
                "Hiển thị VietQR thanh toán",
                "Tạo mã VietQR theo tài khoản nhận cố định, số tiền còn phải thu và mã tham chiếu riêng cho mỗi lần phát hành.",
                "• Mỗi lần phát hành QR gắn một mã tham chiếu duy nhất.\n• Khi gọi thêm món làm đổi số tiền (vd 65.000đ lên 90.000đ), ngừng hiển thị QR cũ ngay lập tức.\n• Tự động cập nhật trạng thái đơn sang Đã thanh toán khi nhận xác nhận đủ tiền.",
                null,
                false,
                6
            ),
            (
                "STAFF",
                "STAFF_PAID_ORDER_CLOSE_TABLE",
                "Xem chi tiết đơn đã trả & trả bàn",
                "Xem lại chi tiết món của đơn đã thanh toán và bấm Trả bàn để kết thúc lượt, đưa bàn về Trống.",
                "• Khi đơn đủ tiền, đơn chuyển Đã thanh toán nhưng bàn vẫn giữ trạng thái Đang có khách.\n• Chỉ cho phép bấm Trả bàn khi mọi đơn trong lượt đã được xử lý xong.\n• Sau khi trả bàn, bàn quay về Trống và sẵn sàng cho lượt mới.",
                null,
                false,
                7
            ),
            (
                "STAFF",
                "STAFF_PHYSICAL_BILL_PRINT",
                "In bill vật lý",
                "Màn hình xem chi tiết đơn đã thanh toán đã có trong bản đầu; phần thiết bị in, in giấy và tự in đang để ngỏ.",
                "• Bản MVP hiển thị đầy đủ chi tiết đơn đã thanh toán trên màn hình.\n• Chốt lại phạm vi hỗ trợ máy in nhiệt / khổ giấy / tự in ở giai đoạn tiếp theo nếu quán cần.",
                "Quyết định đang để ngỏ",
                true,
                8
            ),

            // ===== QUẢN LÝ =====
            (
                "MANAGER",
                "MGR_MENU_PRICE",
                "Quản lý menu và giá bán",
                "Tạo, chỉnh sửa món, cập nhật giá bán, nhóm món và trạng thái còn/hết phục vụ.",
                "• Cập nhật giá mới không làm thay đổi đơn giá đã ghi trong các đơn cũ.\n• Hỗ trợ tìm kiếm và lọc món theo danh mục.\n• Đồng bộ dữ liệu món thật để trợ lý AI tra cứu khi tạo Mini-Form.",
                null,
                false,
                1
            ),
            (
                "MANAGER",
                "MGR_CANCEL_APPROVAL",
                "Duyệt hoặc từ chối hủy món",
                "Xem danh sách yêu cầu hủy món từ nhân viên kèm lý do và thực hiện duyệt hoặc từ chối.",
                "• Hiển thị rõ bàn, đơn, món, số lượng, người yêu cầu và lý do hủy.\n• Cho phép Duyệt hoặc Từ chối kèm ghi chú xử lý.\n• Cập nhật tổng tiền đơn ngay khi duyệt hủy thành công.",
                null,
                false,
                2
            ),
            (
                "MANAGER",
                "MGR_RECONCILIATION",
                "Đối soát giao dịch & thu dư",
                "Theo dõi giao dịch VietQR, xử lý các ca thanh toán muộn hoặc nhận cả QR cũ lẫn QR mới vào mục Cần đối soát.",
                "• Hiển thị rõ giao dịch hợp lệ, giao dịch trùng webhook đã bỏ qua và khoản thu dư.\n• Với ca nhận cả 65.000đ và 90.000đ: đơn thu đủ 90.000đ, phần 65.000đ vào danh sách Cần đối soát.\n• Cho phép đánh dấu trạng thái đã xử lý đối soát.",
                null,
                false,
                3
            ),
            (
                "MANAGER",
                "MGR_REPORTS",
                "Báo cáo doanh thu, lợi nhuận & món bán chạy",
                "Dashboard xem doanh thu, lợi nhuận, món bán chạy và hoàn tiền theo khoảng thời gian.",
                "• Chốt cách tính doanh thu, lợi nhuận, hoàn tiền và giá vốn dùng chung với backend.\n• Số liệu khớp 100% với câu trả lời của trợ lý AI qua Tool Calling.\n• Hỗ trợ lọc theo ngày, tuần, tháng.",
                null,
                false,
                4
            ),
            (
                "MANAGER",
                "MGR_FORECAST",
                "Dự báo doanh thu & đề xuất nhập nguyên liệu",
                "Hiển thị dự báo doanh thu từ mô hình tự huấn luyện và gợi ý lượng nguyên liệu cần nhập.",
                "• So sánh dự báo theo thời gian với mốc cùng thứ tuần trước.\n• Đề xuất nhập nguyên liệu dựa trên dự báo số lượng bán theo món, định mức pha chế và tồn kho hiện tại.\n• Hiển thị rõ độ tin cậy / sai số đánh giá mô hình.",
                null,
                false,
                5
            ),
            (
                "MANAGER",
                "MGR_AI_ASSISTANT",
                "Trợ lý AI tiếng Việt & Mini-Form xác nhận",
                "Giao diện chat hỏi số liệu kinh doanh và nhận bản nháp thao tác nghiệp vụ qua Mini-Form có nút Xác nhận.",
                "• Hỏi số liệu (vd: “Hôm qua quán thu bao nhiêu?”) trả lời bằng tiếng Việt dựa trên số liệu backend.\n• Lệnh thay đổi dữ liệu (vd: “Thứ Bảy giảm bạc xỉu 10%”) render Mini-Form từ JSON values + field_meta.\n• Chỉ lưu thay đổi khi quản lý chủ động bấm Xác nhận (Human-in-the-Loop).",
                null,
                false,
                6
            ),

            // ===== BACKEND =====
            (
                "BACKEND",
                "BE_SESSIONS_ORDERS_API",
                "API Bàn, lượt sử dụng & ghi món",
                "Xây dựng endpoint mở bàn, quản lý lượt sử dụng, tạo đơn, ghi món và ràng buộc tối đa 1 đơn mở/chờ thanh toán.",
                "• Đảm bảo ràng buộc nghiệp vụ: 1 lượt có nhiều đơn đã trả, tối đa 1 đơn đang mở hoặc chờ thanh toán.\n• Lưu snapshot đơn giá tại thời điểm bán, người ghi và thời điểm.\n• Hỗ trợ tạo đơn B trên cùng lượt sau khi đơn A đã thanh toán (ca B07).",
                null,
                false,
                1
            ),
            (
                "BACKEND",
                "BE_CANCEL_AUDIT_API",
                "API Yêu cầu hủy món & lịch sử xử lý",
                "Lưu yêu cầu hủy món, duyệt/từ chối của quản lý và giữ nguyên dòng gốc cùng lịch sử kiểm toán.",
                "• Không xóa vật lý dòng món gốc khi hủy.\n• Lưu đầy đủ trạng thái yêu cầu, lý do, người duyệt/từ chối và thời gian xử lý.\n• Tính lại số tiền phải thu của đơn một cách nhất quán.",
                null,
                false,
                2
            ),
            (
                "BACKEND",
                "BE_VIETQR_WEBHOOK",
                "Phát hành VietQR & Webhook idempotent",
                "Sinh mã tham chiếu riêng mỗi lần tạo QR, hỗ trợ webhook giả lập/thực tế và chống ghi nhận trùng.",
                "• Xác thực nguồn thông báo webhook.\n• Idempotent: webhook gửi lặp cùng mã giao dịch chỉ ghi nhận đúng 1 lần.\n• Cập nhật đơn sang Đã thanh toán khi đủ tiền.",
                null,
                false,
                3
            ),
            (
                "BACKEND",
                "BE_QR_OVERPAYMENT_RECONCILE",
                "Xử lý gọi thêm khi chờ QR & đối soát QR cũ",
                "Giữ mã tham chiếu QR cũ để nhận diện tiền đến muộn, phát hành QR phần chênh lệch hoặc đánh dấu Cần đối soát.",
                "• Chưa nhận tiền -> phát hành QR mới 90.000đ và giữ tham chiếu QR 65.000đ.\n• Đã nhận 65.000đ -> phát hành QR mới 25.000đ và ngừng QR 90.000đ nếu đã hiện.\n• Nhận cả 65.000đ và 90.000đ -> lưu 2 giao dịch, đơn thu đủ 90.000đ, phần 65.000đ vào Cần đối soát.",
                null,
                false,
                4
            ),
            (
                "BACKEND",
                "BE_REPORT_ENGINE",
                "Logic báo cáo dùng chung (C# & PostgreSQL)",
                "Chuẩn hóa công thức doanh thu, lợi nhuận, hoàn tiền, giá vốn cho cả dashboard và trợ lý AI.",
                "• Dùng một nguồn logic duy nhất cho API dashboard và Tool Calling của trợ lý.\n• Kiểm tra phân quyền quản lý và validate khoảng ngày/tham số.\n• Có test đối chiếu công thức doanh thu, lợi nhuận và hoàn tiền.",
                null,
                false,
                5
            ),
            (
                "BACKEND",
                "BE_FORECAST_PYTHON",
                "Mô hình dự báo Python (XGBoost / LightGBM / Prophet)",
                "Huấn luyện mô hình dự báo doanh thu & nhu cầu món theo chu kỳ, phục vụ API cho C# và trợ lý AI.",
                "• Huấn luyện trên lịch sử bán hàng hoặc dữ liệu giả lập có tính chu kỳ.\n• Đánh giá theo thời gian và so sánh với mốc cùng thứ tuần trước.\n• Xuất API dự báo doanh thu và đề xuất nhập nguyên liệu theo định mức + tồn kho.",
                null,
                false,
                6
            ),
            (
                "BACKEND",
                "BE_LOCAL_LLM_TOOLING",
                "Trợ lý AI local (Qwen 2.5 + QLoRA + Ollama/vLLM)",
                "Triển khai model open-weights chạy local, fine-tune 500–1.500 mẫu tiếng Việt, hỗ trợ Tool Calling và Mini-Form JSON.",
                "• Hoàn thiện luồng với model gốc trước khi fine-tune QLoRA bằng Unsloth trên Colab T4.\n• So sánh tập kiểm thử giữ riêng giữa model gốc và fine-tune (chọn công cụ, điền tham số, hỏi lại khi thiếu, từ chối ngoài phạm vi).\n• Trả JSON gồm values và field_meta để Flutter render Mini-Form; C# kiểm tra lại quyền và dữ liệu trước khi lưu.",
                null,
                false,
                7
            )
        };

        var existingItems = await db.WorkItems.ToDictionaryAsync(i => i.Code, cancellationToken);
        foreach (var def in itemDefs)
        {
            var groupId = existingGroups[def.GroupCode].Id;
            if (!existingItems.TryGetValue(def.Code, out var item))
            {
                item = new WorkItem
                {
                    GroupId = groupId,
                    Code = def.Code,
                    Title = def.Title,
                    ShortDescription = def.ShortDesc,
                    AcceptanceCriteria = def.Criteria,
                    StatusNote = def.StatusNote,
                    IsOpenDecision = def.IsOpenDecision,
                    DisplayOrder = def.Order,
                    IsCompleted = false,
                    CompletedAt = null,
                    UpdatedAt = now
                };
                db.WorkItems.Add(item);
            }
            else
            {
                // Chỉ đồng bộ metadata mô tả nghiệp vụ; tuyệt đối không ghi đè tiến độ đã lưu.
                item.GroupId = groupId;
                item.Title = def.Title;
                item.ShortDescription = def.ShortDesc;
                item.AcceptanceCriteria = def.Criteria;
                item.StatusNote = def.StatusNote;
                item.IsOpenDecision = def.IsOpenDecision;
                item.DisplayOrder = def.Order;
            }
        }

        await db.SaveChangesAsync(cancellationToken);
    }
}
