-- ============================================================================
-- PinVuTru Cafe POS - PostgreSQL Schema (Database: cafe_pos, Schema: pos)
-- Đồng bộ 100% với 01-pos-schema.sql và bổ sung bảng pos."CaLamViec"
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS pos;
SET search_path = pos, public;

CREATE TABLE IF NOT EXISTS pos."CaLamViec" (
    "Id" uuid PRIMARY KEY,
    "IdNguoiDung" uuid NOT NULL REFERENCES pos."NguoiDung" ("Id") ON DELETE CASCADE,
    "TrangThai" varchar(20) NOT NULL DEFAULT 'DangMo'
        CHECK ("TrangThai" IN ('DangMo', 'DaDong')),
    "BatDauLuc" timestamptz NOT NULL DEFAULT now(),
    "KetThucLuc" timestamptz,
    "GhiChuMoCa" text,
    "GhiChuKetCa" text,
    CHECK (("TrangThai" = 'DaDong') = ("KetThucLuc" IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS "IdxCaLamViecNguoiDung"
    ON pos."CaLamViec" ("IdNguoiDung");

-- Ràng buộc mỗi nhân viên có tối đa 1 ca đang mở (TrangThai = 'DangMo')
-- Chống tạo trùng ca làm việc khi bấm đúp 2 lần liên tiếp
CREATE UNIQUE INDEX IF NOT EXISTS "UqCaLamViecDangMoMoiNguoi"
    ON pos."CaLamViec" ("IdNguoiDung")
    WHERE "TrangThai" = 'DangMo';
