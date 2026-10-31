class_name PlayerIndicator
extends Node2D

## Mũi tên chỉ định vị trí Người chơi (Player Indicator Arrow)
## Luôn hiển thị trên cùng (z_index = 30), giúp người chơi nhận biết xe của mình
## kể cả khi đang ẩn mình hoàn toàn trong màn khói dày đặc cố định.

@export var arrow_color: Color = Color(0.15, 0.95, 1.0, 0.95)
@export var in_smoke_color: Color = Color(0.25, 1.0, 0.5, 1.0)
@export var outline_color: Color = Color(0.02, 0.1, 0.22, 1.0)
@export var base_y_offset: float = -68.0
@export var bob_range: float = 4.0
@export var bob_speed: float = 5.0

var parent_tank: Node2D

func _ready() -> void:
	z_index = 30
	z_as_relative = false
	parent_tank = get_parent() as Node2D

func _process(_delta: float) -> void:
	if not is_instance_valid(parent_tank):
		return
		
	# Giữ mũi tên luôn chỉ thẳng đứng xuống xe bất kể thân xe xoay theo góc nào
	global_rotation = 0.0
	
	# Hiệu ứng nhấp nhô lơ lửng mượt mà
	var time_val := Time.get_ticks_msec() * 0.001
	var bob := sin(time_val * bob_speed) * bob_range
	position = Vector2(0.0, base_y_offset + bob)
	
	queue_redraw()

func _draw() -> void:
	var is_in_smoke := false
	if parent_tank and "is_in_smoke" in parent_tank:
		is_in_smoke = parent_tank.is_in_smoke
		
	var fill_col := in_smoke_color if is_in_smoke else arrow_color
	
	# Nếu đang trong khói: Vẽ vòng hào quang phát sáng xung quanh để dễ nhận diện
	if is_in_smoke:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.009)
		draw_circle(Vector2(0, 0), 16.0 * pulse, Color(0.2, 1.0, 0.5, 0.22 * pulse))
		draw_arc(Vector2(0, 0), 13.0, 0, TAU, 24, Color(0.3, 1.0, 0.6, 0.75 * pulse), 1.5, true)
	
	# Tọa độ hình mũi tên quân sự chỉ thẳng xuống dưới (V-chevron)
	var pts := PackedVector2Array([
		Vector2(0, 10),      # Mũi nhọn hướng xuống
		Vector2(-9, -2),     # Cánh trái
		Vector2(-4, -1),     # Thắt vào trong
		Vector2(-4, -10),    # Chuôi trái
		Vector2(4, -10),     # Chuôi phải
		Vector2(4, -1),      # Thắt vào trong
		Vector2(9, -2)       # Cánh phải
	])
	
	# 1. Vẽ viền nét đậm tương phản
	draw_polyline(pts, outline_color, 3.5, true)
	# 2. Tô màu neon nổi bật
	draw_colored_polygon(pts, fill_col)
	# 3. Điểm nhấn trung tâm
	draw_circle(Vector2(0, -5), 1.8, Color.WHITE)
