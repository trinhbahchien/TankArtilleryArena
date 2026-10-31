class_name TwinCannonBullet
extends Area2D

## Đạn Pháo Xuyên Giáp Tốc Độ Cao (Twin Kinetic AP Shell)
## Bay theo đường thẳng với vận tốc cực nhanh (950 px/s), xuyên phá công sự và xe tăng địch

@export var speed: float = 950.0
@export var damage: int = 38
@export var lifetime: float = 1.6

var direction: Vector2 = Vector2.RIGHT

@onready var trail: CPUParticles2D = $TrailParticles

func initialize(start_pos: Vector2, dir: Vector2, from_enemy: bool = false) -> void:
	global_position = start_pos
	direction = dir.normalized()
	rotation = direction.angle()
	if from_enemy:
		collision_mask = 1 | 2 # Tường (1) và Người chơi (2)
		modulate = Color(1.3, 0.45, 0.3)
	else:
		collision_mask = 1 | 4 # Tường (1) và Địch (4)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, true)
	_spawn_impact()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		_spawn_impact()
		queue_free()

func _spawn_impact() -> void:
	AudioManager.play_explosion()
	GlobalEvents.camera_shake_requested.emit(4.0, 0.2)
