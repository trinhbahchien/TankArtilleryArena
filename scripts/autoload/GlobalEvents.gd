extends Node

## Event Bus toàn cục (Autoload Singleton) - Giúp các hệ thống giao tiếp mà không bị ràng buộc phụ thuộc (Decoupled)

# Sự kiện Camera & Hiệu ứng
signal camera_shake_requested(intensity: float, duration: float)

# Sự kiện Chiến đấu & Xe tăng
signal tank_damaged(tank: Node, current_hp: int, max_hp: int)
signal tank_destroyed(tank: Node, killer: Node)
signal projectile_fired(projectile: Node)
signal artillery_apex_reached(position: Vector2)

# Sự kiện Màn chơi & Điểm số
signal score_added(amount: int)
signal map_load_requested(map_scene_path: String)
signal game_state_changed(new_state: String)
signal ui_hover_changed(is_over_ui: bool)
signal radar_scan_triggered(duration: float)

var is_radar_active: bool = false

# Tùy chỉnh hỏa lực & trang bị (Weapon Customization Loadout)
var default_weapon_mode: int = 0   # Vũ khí chính (Chuột trái): 0: Pháo cối, 1: Song pháo, 2: Rocket
var secondary_weapon_mode: int = 0 # Vũ khí phụ (Chuột phải): 0: Súng AP (Mặc định), 1: Súng máy, 2: Shotgun
var weapon_preset: int = 0         # 0: Cân bằng, 1: Pháo binh, 2: Đột kích, 3: Tên lửa
signal weapon_customization_updated()

const WEAPON_CONFIG_PATH := "user://weapon_loadout.cfg"

func _ready() -> void:
	# Đảm bảo font Xolonium hỗ trợ 100% đầy đủ các ký tự tiếng Việt có dấu phức (fallback SystemFont)
	var font := load("res://assets/fonts/Xolonium-Regular.ttf") as FontFile
	if font:
		var has_sys_fallback := false
		for fb in font.fallbacks:
			if fb is SystemFont:
				has_sys_fallback = true
				break
		if not has_sys_fallback:
			var sys_font := SystemFont.new()
			sys_font.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma", "sans-serif"])
			font.fallbacks.append(sys_font)

	load_weapon_customization()

	radar_scan_triggered.connect(func(duration: float):
		is_radar_active = true
		get_tree().create_timer(duration).timeout.connect(func():
			is_radar_active = false
		)
	)

func save_weapon_customization(pri_mode: int, sec_mode: int, preset: int) -> void:
	default_weapon_mode = pri_mode
	secondary_weapon_mode = sec_mode
	weapon_preset = preset
	var cfg := ConfigFile.new()
	cfg.set_value("loadout", "default_weapon_mode", default_weapon_mode)
	cfg.set_value("loadout", "secondary_weapon_mode", secondary_weapon_mode)
	cfg.set_value("loadout", "weapon_preset", weapon_preset)
	cfg.save(WEAPON_CONFIG_PATH)
	weapon_customization_updated.emit()

func load_weapon_customization() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(WEAPON_CONFIG_PATH) == OK:
		default_weapon_mode = int(cfg.get_value("loadout", "default_weapon_mode", 0))
		secondary_weapon_mode = int(cfg.get_value("loadout", "secondary_weapon_mode", 0))
		weapon_preset = int(cfg.get_value("loadout", "weapon_preset", 0))

