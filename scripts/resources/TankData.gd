class_name TankData
extends Resource

## Định nghĩa dữ liệu Xe tăng - Dễ dàng tạo thêm các loại xe tăng mới (Kẻ địch Scout, Heavy, Artillery Boss)

enum AIType { PLAYER_CONTROLLED, EASY_PATROL, TACTICAL_ARTILLERY, BOSS_RUSHER }

@export var tank_id: String = "artillery_enemy"
@export var tank_name: String = "Xe Tăng Pháo Binh Địch"
@export var max_health: int = 100
@export var move_speed: float = 160.0
@export var rotation_speed: float = 2.0
@export var ai_type: AIType = AIType.TACTICAL_ARTILLERY

@export var primary_weapon: WeaponData
@export var secondary_weapon: WeaponData

# Vùng cắt sprite trên Atlas
@export var chassis_region: Rect2 = Rect2(268, 186, 80, 76)
@export var turret_region: Rect2 = Rect2(371, 14, 60, 24)
