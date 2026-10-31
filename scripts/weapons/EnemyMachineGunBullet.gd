class_name EnemyMachineGunBullet
extends Area2D

## Đạn súng máy của xe tăng địch bắn vào Player (bị tường chặn)

@export var speed: float = 950.0
@export var damage: int = 4
@export var lifetime: float = 1.2

var direction: Vector2 = Vector2.RIGHT

func initialize(start_pos: Vector2, shoot_direction: Vector2) -> void:
	global_position = start_pos
	direction = shoot_direction.normalized()
	rotation = direction.angle()

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
