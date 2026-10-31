class_name MapData
extends Resource

## Định nghĩa dữ liệu Bản đồ - Giúp thêm bản đồ mới cực nhanh bằng file .tres mà không cần sửa code

@export var map_id: String = "arena_01"
@export var display_name: String = "Đấu trường Căn bản"
@export_multiline var description: String = "Khu vực tập luyện tác chiến pháo cối với tường bê tông chắn tầm nhìn."
@export_file("*.tscn") var scene_path: String = "res://scenes/maps/Arena01_Test.tscn"
@export var enemy_count: int = 3
@export var has_fog_of_war: bool = false
@export var ambient_color: Color = Color(0.18, 0.20, 0.22, 1.0)
