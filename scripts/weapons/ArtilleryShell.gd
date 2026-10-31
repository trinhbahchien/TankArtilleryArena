class_name ArtilleryShell
extends Node2D

## Đạn Pháo Parabola 2.5D:
## - Mũi đạn luôn xoay đúng 100% theo tiếp tuyến quỹ đạo bay (vọt lên rồi chúi xuống mục tiêu)
## - 2 Hoạt ảnh rõ rệt: Giai đoạn 1 (bốc cao lên nửa đường) & Giai đoạn 2 (lao dốc qua nửa đường)

@export var travel_speed: float = 620.0
@export var height_ratio: float = 0.38
@export var explosion_radius: float = 120.0
@export var base_damage: int = 50
@export var explosion_vfx_scene: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var start_pos: Vector2
var target_pos: Vector2
var flight_time: float = 1.0
var elapsed_time: float = 0.0
var max_height: float = 120.0
var has_exploded: bool = false
var apex_reached: bool = false

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var shell_sprite: Sprite2D = $ShellVisual
@onready var ascent_particles: CPUParticles2D = $ShellVisual/AscentParticles
@onready var descent_particles: CPUParticles2D = $ShellVisual/DescentParticles
@onready var apex_spark: CPUParticles2D = $ShellVisual/ApexSpark

func initialize(start: Vector2, target: Vector2) -> void:
	if "weapon_preset" in GlobalEvents and GlobalEvents.weapon_preset == 1:
		explosion_radius = 140.0
	start_pos = start
	target_pos = target
	global_position = start
	
	var distance := start.distance_to(target)
	flight_time = maxf(distance / travel_speed, 0.4)
	max_height = maxf(distance * height_ratio, 70.0)
	
	if shadow_sprite:
		shadow_sprite.global_position = start
	if shell_sprite:
		shell_sprite.global_position = start
		# Đạn hướng về mục tiêu ngay từ vạch xuất phát
		var initial_dir := target_pos - start_pos
		var initial_angle := atan2(initial_dir.y - 4.0 * max_height, initial_dir.x) + PI
		shell_sprite.rotation = initial_angle
	
	# Bật hạt giai đoạn 1 (Ascent)
	if ascent_particles:
		ascent_particles.emitting = true
	if descent_particles:
		descent_particles.emitting = false
		
	_create_ground_impact_marker()

var ground_marker: Node2D

func _create_ground_impact_marker() -> void:
	ground_marker = Node2D.new()
	ground_marker.top_level = true
	ground_marker.global_position = target_pos
	ground_marker.z_index = 2
	
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ground_marker.material = mat
	
	ground_marker.draw.connect(_on_ground_marker_draw)
	add_child(ground_marker)

func _on_ground_marker_draw() -> void:
	if not ground_marker or has_exploded:
		return
	var t := clampf(elapsed_time / flight_time, 0.0, 1.0)
	var time_left := maxf(flight_time - elapsed_time, 0.0)
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.015)
	
	# 1. Vùng bán kính sát thương thực tế AoE (120 px)
	ground_marker.draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.15, 0.1, 0.16 * pulse))
	ground_marker.draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 56, Color(1.0, 0.25, 0.18, 0.9), 2.2, true)
	
	# 2. Vòng thu hẹp dần theo thời gian tiếp đất (Contracting Ring)
	var contract_r := explosion_radius * lerpf(1.8, 1.0, t)
	ground_marker.draw_arc(Vector2.ZERO, contract_r, 0.0, TAU, 48, Color(1.0, 0.85, 0.3, 0.75), 1.8, true)
	
	# 3. Dấu chữ thập tâm nổ
	ground_marker.draw_line(Vector2(-12, 0), Vector2(12, 0), Color(1.0, 0.9, 0.3, 0.9), 2.0, true)
	ground_marker.draw_line(Vector2(0, -12), Vector2(0, 12), Color(1.0, 0.9, 0.3, 0.9), 2.0, true)
	
	# 4. Nhãn cảnh báo cự ly va chạm
	ground_marker.draw_string(
		ThemeDB.fallback_font,
		Vector2(-65, -explosion_radius - 8),
		"[ĐẠN TIẾP ĐẤT: %.1fs]" % time_left,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		11,
		Color(1.0, 0.4, 0.3, 0.95)
	)

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
		
	if ground_marker:
		ground_marker.queue_redraw()
		
	elapsed_time += delta
	var t := clampf(elapsed_time / flight_time, 0.0, 1.0)
	
	# 1. Tọa độ mặt đất (Lerp tuyến tính)
	var ground_pos := start_pos.lerp(target_pos, t)
	
	# 2. Độ cao giả lập không gian Parabola H(t)
	var h := 4.0 * max_height * t * (1.0 - t)
	
	# 3. Tính góc tiếp tuyến tức thời của quỹ đạo bay (vọt lên -> đỉnh phẳng -> chúc xuống đất)
	var dir := target_pos - start_pos
	# Đạo hàm dH/dt tỷ lệ với 4 * max_height * (1 - 2t)
	var vy := dir.y - 4.0 * max_height * (1.0 - 2.0 * t)
	var tangent_angle := atan2(vy, dir.x) + PI # Thêm PI vì sprite gốc quay mũi sang trái
	
	# 4. Cập nhật vị trí bóng chạy trên mặt đất
	if shadow_sprite:
		shadow_sprite.global_position = ground_pos
		# Càng lên cao bóng càng nhỏ và mờ; khi sắp chạm đất bóng to và đậm lại
		var shadow_scale := 1.0 - (h / max_height) * 0.45
		shadow_sprite.scale = Vector2(shadow_scale, shadow_scale * 0.55)
		shadow_sprite.modulate.a = 0.65 - (h / max_height) * 0.35
	
	# 5. Cập nhật vị trí và góc quay của viên đạn trên màn hình
	if shell_sprite:
		shell_sprite.global_position = ground_pos - Vector2(0.0, h)
		shell_sprite.rotation = tangent_angle
		
		# Kích thước 3D phóng to khi ở đỉnh cao và thu nhỏ khi lao xuống đất
		var scale_factor := 1.0 + (h / max_height) * 0.55
		shell_sprite.scale = Vector2.ONE * scale_factor

	# 6. XỬ LÝ 2 HOẠT ẢNH / GIAI ĐOẠN BAY
	if t < 0.5:
		# GIAI ĐOẠN 1: BỐC CAO LÊN NỬA ĐƯỜNG (Ascent)
		if ascent_particles and not ascent_particles.emitting:
			ascent_particles.emitting = true
		if descent_particles:
			descent_particles.emitting = false
	else:
		# MỐC NỬA ĐƯỜNG (APEX): Kích hoạt hiệu ứng chớp sáng đỉnh cực đại
		if not apex_reached:
			apex_reached = true
			if apex_spark:
				apex_spark.restart()
				apex_spark.emitting = true
			GlobalEvents.artillery_apex_reached.emit(shell_sprite.global_position)
		
		# GIAI ĐOẠN 2: QUA NỬA ĐƯỜNG (Descent - Lao dốc bổ nhào)
		if ascent_particles:
			ascent_particles.emitting = false
		if descent_particles and not descent_particles.emitting:
			descent_particles.emitting = true
	
	# 7. Khi t >= 1.0: Chạm đúng tọa độ mục tiêu -> Kích nổ AoE
	if t >= 1.0:
		explode()

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	# Hiệu ứng nổ
	if explosion_vfx_scene:
		var vfx := explosion_vfx_scene.instantiate() as Node2D
		vfx.global_position = target_pos
		get_parent().add_child(vfx)
	
	# Rung màn hình và âm thanh vụ nổ
	GlobalEvents.camera_shake_requested.emit(8.0, 0.35)
	AudioManager.play_explosion()
	
	# Quét sát thương AoE qua Physics Space State
	var space_state := get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = explosion_radius
	shape_query.shape = circle_shape
	shape_query.transform = Transform2D(0.0, target_pos)
	# Quét cả Vật thể/Thùng gỗ/Phuy xăng (Layer 1), Người chơi (Layer 2) và Địch (Layer 4)
	shape_query.collision_mask = 1 | 2 | 4
	
	var results := space_state.intersect_shape(shape_query)
	for hit in results:
		var collider = hit.get("collider")
		if collider and collider.has_method("take_damage"):
			var dist := target_pos.distance_to(collider.global_position)
			var damage_ratio := 1.0 - clampf(dist / explosion_radius, 0.0, 0.7)
			var actual_damage := int(base_damage * damage_ratio)
			collider.take_damage(actual_damage, true)
	
	queue_free()
