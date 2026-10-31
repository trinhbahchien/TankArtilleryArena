# CẨM NANG HƯỚNG DẪN CHỈNH SỬA, MỞ RỘNG VÀ THÊM TÍNH NĂNG MỚI
## DỰ ÁN: TANK ARTILLERY ARENA (MTA 2026)

> **Mục đích tài liệu:** Cung cấp hướng dẫn kỹ thuật chi tiết từng bước (Step-by-Step Guide) giúp sinh viên, giảng viên và các nhà phát triển dễ dàng bảo trì, tùy biến thông số hoặc mở rộng thêm các tính năng mới (thêm vũ khí, thêm xe tăng địch, tạo màn chơi mới, thêm cấu hình nâng cấp) vào mã nguồn dự án và cập nhật lại báo cáo đồ án một cách đồng bộ, chuẩn mực.

---

## MỤC LỤC
1. [Nguyên Tắc Kiến Trúc & Cấu Trúc Thư Mục](#1-nguyên-tắc-kiến-trúc--cấu-trúc-thư-mục)
2. [Hướng Dẫn 1: Thêm Vũ Khí Mới Vào Hệ Thống](#2-hướng-dẫn-1-thêm-vũ-khí-mới-vào-hệ-thống)
3. [Hướng Dẫn 2: Thêm Loại Xe Tăng Địch Mới](#3-hướng-dẫn-2-thêm-loại-xe-tăng-địch-mới)
4. [Hướng Dẫn 3: Tạo Thêm Màn Chơi Mới (Level 11 - 20)](#4-hướng-dẫn-3-tạo-thêm-màn-chơi-mới-level-11---20)
5. [Hướng Dẫn 4: Thêm Cấu Hình Nâng Cấp Tác Chiến (Combat Preset) Vào Menu](#5-hướng-dẫn-4-thêm-cấu-hình-nâng-cấp-tác-chiến-combat-preset-vào-menu)
6. [Hướng Dẫn 5: Quy Trình Cập Nhật Đồng Bộ Vào Báo Cáo Đồ Án](#6-hướng-dẫn-5-quy-trình-cập-nhật-đồng-bộ-vào-báo-cáo-đồ-án)
7. [Quy Trình Đóng Gói Xuất Bản File Thực Thi (.pck)](#7-quy-trình-đóng-gói-xuất-bản-file-thực-thi-pck)

---

## 1. NGUYÊN TẮC KIẾN TRÚC & CẤU TRÚC THƯ MỤC

### 1.1. Nguyên tắc cốt lõi
Dự án được xây dựng theo mô hình **Scene-Node Decoupled Architecture**:
- Mọi thành phần đều là một Scene độc lập có thể chạy thử nghiệm riêng biệt (`F6` trong Godot Editor).
- Các đối tượng không truy xuất chéo trực tiếp mà giao tiếp thông qua **Tín hiệu Sự kiện toàn cục** (`GlobalEvents.gd`).
- Mọi văn bản hiển thị phải dùng tiếng Việt có dấu chuẩn, không sử dụng icon/emoji cảm xúc.

### 1.2. Sơ đồ cây thư mục dự án
```
d:/Do an 2026/MTA/Godot/TankArtilleryArena/
├── assets/                  # Hình ảnh Sprite Sheet, Âm thanh SFX, Phông chữ TTF
│   ├── fonts/               # Xolonium-Regular.ttf (kèm fallback SystemFont)
│   ├── sfx/                 # Tiếng bắn pháo, súng máy, nổ, rít nhiệt
│   └── sprites/             # Atlas hình ảnh xe tăng, đạn đạo, chướng ngại vật
├── docs/                    # Tài liệu kỹ thuật và Báo cáo Đồ án tốt nghiệp
│   ├── BAO_CAO_DO_AN_TANK_ARTILLERY_ARENA.md    # Báo cáo chuẩn MTA
│   └── HUONG_DAN_CHINH_SUA_VA_THEM_TINH_NANG_DO_AN.md # File cẩm nang này
├── scenes/                  # Toàn bộ các Scene (.tscn) phân theo thư mục chức năng
│   ├── entities/            # PlayerTank, EnemyTank, SniperEnemy, MammothTank...
│   ├── environment/         # Wall, Bush (Bụi rậm), ExplosiveBarrel, DestructibleCrate
│   ├── levels/              # Level1.tscn -> Level10.tscn, Sandbox.tscn
│   ├── ui/                  # DeltaForceHUD, MainMenu, LevelSelectMenu, VictoryScreen...
│   └── weapons/             # ArtilleryShell, MachineGunBullet, TwinCannonBullet...
└── scripts/                 # Mã nguồn GDScript 2.0 (.gd)
    ├── autoload/            # GlobalEvents.gd, ScoreManager.gd, AudioManager.gd
    ├── entities/            # TankChassis.gd, TurretAim.gd, PracticeDummy.gd
    ├── ui/                  # DeltaForceHUD.gd, MainMenu.gd, LevelSelectMenu.gd...
    └── weapons/             # WeaponController.gd, ArtilleryShell.gd...
```

---

## 2. HƯỚNG DẪN 1: THÊM VŨ KHÍ MỚI VÀO HỆ THỐNG

Hệ thống vũ khí hiện tại chia làm 2 nhánh rõ rệt được cấu hình từ Menu:
1. **Hỏa lực Chính (Chuột trái):** `WeaponMode` (Pháo cối AoE, Song pháo AP, Rocket chùm).
2. **Hỏa lực Phụ (Chuột phải):** `SecondaryWeaponMode` (0: Súng xuyên giáp AP mặc định, 1: Súng máy liên thanh quá nhiệt, 2: Súng shotgun tán xạ).

*Ví dụ: Bạn muốn thêm một loại **Súng Phụ Chuột Phải Mới: Súng Phóng Lựu Độc Tố (Gas Grenade - Mode 3)**.*

### Bước 1: Tạo Scene và Script cho viên đạn/lựu đạn mới
1. Tạo script mới: `scripts/weapons/GasGrenade.gd`.
   ```gdscript
   extends Area2D

   @export var speed: float = 700.0
   @export var poison_damage: int = 15
   var direction: Vector2 = Vector2.RIGHT

   func _ready() -> void:
       body_entered.connect(_on_body_entered)
       get_tree().create_timer(2.5).timeout.connect(queue_free)

   func initialize(pos: Vector2, rot: float, _from_enemy: bool = false) -> void:
       global_position = pos
       rotation = rot
       direction = Vector2.RIGHT.rotated(rot)

   func _physics_process(delta: float) -> void:
       global_position += direction * speed * delta

   func _on_body_entered(body: Node) -> void:
       if body.is_in_group("player"):
           return
       if body.has_node("HealthComponent"):
           body.get_node("HealthComponent").take_damage(poison_damage)
       queue_free()
   ```
2. Tạo Scene `scenes/weapons/GasGrenade.tscn` gắn script trên, thêm Sprite và CollisionShape2D.

### Bước 2: Đăng ký súng phụ trong `WeaponController.gd`
Mở file `scripts/weapons/WeaponController.gd`:
1. Mở rộng enum `SecondaryWeaponMode`:
   ```gdscript
   enum SecondaryWeaponMode {
       HEAVY_AP = 0,
       MACHINE_GUN = 1,
       SHOTGUN = 2,
       GAS_GRENADE = 3 # << THÊM MỚI TẠI ĐÂY
   }
   ```
2. Khai báo nạp PackedScene và bộ đếm hồi chiêu:
   ```gdscript
   @export var gas_grenade_scene: PackedScene = preload("res://scenes/weapons/GasGrenade.tscn")
   @export var gas_cooldown: float = 1.2
   var gas_timer: float = 0.0
   ```
3. Cập nhật nhánh gọi bắn trong `fire_secondary()`:
   ```gdscript
   match secondary_mode:
       SecondaryWeaponMode.HEAVY_AP:
           _fire_heavy_ap()
       SecondaryWeaponMode.MACHINE_GUN:
           fire_machinegun()
       SecondaryWeaponMode.SHOTGUN:
           _fire_shotgun()
       SecondaryWeaponMode.GAS_GRENADE:
           _fire_gas_grenade()
   ```
4. Viết hàm `_fire_gas_grenade()`:
   ```gdscript
   func _fire_gas_grenade() -> void:
       if gas_timer > 0.0:
           return
       gas_timer = gas_cooldown
       var grenade = gas_grenade_scene.instantiate()
       var rot = turret_aim.get_turret_rotation() if turret_aim else global_rotation
       grenade.initialize(turret_aim.get_muzzle_position(), rot, false)
       get_tree().current_scene.add_child(grenade)
       GlobalEvents.camera_shake_requested.emit(2.5, 0.15)
   ```

### Bước 3: Đăng ký vào Menu Tùy Chỉnh (`MainMenu.gd`) và Lưu Trữ (`GlobalEvents.gd`)
1. Trong `GlobalEvents.gd`: Thêm biến lưu trữ cấu hình `secondary_weapon_mode: int = 0` và lưu/nạp vào `user://weapon_loadout.cfg`.
2. Trong `MainMenu.tscn` và `MainMenu.gd`: Bổ sung OptionButton chọn `SÚNG PHÓNG LỰU ĐỘC` trong cửa sổ Tùy Chỉnh Hỏa Lực để người chơi lựa chọn trước khi xuất kích.
3. Trong `DeltaForceHUD.gd`: Cập nhật hiển thị tên súng `[R-CLICK] LỰU ĐẠN ĐỘC` và đồng hồ hồi đạn trên HUD.

---

## 3. HƯỚNG DẪN 2: THÊM LOẠI XE TĂNG ĐỊCH MỚI

*Giả sử bạn muốn thêm: **Xe Tăng Phun Lửa (Flame Tank)**.*

### Bước 1: Nhân bản và Cấu hình Scene mới
1. Nhân bản file `scenes/entities/EnemyTank.tscn` thành `scenes/entities/FlameTank.tscn`.
2. Thay đổi màu Sprite nòng pháo và thân xe (ví dụ màu Cam Cháy `Color(1.0, 0.45, 0.15)`).
3. Đổi tên Node gốc thành `FlameTank`.

### Bước 2: Tùy biến chỉ số và hành vi AI
Mở script gắn trên xe tăng hoặc tạo `scripts/entities/FlameTank.gd`:
```gdscript
extends CharacterBody2D

@export var max_health: int = 110
@export var move_speed: float = 145.0
@export var flame_range: float = 320.0
@export var flame_damage_per_sec: float = 25.0

# Điều chỉnh bán kính áp sát trong FSM AI:
# Khi khoảng cách tới người chơi < flame_range, kích hoạt xả luồng lửa liên tục
```

### Bước 3: Đưa xe tăng mới vào Màn chơi
Mở màn chơi bất kỳ (ví dụ `Level7.tscn`), kéo `FlameTank.tscn` từ FileSystem thả vào Node `Enemies` trên Scene Tree.

---

## 4. HƯỚNG DẪN 3: TẠO THÊM MÀN CHƠI MỚI (LEVEL 11 - 20)

### Bước 1: Tạo Scene Màn chơi từ mẫu có sẵn
1. Nhân bản file `scenes/levels/Level10.tscn` và đổi tên thành `Level11.tscn`.
2. Mở `Level11.tscn` trong Godot:
   - Xóa bỏ hoặc thay thế các xe địch cũ trong Node `Enemies`.
   - Bố trí lại các khối tường `Wall.tscn`, bụi rậm `Bush.tscn` và thùng nổ `ExplosiveBarrel.tscn`.
   - Đảm bảo có đúng 1 Node `PlayerTank` tại vị trí xuất phát an toàn.
   - Đảm bảo trong Scene có chứa `DeltaForceHUD.tscn` (Giao diện chuẩn).

### Bước 2: Đăng ký màn chơi mới vào `ScoreManager.gd`
Mở file `scripts/autoload/ScoreManager.gd`:
```gdscript
# Cập nhật tổng số màn chơi lên 11 (hoặc 20)
const TOTAL_LEVELS: int = 11

# Thêm cấu hình thời gian chuẩn để đạt 5 Sao cho Màn 11:
const LEVEL_PAR_TIMES: Dictionary = {
    1: 45.0, 2: 55.0, 3: 65.0, 4: 75.0, 5: 85.0,
    6: 95.0, 7: 105.0, 8: 120.0, 9: 140.0, 10: 180.0,
    11: 150.0 # << THÊM THỜI GIAN CHUẨN MÀN 11
}
```

### Bước 3: Cập nhật Menu Chọn màn chơi (`LevelSelectMenu.gd`)
Mở `scripts/ui/LevelSelectMenu.gd`, hàm sinh nút màn chơi sẽ tự động duyệt theo `TOTAL_LEVELS` và hiển thị thêm nút `MÀN 11` trên lưới lựa chọn.

---

## 5. HƯỚNG DẪN 4: THÊM CẤU HÌNH NÂNG CẤP TÁC CHIẾN (COMBAT PRESET) VÀO MENU

*Giả sử bạn muốn thêm Cấu hình thứ 5: **Cấu Hình Giáp Trọng Pháo (Heavy Armor Bulwark)**.*

### Bước 1: Mở rộng Preset trong `GlobalEvents.gd`
Mở `scripts/autoload/GlobalEvents.gd`:
- Không cần sửa đổi nhiều vì `weapon_preset` là kiểu số nguyên `int`.
- Giá trị preset mới sẽ là `4`.

### Bước 2: Thêm hiệu ứng nâng cấp trong `WeaponController.gd`
Mở `scripts/weapons/WeaponController.gd`, tại hàm `apply_weapon_preset(preset: int)`:
```gdscript
match preset:
    1: # Pháo binh
        artillery_cooldown = 1.35
    2: # Súng máy
        mg_heat_capacity = 130.0
        mg_cooling_rate = 55.0
    3: # Tên lửa
        rocket_lock_duration = 0.75
        rocket_max_range = 800.0
    4: # GIÁP TRỌNG PHÁO (THÊM MỚI)
        # Giảm tốc độ nhưng tăng giáp hoặc giảm hồi chiêu cả 3 loại vũ khí
        artillery_cooldown = 1.4
        mg_cooling_rate = 45.0
    _:
        # Cân bằng tiêu chuẩn
        pass
```

### Bước 3: Thêm lựa chọn và Mô tả vào `MainMenu.gd`
Mở `scripts/ui/MainMenu.gd`:
1. Trong hàm `_setup_customization_ui()`:
   ```gdscript
   preset_option.add_item("Giáp Trọng Pháo (Tăng sức chống chịu và ổn định nòng súng)", 4)
   ```
2. Trong hàm `_update_customization_details()`:
   ```gdscript
   4:
       text = "[color=#ff88ee][b]CẤU HÌNH GIÁP TRỌNG PHÁO:[/b][/color]\n" + \
              "• Tăng độ ổn định đường đạn và giảm thời gian rung lắc.\n" + \
              "• Tốc độ tản nhiệt đạt 45/s và giảm thời gian nạp pháo cối còn 1.4s."
   ```

---

## 6. HƯỚNG DẪN 5: QUY TRÌNH CẬP NHẬT ĐỒNG BỘ VÀO BÁO CÁO ĐỒ ÁN

Khi bạn thêm bất kỳ tính năng mới nào vào dự án, hãy mở file báo cáo chính:  
`d:/Do an 2026/MTA/Godot/TankArtilleryArena/docs/BAO_CAO_DO_AN_TANK_ARTILLERY_ARENA.md`  
và cập nhật lại các mục tương ứng theo bảng hướng dẫn sau:

| Tính năng vừa thêm | Vị trí mục cần cập nhật trong file Báo cáo | Nội dung cần bổ sung / chỉnh sửa |
| :--- | :--- | :--- |
| **Thêm Vũ khí mới** | **Mục 2.1 & Mục 3.2** (Chương 2 & 3) | Thêm mô tả cơ chế, công thức toán học và đoạn mã nguồn GDScript tiêu biểu. |
| **Thêm Xe tăng địch mới** | **Mục 3.4 & Bảng 3.2** (Chương 3) | Cập nhật thêm dòng thông số (Máu, Vận tốc, Vũ khí, Chiến thuật) vào Bảng 3.2. |
| **Thêm Màn chơi mới** | **Mục 4.1 & Bảng 4.1** (Chương 4) | Thêm hàng mới vào Bảng 4.1 mô tả Mục tiêu tác chiến và Kẻ địch xuất hiện. |
| **Thêm Preset tùy chỉnh** | **Mục 3.6** (Chương 3) | Bổ sung tên Preset và các chỉ số được buff vào danh sách nâng cấp. |
| **Cập nhật Hình ảnh mới** | **Danh mục hình ảnh & Mục 4.2** | Chụp ảnh màn hình mới, lưu vào `assets/screenshots/`, đánh số lại Hình minh họa tương ứng. |

---

## 7. QUY TRÌNH ĐÓNG GÓI XUẤT BẢN FILE THỰC THI (.PCK)

Để xuất bản bản dựng mới sau khi chỉnh sửa hoặc thêm tính năng:
1. Mở PowerShell trong thư mục gốc dự án:
   ```powershell
   cd "d:\Do an 2026\MTA\Godot\TankArtilleryArena"
   ```
2. Chạy lệnh xuất bản gói tài nguyên `.pck`:
   ```powershell
   & "d:\Do an 2026\MTA\Godot\Engine\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-pack "Windows Desktop" "d:\Do an 2026\MTA\Godot\TankArtilleryArena\export\TankArtilleryArena.pck"
   ```
3. Sau khi xuất bản xong, người chơi chỉ cần mở file chạy `TankArtilleryArena.exe` là game sẽ tự động nạp gói nội dung mới nhất.

---
*Tài liệu được biên soạn bởi Nhóm Nghiên Cứu & Phát Triển MTA - Khóa Luận Tốt Nghiệp 2026.*
