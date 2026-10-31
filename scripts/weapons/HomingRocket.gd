class_name HomingRocket
extends Area2D

## Tên Lửa Tự Hành Tầm Xa (Homing Micro-Rocket)
## Phóng vọt lên rồi tự động lượn bám theo mục tiêu gần nhất, phát nổ AoE 80px.
## Cơ chế Khói Mù Tác Chiến: Khi mục tiêu mở khói mù hoặc núp trong khói,
## cảm biến tên lửa bị vô hiệu hóa hoàn toàn, mất khóa và bay loạn xạ không thể bám đuổi!

@export var speed: float = 580.0
@export var turn_speed: float = 4.2
@export var damage: int = 42
@export var aoe_radius: float = 80.0
@export var lifetime: float = 2.8
@export var explosion_vfx: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var target_node: Node2D = null
var current_dir: Vector2 = Vector2.RIGHT
var is_confused: bool = false
var confused_timer: float = 0.0
var random_phase: float = 0.0

func initialize(start_pos: Vector2, initial_dir: Vector2, target: Node2D = null) -> void:
	global_position = start_pos
	current_dir = initial_dir.normalized()
	rotation = current_dir.angle()
	target_node = target
	random_phase = randf_range(0.0, TAU)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		explode()
		return
		
	_check_smoke_interference()
		
	if is_confused:
		# Bay loạn xạ: Đảo hướng liên tục với biên độ lớn và tần số cao khi bị khói làm mù cảm biến
		confused_timer += delta
		var wobble := sin(confused_timer * 16.0 + random_phase) * 9.5 + cos(confused_timer * 8.0) * 6.0
		current_dir = current_dir.rotated(wobble * delta).normalized()
	else:
		# Nếu mục tiêu còn sống và không bị che khuất, tự động bẻ lái bám theo
		if is_instance_valid(target_node):
			if _is_node_concealed(target_node):
				# Mục tiêu vừa mở khói hoặc trốn vào khói -> Mất dấu ngay lập tức!
				is_confused = true
				target_node = null
			else:
				var to_target := (target_node.global_position - global_position).normalized()
				current_dir = current_dir.slerp(to_target, turn_speed * delta).normalized()
		else:
			_find_nearest_target()
		
	rotation = current_dir.angle()
	global_position += current_dir * speed * delta

func _check_smoke_interference() -> void:
	if is_confused:
		return
	# Nếu tên lửa bay xuyên qua hoặc ở gần bất kỳ đám khói mù nào
	var smoke_clouds := get_tree().get_nodes_in_group("smoke_screen")
	for cloud in smoke_clouds:
		if is_instance_valid(cloud) and cloud is Node2D:
			var cloud_radius := 195.0
			if "smoke_radius" in cloud:
				cloud_radius = cloud.smoke_radius
			if global_position.distance_to(cloud.global_position) <= cloud_radius:
				is_confused = true
				target_node = null
				break

func _is_node_concealed(node: Node2D) -> bool:
	if not is_instance_valid(node):
		return true
	if node.has_method("is_concealed") and node.is_concealed():
		return true
	if "is_in_smoke" in node and node.is_in_smoke:
		return true
	if "is_in_bush" in node and node.is_in_bush:
		if "bush_reveal_timer" in node and node.bush_reveal_timer <= 0.0:
			return true
	return false

func _find_nearest_target() -> void:
	if is_confused:
		return
		
	# Tự động tìm mục tiêu hợp lệ (không ẩn mình trong khói)
	var possible_targets := get_tree().get_nodes_in_group("enemy")
	var nearest_dist := 99999.0
	for e in possible_targets:
		if is_instance_valid(e) and e is Node2D:
			if _is_node_concealed(e):
				continue
			var d := global_position.distance_to(e.global_position)
			if d < nearest_dist:
				nearest_dist = d
				target_node = e

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	explode()

func _on_area_entered(area: Area2D) -> void:
	if area == self or area.is_in_group("smoke_screen"):
		return
	explode()

func explode() -> void:
	if explosion_vfx:
		var vfx := explosion_vfx.instantiate() as Node2D
		vfx.global_position = global_position
		get_parent().add_child(vfx)
		
	AudioManager.play_explosion()
	GlobalEvents.camera_shake_requested.emit(5.0, 0.25)
	
	# AoE Damage
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = aoe_radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1 | 2 | 4 # Obstacles, Players & Enemies
	
	var hits := space_state.intersect_shape(query)
	for hit in hits:
		var col = hit.get("collider")
		if col and col.has_method("take_damage"):
			col.take_damage(damage, true)
			
	queue_free()
