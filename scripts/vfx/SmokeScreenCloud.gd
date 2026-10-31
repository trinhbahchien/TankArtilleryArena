class_name SmokeScreenCloud
extends Area2D

## Màn Khói Mù Cố Định (Static Smoke Screen Cloud)
## - Đặt cố định tại vị trí thả trong thế giới, tồn tại 6 giây.
## - Render tại z_index = 15 để che khuất hoàn toàn tầm nhìn từ trên xuống của người chơi và AI.
## - Địch và Ta ở trong khói đều không nhìn thấy nhau; súng/pháo đi qua khói bị giảm 50% sát thương.
## - Chặn toàn bộ tia tầm nhìn (Line of Sight) của AI xuyên qua vùng khói.

@export var smoke_radius: float = 195.0
@export var duration: float = 6.0
var time_left: float = 6.0
var is_active: bool = true
var bodies_inside: Array[Node2D] = []

@onready var particles: CPUParticles2D = $RollingSmokeParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("smoke_screen")
	z_index = 15
	z_as_relative = false
	
	# Kết nối tín hiệu vào/ra vùng khói
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if particles:
		particles.emitting = true
		
	# Phát âm thanh xả khói nén
	AudioManager.play_smoke()

func _process(delta: float) -> void:
	if not is_active:
		return
		
	time_left -= delta
	
	# Trong 1.2 giây cuối cùng: Khói bắt đầu loãng dần và tan biến
	if time_left <= 1.2 and particles and particles.emitting:
		particles.emitting = false
		var fade_tween := create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 1.2)
		
	if time_left <= 0.0:
		_cleanup_and_destroy()

func _draw() -> void:
	# Lớp mây khói nền đặc nhiều tầng che phủ hoàn toàn bên dưới
	var center := Vector2.ZERO
	# Tầng lõi dày đặc (Opaque core)
	draw_circle(center, smoke_radius * 0.72, Color(0.22, 0.25, 0.28, 0.88))
	# Tầng rìa chuyển tiếp mềm mại (Soft edge)
	draw_circle(center, smoke_radius * 0.88, Color(0.28, 0.32, 0.36, 0.55))
	draw_circle(center, smoke_radius, Color(0.35, 0.39, 0.44, 0.28))

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body not in bodies_inside:
		bodies_inside.append(body)
		
	if "is_in_smoke" in body:
		body.is_in_smoke = true
		
	# Ẩn thanh máu và nhãn trạng thái khi chìm vào trong khói (Cả Ta và Địch đều không thấy)
	var hp_bar = body.get_node_or_null("FloatingHealthBar")
	if hp_bar:
		hp_bar.visible = false
	var state_lbl = body.get_node_or_null("StateLabel")
	if state_lbl:
		state_lbl.visible = false

func _on_body_exited(body: Node2D) -> void:
	if body in bodies_inside:
		bodies_inside.erase(body)
		
	# Chỉ bỏ trạng thái khói nếu thực thể không còn nằm trong màn khói nào khác
	if "is_in_smoke" in body:
		body.is_in_smoke = _check_if_body_in_any_other_smoke(body)
		
	# Khôi phục thanh máu khi ra khỏi khói
	var hp_bar = body.get_node_or_null("FloatingHealthBar")
	if hp_bar:
		hp_bar.visible = true
	var state_lbl = body.get_node_or_null("StateLabel")
	if state_lbl:
		state_lbl.visible = true

func _check_if_body_in_any_other_smoke(body: Node2D) -> bool:
	var smokes := get_tree().get_nodes_in_group("smoke_screen")
	for s in smokes:
		if s != self and is_instance_valid(s) and s is SmokeScreenCloud and s.is_active:
			if s.global_position.distance_to(body.global_position) <= s.smoke_radius:
				return true
	return false

func _cleanup_and_destroy() -> void:
	is_active = false
	# Khôi phục trạng thái cho các đơn vị còn kẹt lại khi khói tan
	for body in bodies_inside:
		if is_instance_valid(body):
			if "is_in_smoke" in body:
				body.is_in_smoke = false
			var hp_bar = body.get_node_or_null("FloatingHealthBar")
			if hp_bar:
				hp_bar.visible = true
			var state_lbl = body.get_node_or_null("StateLabel")
			if state_lbl:
				state_lbl.visible = true
				
	queue_free()

## Kiểm tra xem đoạn thẳng tầm nhìn giữa hai điểm (từ A đến B) có bị cắt ngang bởi màn khói nào không
static func is_line_blocked_by_smoke(from_pos: Vector2, to_pos: Vector2) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return false
	var smokes := tree.get_nodes_in_group("smoke_screen")
	for node in smokes:
		if not is_instance_valid(node) or not (node is SmokeScreenCloud):
			continue
		var smoke := node as SmokeScreenCloud
		if not smoke.is_active:
			continue
			
		var seg := to_pos - from_pos
		var seg_len_sq := seg.length_squared()
		if seg_len_sq == 0.0:
			if from_pos.distance_to(smoke.global_position) <= smoke.smoke_radius:
				return true
			continue
			
		var t := clampf((smoke.global_position - from_pos).dot(seg) / seg_len_sq, 0.0, 1.0)
		var closest_pt := from_pos + seg * t
		if closest_pt.distance_to(smoke.global_position) <= smoke.smoke_radius:
			return true
			
	return false
