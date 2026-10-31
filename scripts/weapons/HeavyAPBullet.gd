class_name HeavyAPBullet
extends Area2D

## Đạn Súng Xuyên Giáp Hạng Nặng (Heavy Armor-Piercing Bullet)
## Vũ khí phụ mặc định cho Chuột phải hoặc Xe tăng địch hạng nặng.
## Tốc độ bắn chậm, thời gian hồi lâu hơn súng máy, nhưng sơ tốc cực cao và sát thương uy lực lớn.
## TÍNH NĂNG ĐỘC QUYỀN: Xuyên thấu đa mục tiêu và xuyên công sự phá hủy được!

@export var speed: float = 1350.0
@export var damage: int = 75 # Sát thương cực lớn công phá xe bọc thép
@export var lifetime: float = 0.65 # Tầm bắn ~850 px
@export var max_pierce: int = 3 # Cho phép xuyên qua tối đa 3 mục tiêu liên tiếp

var direction: Vector2 = Vector2.RIGHT
var is_enemy_bullet: bool = false
var current_damage: int = 75
var pierce_count: int = 0
var hit_entities: Array[Node2D] = []

func initialize(start_pos: Vector2, shoot_direction: Vector2, from_enemy: bool = false) -> void:
	global_position = start_pos
	direction = shoot_direction.normalized()
	rotation = direction.angle()
	is_enemy_bullet = from_enemy
	if is_enemy_bullet:
		collision_mask = 1 | 2 # Va chạm với Tường (1) và Người chơi (2)
		modulate = Color(1.3, 0.4, 0.4)
		current_damage = 30 # Địch bắn thì giảm sát thương cân bằng
		max_pierce = 1
	else:
		collision_mask = 1 | 4 # Va chạm với Tường (1) và Địch/Vật thể (4)
		current_damage = damage
		max_pierce = 3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body in hit_entities:
		return
		
	# Nếu đối tượng có thể nhận sát thương (xe địch, hòm gỗ, thùng xăng...)
	if body.has_method("take_damage"):
		hit_entities.append(body)
		body.take_damage(current_damage, false)
		GlobalEvents.camera_shake_requested.emit(4.5, 0.18)
		
		# Giảm nhẹ sát thương sau mỗi lần xuyên nhưng vẫn cực mạnh
		current_damage = int(float(current_damage) * 0.85)
		pierce_count += 1
		
		# Nếu đã xuyên đủ số mục tiêu tối đa thì nổ tan
		if pierce_count >= max_pierce:
			queue_free()
		return
	
	# Nếu đập vào tường bê tông kiên cố không thể phá hủy -> nổ tan
	queue_free()
