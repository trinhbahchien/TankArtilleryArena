class_name ShotgunPellet
extends Area2D

## Mảnh Đạn Súng Shotgun Tán Xạ (Shotgun Spread Pellet)
## Bắn chùm rẻ quạt cận chiến cực mạnh, tầm bắn ngắn ~360 px.
## Dùng được cho cả Người chơi (Chuột phải) lẫn Xe Địch Đột Kích Shotgun.

@export var speed: float = 850.0
@export var damage: int = 11
@export var lifetime: float = 0.42

var direction: Vector2 = Vector2.RIGHT
var is_enemy_bullet: bool = false

func initialize(start_pos: Vector2, shoot_direction: Vector2, from_enemy: bool = false) -> void:
	global_position = start_pos
	direction = shoot_direction.normalized()
	rotation = direction.angle()
	is_enemy_bullet = from_enemy
	if is_enemy_bullet:
		collision_mask = 1 | 2 # Va chạm với Tường (1) và Người chơi (2)
		modulate = Color(1.3, 0.3, 0.3)
	else:
		collision_mask = 1 | 4 # Va chạm với Tường (1) và Địch (4)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, false)
	queue_free()
