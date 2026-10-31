# TỔNG HỢP MÃ SƠ ĐỒ MERMAID CHUẨN HÓA IN ẤN & TỐI ƯU KHỔ WORD A4
> **Đồ án:** Nghiên Cứu Công Nghệ Game Engine và Phát Triển Game Chiến Thuật Pháo Binh 2.5D (Dự án: Tank Artillery Arena)  
> **Tài liệu tham chiếu:** `docs/BAO_CAO_DO_AN_TANK_ARTILLERY_ARENA.md`  
> **Mục đích tài liệu:** Cung cấp mã nguồn Mermaid đã chuẩn hóa toàn bộ về phong cách đồ họa tương phản cao trên nền trắng (High-Contrast Monochrome / Technical Blueprint), kích thước phông chữ lớn (18px - 22px), nét vẽ đậm (2px) và bố cục kiểm soát chặt chẽ chiều rộng để khi dán vào Microsoft Word khổ giấy A4 không bị tràn lề, không bị thu nhỏ làm mờ chữ.

---

## PHẦN 1. BẢNG PHÂN LOẠI TOÀN BỘ HÌNH ẢNH TRONG BÁO CÁO

Trong báo cáo đồ án gồm tổng cộng **14 hình ảnh**, được phân chia rành mạch thành 2 nhóm:

| Số hiệu Hình | Tên hình ảnh trong Báo cáo | Phân loại | Phương thức thực hiện |
| :---: | :--- | :---: | :--- |
| **Hình 2.1** | Sơ đồ Kiến trúc Tổng thể Hệ thống Scene-Node & Signal Bus | **Sơ đồ Kỹ thuật** | **Mã Mermaid (Sơ đồ 1 bên dưới)** |
| **Hình 2.2** | Mô hình Quỹ đạo Đạn Parabola 2.5D và Độ cao ảo $z(t)$ | **Sơ đồ Thuật toán** | **Mã Mermaid (Sơ đồ 2 bên dưới)** |
| **Hình 2.3** | Sơ đồ Thuật toán Khóa Cự ly Ngắm Vành khăn (Annulus Aim Clamp) | **Sơ đồ Thuật toán** | **Mã Mermaid (Sơ đồ 3 bên dưới)** |
| **Hình 2.4** | Mô hình Máy Trạng thái Hữu hạn AI Xe Tăng Địch (AI FSM) | **Sơ đồ Trạng thái** | **Mã Mermaid (Sơ đồ 4 bên dưới)** |
| **Hình 3.1** | Mô hình Thân xe Độc lập với Tháp pháo và Chỉ báo Neon Chevrons | Ảnh chụp thực tế | Chụp trong game (`hinh_3_1_than_xe_chassis.png`) |
| **Hình 3.2** | Bố cục Cửa sổ Tùy chỉnh Hỏa lực Chiến Tăng (Tactical Loadout Modal) | Ảnh chụp thực tế | Chụp trong game (`hinh_3_2_modal_loadout.png`) |
| **Hình 3.3** | Chu trình Súng máy Tăng tốc (Spool-Up) và Quá nhiệt Nòng súng | **Sơ đồ Giải thuật** | **Mã Mermaid (Sơ đồ 5 bên dưới)** |
| **Hình 3.4** | Cơ chế Màn khói Tác chiến Điện tử làm Nhiễu loạn Tên lửa | **Sơ đồ Giải thuật** | **Mã Mermaid (Sơ đồ 6 bên dưới)** |
| **Hình 3.5** | Bố cục Giao diện Quân sự Tối giản (Delta Force HUD) & Camera Zoom | Ảnh chụp thực tế | Chụp trong game (`hinh_3_5_delta_force_hud.png`) |
| **Hình 4.1** | Bản đồ Chiến thuật 10 Màn chơi Chiến dịch và Phòng tập Sandbox | Ảnh chụp thực tế | Chụp trong game (`hinh_4_1_bando_10_man_choi.png`) |
| **Hình 4.2** | Giao diện Menu Chính và Cửa sổ Lựa chọn Trang bị Hỏa lực | Ảnh chụp thực tế | Chụp trong game (`hinh_4_2_menu_chinh_loadout.png`) |
| **Hình 4.3** | Trận địa Mở rộng với Góc nhìn Camera Zoom 0.65 và Minimap Radar | Ảnh chụp thực tế | Chụp trong game (`hinh_4_3_camera_zoom_radar.png`) |
| **Hình 4.4** | Đại chiến Siêu Xe Tăng Trùm Cuối Mammoth Boss tại Màn 10 | Ảnh chụp thực tế | Chụp trong game (`hinh_4_4_boss_mammoth_man_10.png`) |
| **Hình 4.5** | Màn hình Chiến thắng Tổng kết Thời gian, Điểm số và 5 Sao Max Cấp | Ảnh chụp thực tế | Chụp trong game (`hinh_4_5_man_hinh_chien_thang.png`) |

---

## PHẦN 2. MÃ NGUỒN 6 SƠ ĐỒ MERMAID CHUẨN HÓA CHO BẢN IN WORD

### 1. Sơ đồ 1 — Hình 2.1: Kiến trúc Phân tầng Hệ thống (Mục 2.1)
- **Vị trí trong báo cáo:** Chương 2, Mục 2.1 (Trang 18 - 20).
- **Tối ưu khổ Word:** Xếp theo chiều dọc (`flowchart TD`), nhóm các thành phần Player, Enemy, Environment theo 2 cột cân đối thay vì trải dài 3 cột ngang, giữ cho chiều rộng sơ đồ không vượt quá 850px (vừa khít 16cm lề trang Word A4 dọc).

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '20px'}}}%%
flowchart TD
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:16px,font-weight:bold;
    classDef bus fill:#f9f9f9,stroke:#000000,stroke-width:2.5px,color:#000000,font-size:17px,font-weight:bold;

    subgraph AUTOLOAD["TẦNG QUẢN LÝ TOÀN CỤC (AUTOLOAD / SINGLETONS)"]
        direction TB
        GE["GlobalEvents.gd<br/>(Signal Bus Trung Tâm)"]:::bus
        AM["AudioManager.gd<br/>(Âm thanh & SFX)"]
        SM["ScoreManager.gd<br/>(Điểm & Xếp sao Chiến dịch)"]
        GE -. "Phát âm thanh" .-> AM
        GE -. "Lưu điểm số" .-> SM
    end

    subgraph GAMEPLAY["TẦNG THỰC THỂ CHIẾN TRƯỜNG (GAMEPLAY SCENES)"]
        direction TB
        subgraph COMBAT_UNITS["LỰC LƯỢNG TÁC CHIẾN"]
            direction LR
            P_TANK["PlayerTank<br/>- Chassis (Thân xe)<br/>- Turret (Tháp pháo)<br/>- WeaponController<br/>- HealthComponent"]
            E_TANK["EnemyTank Scenes<br/>- Assault Artillery<br/>- Laser / AP Sniper<br/>- Rocket Tank<br/>- Mammoth Boss 350 HP"]
        end
        subgraph WORLD_ENV["MÔI TRƯỜNG & VẬT CẢN"]
            direction LR
            V_WALL["Wall (Tường cản đạn)<br/>Bush (Bụi ngụy trang)"]
            V_PROPS["ExplosiveBarrel (Thùng nổ)<br/>HealthPickup (Hồi máu)"]
        end
        COMBAT_UNITS --- WORLD_ENV
    end

    subgraph HUD["TẦNG GIAO DIỆN TÁC CHIẾN (DELTA FORCE HUD)"]
        direction LR
        H1["DeltaForceHUD<br/>(Máu, Cự ly, Tốc độ)"]
        H2["MinimapRadarDraw<br/>(Radar Sonar 360°)"]
        H3["ChassisCompassDraw<br/>(La bàn thân xe)"]
        H4["Tactical Loadout Hub<br/>(Cấu hình vũ khí Menu)"]
    end

    GAMEPLAY ==>|"Phát tín hiệu sự kiện (Emit Signals)"| GE
    GE ==>|"Cập nhật trạng thái hiển thị (Connect)"| HUD
```

---

### 2. Sơ đồ 2 — Hình 2.2: Tiến trình Quỹ đạo Đạn Parabol 2.5D (Mục 2.3.1)
- **Vị trí trong báo cáo:** Chương 2, Mục 2.3.1 (Trang 23 - 25).
- **Tối ưu khổ Word:** Chuyển từ dàn ngang 5 khối (`flowchart LR` gây tràn lề) sang dạng tiến trình dọc từng bước (`flowchart TD`). Chiều rộng cực kỳ nhỏ gọn (~480px), đọc cực rõ nét ở trang in Word A4.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '20px'}}}%%
flowchart TD
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:17px,font-weight:bold;
    classDef stage fill:#fdfdfd,stroke:#000000,stroke-width:2.5px,color:#000000,font-size:18px,font-weight:bold;

    S1["<b>GIAI ĐOẠN 1: KHAI HỎA (t = 0.0)</b><br/>• Tọa độ xuất phát: P_start tại nòng pháo<br/>• Độ cao ảo z(0) = 0 | Kích thước bóng đổ: 100%"]:::stage
    -->
    S2["<b>GIAI ĐOẠN 2: BỐC CAO CẦU VỒNG (0.0 &lt; t &lt; 0.5)</b><br/>• Đạn bay vút lên không trung, vượt qua tường bê tông<br/>• z(t) tăng dần theo Parabol | Bóng đổ co nhỏ dần"]:::stage
    -->
    S3["<b>GIAI ĐOẠN 3: ĐỈNH QUỸ ĐẠO (t = 0.5)</b><br/>• Độ cao cực đại: h_max = 140 px | Vận tốc đứng v_z = 0<br/>• Bóng co nhỏ cực tiểu (55%) tạo chiều sâu 2.5D rõ rệt"]:::stage
    -->
    S4["<b>GIAI ĐOẠN 4: HẠ ĐỘ CAO TIẾP ĐẤT (0.5 &lt; t &lt; 1.0)</b><br/>• Đạn lao cắm xuống mục tiêu | Bóng mặt đất nở to dần<br/>• Vòng tròn cảnh báo GroundImpactMarker hiển thị bán kính AoE 120 px"]:::stage
    -->
    S5["<b>GIAI ĐOẠN 5: CHẠM ĐẤT NỔ TUNG (t = 1.0)</b><br/>• Chạm đích: P_target | Độ cao ảo kết thúc z(1) = 0<br/>• Kích nổ sát thương AoE 120 px (60 HP) & Rung màn hình CameraShake"]:::stage
```

---

### 3. Sơ đồ 3 — Hình 2.3: Giải thuật Khóa Phạm vi Ngắm Vành khăn (Mục 2.3.2)
- **Vị trí trong báo cáo:** Chương 2, Mục 2.3.2 (Trang 26 - 27).
- **Tối ưu khổ Word:** Giữ cấu trúc 3 nhánh rẽ nhưng ngắt dòng súc tích, chữ đen nền trắng viền đen 2px, nhãn điều kiện rõ ràng.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '20px'}}}%%
flowchart TD
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:16px,font-weight:bold;
    classDef decision fill:#ffffff,stroke:#000000,stroke-width:2.5px,color:#000000,font-size:17px,font-weight:bold;
    classDef highlight fill:#f9f9f9,stroke:#000000,stroke-width:2px,color:#000000,font-size:16px,font-weight:bold;

    MouseInput["<b>DỮ LIỆU ĐẦU VÀO CON TRỎ CHUỘT:</b><br/>Vector khoảng cách: D = P_mouse - P_tank<br/>Cự ly ngắm thực tế: d = |D|"]
    --> CheckRange{"Kiểm tra Cự Ly d so với<br/>[R_min = 280px, R_max = 720px]"}:::decision

    CheckRange -- "Trường hợp 1:<br/>d &lt; 280 px (Quá gần xe)" --> ClampMin["<b>KHÓA TẦM GẦN (Clamp Min)</b><br/>Gán khoảng cách = 280 px<br/><i>Tránh nổ tự gây sát thương thân xe</i>"]:::highlight

    CheckRange -- "Trường hợp 2:<br/>280 px &le; d &le; 720 px" --> InRange["<b>VÙNG VÀNH KHĂN HỢP LỆ</b><br/>Giữ nguyên cự ly d thực tế<br/><i>Tâm ngắm bám sát con trỏ chuột</i>"]:::highlight

    CheckRange -- "Trường hợp 3:<br/>d &gt; 720 px (Quá tầm pháo)" --> ClampMax["<b>KHÓA TẦM XA (Clamp Max)</b><br/>Gán khoảng cách = 720 px<br/><i>Giới hạn tầm bắn tối đa của pháo</i>"]:::highlight

    ClampMin --> CalcTarget["<b>TÍNH TOÁN TỌA ĐỘ TIẾP ĐẤT MỤC TIÊU:</b><br/>P_target = P_tank + clamp(d, 280, 720) * (D / d)"]
    InRange --> CalcTarget
    ClampMax --> CalcTarget

    CalcTarget --> OutputHUD["Hiển thị vòng tròn ngắm Parabol trên mặt đất &<br/>Cập nhật chỉ số cự ly DIST (px) lên thanh HUD"]
```

---

### 4. Sơ đồ 4 — Hình 2.4: Máy Trạng thái Hữu hạn AI Xe Tăng Địch (Mục 2.3.4)
- **Vị trí trong báo cáo:** Chương 2, Mục 2.3.4 (Trang 29 - 31).
- **Tối ưu khổ Word:** Chuẩn hóa sang dạng lưu đồ trạng thái tuần tự rõ ràng (Flowchart State Machine), triệt tiêu các lỗi font của `stateDiagram-v2`, hiển thị trực quan 5 trạng thái với cỡ chữ 16px - 18px in đậm nền trắng.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '20px'}}}%%
flowchart TD
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:16px,font-weight:bold;
    classDef stateNode fill:#ffffff,stroke:#000000,stroke-width:2.5px,color:#000000,font-size:17px,font-weight:bold;
    classDef deadNode fill:#f2f2f2,stroke:#000000,stroke-width:2px,color:#000000,font-size:16px,font-weight:bold;

    START((Khởi tạo AI)) --> S_PATROL["<b>1. TRẠNG THÁI TUẦN TRA (PATROL)</b><br/>- Di chuyển giữa các Waypoint (v = 140 px/s)<br/>- Tháp pháo quay quét cảnh giới &plusmn;35&deg;<br/>- Quét cảm biến tầm nhìn LoS và 3 tia Raycast"]:::stateNode

    S_PATROL -->|"Phát hiện người chơi (LoS &le; 650px)<br/>hoặc BỊ TẤN CÔNG (Take Damage)"| S_CHASE["<b>2. TRẠNG THÁI TRUY BẮT (CHASE)</b><br/>- Tăng tốc cực đại bám đuôi (v = 210 px/s)<br/>- Kích hoạt lực lái 3 tia né góc tường<br/>- Phát sóng âm báo động đồng đội lân cận (450px)"]:::stateNode

    S_CHASE -->|"Người chơi vào bụi rậm tàng hình<br/>hoặc cắt tầm nhìn quá 4.0s"| S_PATROL

    S_CHASE -->|"Tiến vào cự ly tác chiến hiệu quả<br/>(300px - 500px)"| S_AIM["<b>3. TRẠNG THÁI NGẮM BẮN (AIMING)</b><br/>- Tháp pháo xoay bám tọa độ người chơi<br/>- Khóa mục tiêu / Chiếu tia Laser cảnh báo (1.3s)"]:::stateNode

    S_AIM -->|"Người chơi cơ động thoát khỏi góc ngắm"| S_CHASE

    S_AIM -->|"Nòng pháo sẵn sàng & Khóa mục tiêu"| S_ATTACK["<b>4. TRẠNG THÁI KHAI HỎA (ATTACK)</b><br/>- Bắn vũ khí đặc chủng (Pháo/AP/Rocket/Shotgun)<br/>- Giật lùi xe tạo cự ly an toàn (Kiting)"]:::stateNode

    S_ATTACK -->|"Vũ khí bước vào chu kỳ nạp đạn (Cooldown)"| S_AIM

    S_CHASE -->|"Máu nguy cấp: HP &le; 25%"| S_RETREAT["<b>5. TRẠNG THÁI RÚT LUI (RETREAT)</b><br/>- Tìm vật cản tường bê tông che chắn<br/>- Định vị và di chuyển khẩn cấp tới hộp máu"]:::stateNode
    S_ATTACK -->|"Máu nguy cấp: HP &le; 25%"| S_RETREAT

    S_RETREAT -->|"Hồi máu thành công (Nhặt hộp máu)"| S_CHASE
    S_ATTACK -->|"HP = 0"| S_DEAD["<b>TIÊU DIỆT: PHÁT NỔ & CỘNG ĐIỂM</b>"]:::deadNode
    S_RETREAT -->|"HP = 0"| S_DEAD
```

---

### 5. Sơ đồ 5 — Hình 3.3: Chu trình Súng máy Tăng tốc & Quá nhiệt (Mục 3.2.3)
- **Vị trí trong báo cáo:** Chương 3, Mục 3.2.3 (Trang 38 - 40).
- **Tối ưu khổ Word:** Chuẩn hóa mã nguồn theo đúng mẫu tham chiếu của người dùng: nền trắng, viền đen 2px, cỡ chữ lớn 18px - 22px in đậm, chuyển ký tự mũi tên thành `->` chống lỗi hiển thị.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '22px'}}}%%
flowchart LR
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:18px,font-weight:bold;

    subgraph S_IDLE["1. TRẠNG THÁI NGHỈ (IDLE)"]
        direction TB
        I1["Nòng súng nguội: Heat = 0%"]
        I2["Tốc độ bắn ban đầu: 0.16s / viên"]
    end

    subgraph S_FIRE["2. GIỮ CHUỘT PHẢI: TĂNG TỐC (SPOOL-UP)"]
        direction TB
        F1["Nòng xoay tăng tốc: spool_progress -> 1.0"]
        F2["Tốc độ xả đạn cực đại: 0.045s / viên (x3.5)"]
        F3["Nhiệt lượng tích tụ: +6.5% / mỗi viên"]
    end

    subgraph S_OVERHEAT["3. ĐẠT 100% NHIỆT: QUÁ NHIỆT (BURN OUT)"]
        direction TB
        O1["Khóa nòng súng hoàn toàn trong 2.8s"]
        O2["Cảnh báo [OVERHEATED] nhấp nháy đỏ trên HUD"]
        O3["Không thể khai hỏa cho đến khi hạ nhiệt"]
    end

    subgraph S_COOL["4. HẠ NHIỆT TỰ NHIÊN (COOLDOWN)"]
        direction TB
        C1["Nhả chuột: Hạ nhiệt độ -35% / giây"]
        C2["Về trạng thái an toàn: Heat = 0%"]
    end

    S_IDLE -- "Nhấn giữ Chuột Phải" --> S_FIRE
    S_FIRE -- "Nhả chuột khi Heat &lt; 100%" --> S_COOL
    S_FIRE -- "Giữ bắn liên tục tới Heat = 100%" --> S_OVERHEAT
    S_OVERHEAT -- "Hết thời gian cưỡng chế 2.8s" --> S_IDLE
    S_COOL --> S_IDLE
```

---

### 6. Sơ đồ 6 — Hình 3.4: Giải thuật Màn khói Tác chiến Điện tử (Mục 3.4.3)
- **Vị trí trong báo cáo:** Chương 3, Mục 3.4.3 (Trang 48 - 49).
- **Tối ưu khổ Word:** Bố cục dạng phân nhánh điều kiện dọc, nền trắng viền đen 2px, kích thước nhỏ gọn (~540px), chữ to 18px dễ đọc.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'clusterBkg': '#ffffff', 'clusterBorder': '#000000', 'lineColor': '#000000', 'edgeLabelBackground':'#ffffff', 'primaryTextColor': '#000000', 'fontSize': '22px'}}}%%
flowchart TD
    classDef default fill:#ffffff,stroke:#000000,stroke-width:2px,color:#000000,font-size:18px,font-weight:bold;
    classDef decision fill:#ffffff,stroke:#000000,stroke-width:2.5px,color:#000000,font-size:18px,font-weight:bold;
    classDef effect fill:#f9f9f9,stroke:#000000,stroke-width:2px,color:#000000,font-size:18px,font-weight:bold;

    RocketFired["Xe địch phóng Tên lửa Tự hành (Homing Rocket)"]
    --> Tracking["Đầu dò tên lửa khóa tọa độ P_player<br/>Hiệu chỉnh vector bay bám đuôi liên tục"]
    --> CheckSmoke{"Xe người chơi kích hoạt Màn khói [E]<br/>hoặc tiến vào vùng khói mù?"}:::decision

    CheckSmoke -- "Không" --> DirectHit["Tên lửa bay thẳng tới xe người chơi<br/>Kích nổ gây 55 HP sát thương diện rộng AoE"]

    CheckSmoke -- "Có (Bị màn khói vô hiệu hóa)" --> LostLock["<b>MẤT TÍN HIỆU ĐẦU DÒ (target_node = null)</b><br/>Kích hoạt cờ mất kiểm soát: is_confused = true"]:::effect
    --> SpiralFlight["<b>BAY XOẮN ỐC LOẠN XẠ</b><br/>Đảo hướng: sin(t * 18.0) * 1.25 rad + randf()<br/>Tên lửa mất hoàn toàn phương hướng"]:::effect
    --> Crash["Đâm vào tường bê tông hoặc mặt đất nổ tan<br/><i>Bảo vệ an toàn tuyệt đối cho người chơi</i>"]:::effect
```

---

## PHẦN 3. HƯỚNG DẪN ĐƯA VÀO FILE MICROSOFT WORD IN ẤN

1. **Cách 1 — Chèn trực tiếp qua tiện ích Markdown trong VSCode / Typora:**
   - Khi mở tệp báo cáo bằng phần mềm soạn thảo hỗ trợ Mermaid (Typora, Obsidian, VSCode Preview Enhanced), toàn bộ 6 sơ đồ trên sẽ tự động kết xuất thành hình vẽ vector nền trắng, viền đen sắc nét, cỡ chữ lớn 18px - 22px.
   - Nhấn `Ctrl + A` $\rightarrow$ `Ctrl + C` và dán thẳng vào Microsoft Word, sơ đồ sẽ giữ nguyên tỷ lệ trang in A4 chuẩn.

2. **Cách 2 — Sao chép ảnh SVG/PNG từ trình duyệt:**
   - Mở trình soạn thảo Markdown Preview, nhấp chuột phải vào từng sơ đồ chọn **Copy Image** rồi `Ctrl + V` vào Word.
   - Do đã được giới hạn chiều rộng và đặt phông chữ `18px - 22px`, hình ảnh khi chèn vào trang giấy A4 Word sẽ vừa vặn tuyệt đối từ lề trái (3cm) đến lề phải (2cm), không bị co cụm chữ và không bị tràn trang.

