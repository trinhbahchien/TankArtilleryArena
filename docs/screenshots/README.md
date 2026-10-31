# 📸 CẨM NANG HƯỚNG DẪN CHỤP ẢNH THỰC TẾ TRONG GAME
### DỰ ÁN: TANK ARTILLERY ARENA (ĐỒ ÁN TỐT NGHIỆP CÔNG NGHỆ THÔNG TIN)
**Thư mục lưu ảnh:** `d:\Do an 2026\MTA\Godot\TankArtilleryArena\docs\screenshots\`

Tài liệu này là cẩm nang hướng dẫn riêng cho bạn để tự chơi game, chụp lại 8 bức ảnh màn hình thực tế và lưu vào thư mục này. Báo cáo chính [**`BAO_CAO_DO_AN_TANK_ARTILLERY_ARENA.md`**](../BAO_CAO_DO_AN_TANK_ARTILLERY_ARENA.md) đã cài đặt sẵn các liên kết `![...](screenshots/hinh_X.png)`. Khi bạn chụp và lưu đúng tên file, ảnh sẽ tự động hiển thị mượt mà trên báo cáo.

---

## 🛠️ CÁCH CHỤP ẢNH MÀN HÌNH NHANH TRÊN WINDOWS

1. **Phím tắt chụp nhanh:** Nhấn tổ hợp phím **`Windows + Shift + S`**:
   - Kéo chuột chọn toàn bộ cửa sổ game Godot đang chạy.
   - Nhấp vào thông báo góc phải màn hình $\rightarrow$ Chọn **Save As** (hoặc `Ctrl + S`).
   - Lưu vào thư mục: `d:\Do an 2026\MTA\Godot\TankArtilleryArena\docs\screenshots\`.
2. **Khuyến nghị:**
   - Định dạng tệp: **`.png`**.
   - Nên để game ở chế độ cửa sổ lớn hoặc Fullscreen để ảnh nét, rõ chữ số trên HUD.

---

## ✅ CHECKLIST 8 ẢNH CẦN CHỤP VÀ HƯỚNG DẪN THỰC HIỆN

### 1. `hinh_3_1_than_xe_chassis.png`
- **Mục trong Báo cáo:** Hình 3.1 (Trang bị & Vận hành thân xe).
- **Cách vào:** Chạy game $\rightarrow$ Vào **Màn 1** hoặc **Phòng tập Sandbox**.
- **Thao tác:** Nhấn phím `W` hoặc `D` để xe di chuyển và xoay thân xe, đồng thời rê chuột để tháp pháo quay sang một góc khác.
- **Yêu cầu ảnh:** Thấy rõ thân xe độc lập với tháp pháo, 3 mũi tên Chevrons neon xanh cyan nhấp nháy dẫn hướng phía trước mũi xe.

---

### 2. `hinh_3_2_modal_loadout.png`
- **Mục trong Báo cáo:** Hình 3.2 (Cửa sổ Tùy chỉnh hỏa lực).
- **Cách vào:** Tại **Menu Chính** (`MainMenu.tscn`) $\rightarrow$ Bấm nút **"TÙY CHỈNH HỎA LỰC"** (hoặc **"LOADOUT"**).
- **Yêu cầu ảnh:** Hiện cửa sổ Modal ở giữa màn hình với 2 thẻ thông số `PrimaryCard` (Pháo cối / AP / Rocket) và `SecondaryCard` (Súng AP / Súng máy / Shotgun).

---

### 3. `hinh_3_5_delta_force_hud.png`
- **Mục trong Báo cáo:** Hình 3.5 (Bố cục Giao diện Quân sự Delta Force HUD).
- **Cách vào:** Vào **Màn 1** hoặc **Màn 2**.
- **Thao tác:** Rê chuột ngắm mục tiêu.
- **Yêu cầu ảnh:**
  - Đáy màn hình: Thanh máu đổi màu kèm thông số `DIST` (cự ly) và `SPD` (vận tốc).
  - Góc trái dưới: Card vũ khí hiển thị hỏa lực chính/phụ và thời gian hồi chiêu [E], [Q].
  - Góc phải dưới: Minimap Radar Sonar 360° quét mục tiêu.
  - Vùng chính giữa: Hoàn toàn thông thoáng không bị che khuất.

---

### 4. `hinh_4_1_bando_10_man_choi.png`
- **Mục trong Báo cáo:** Hình 4.1 (Bản đồ Chiến thuật 10 Màn chơi Chiến dịch).
- **Cách vào:** Tại Menu chính $\rightarrow$ Bấm nút **"CHỌN MÀN CHIẾN DỊCH"** (`LevelSelectMenu.tscn`).
- **Yêu cầu ảnh:** Bảng danh sách lưới 10 ô màn chơi từ Màn 1 đến Màn 10, hiển thị số sao đạt được và nút vào **Phòng tập Tác chiến Sandbox**.

---

### 5. `hinh_4_2_menu_chinh_loadout.png`
- **Mục trong Báo cáo:** Hình 4.2 (Giao diện Menu Chính).
- **Cách vào:** Vừa mở game lên ở màn hình đầu tiên (`MainMenu.tscn`).
- **Yêu cầu ảnh:** Toàn cảnh Menu Chính với tiêu đề game nổi bật, nền chiến trường quân sự và các nút chức năng (Chiến dịch, Chọn màn, Phòng tập, Tùy chỉnh hỏa lực, Thoát game).

---

### 6. `hinh_4_3_camera_zoom_radar.png`
- **Mục trong Báo cáo:** Hình 4.3 (Trận địa mở rộng với Camera Zoom và Radar).
- **Cách vào:** Vào **Màn 3 (Kho Xăng)** hoặc **Màn 7 (Phản Kích)**.
- **Thao tác:** Lăn con lăn chuột xuống để thu nhỏ camera về mức **0.65** hoặc **0.48**.
- **Yêu cầu ảnh:** Tầm nhìn chiến trường cực rộng, bao quát được nhiều chướng ngại vật tường bê tông, thùng phuy xăng và các chấm đỏ kẻ địch hiển thị trên Minimap Radar.

---

### 7. `hinh_4_4_boss_mammoth_man_10.png`
- **Mục trong Báo cáo:** Hình 4.4 (Đại chiến Siêu Trùm Mammoth Boss tại Màn 10).
- **Cách vào:** Vào **Màn 10 (Quyết Chiến Mammoth)**.
- **Thao tác:** Tiến vào giữa đấu trường đối đầu Siêu Xe Tăng Trùm Mammoth khổng lồ.
- **Yêu cầu ảnh:** Màn hình đại chiến gay cấn: thanh máu trùm Mammoth (350 HP), hiệu ứng pháo cối nổ cam hoặc chùm đạn shotgun 5 tia, khói lửa chiến trường.

---

### 8. `hinh_4_5_man_hinh_chien_thang.png`
- **Mục trong Báo cáo:** Hình 4.5 (Màn hình Chiến thắng & Xếp hạng 5 Sao).
- **Cách vào:** Tiêu diệt hết địch trong bất kỳ màn chơi nào (hoặc hạ gục trùm ở Màn 10).
- **Yêu cầu ảnh:** Bảng tổng kết chiến thắng hiển thị thời gian tác chiến (`TIME`), điểm số thưởng (`SCORE`), biểu tượng vinh danh `⭐⭐⭐⭐⭐ [MAX CẤP CHIẾN THẦN]` và các nút điều hướng.
