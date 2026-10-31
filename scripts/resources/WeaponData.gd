class_name WeaponData
extends Resource

## Định nghĩa dữ liệu Vũ khí - Cho phép thêm vũ khí mới (Laser, Tên lửa, Đạn chùm, Pháo nổ) bằng file .tres

enum WeaponType { ARTILLERY_PARABOLA, STRAIGHT_BULLET, HOMING_MISSILE, LASER_BEAM }

@export var weapon_id: String = "heavy_howitzer"
@export var display_name: String = "Pháo Cối Hạng Nặng"
@export var weapon_type: WeaponType = WeaponType.ARTILLERY_PARABOLA
@export var cooldown: float = 2.2
@export var base_damage: int = 50
@export var projectile_speed: float = 620.0
@export var aoe_radius: float = 120.0
@export var projectile_scene: PackedScene = preload("res://scenes/weapons/ArtilleryShell.tscn")
@export var muzzle_flash_color: Color = Color(1.0, 0.7, 0.2)
