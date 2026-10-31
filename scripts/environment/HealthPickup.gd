class_name HealthPickup
extends Area2D

## Hộp cứu thương / Vật phẩm hồi máu: Hồi +35 HP khi xe tăng (Người chơi hoặc Địch) đi qua

@export var heal_amount: int = 35

@onready var sprite: Sprite2D = $Sprite2D

var initial_y: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
	initial_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	elapsed += delta
	# Hiệu ứng trôi nổi nhẹ nhàng lên xuống
	if sprite:
		sprite.position.y = sin(elapsed * 4.0) * 4.0

func _on_body_entered(body: Node2D) -> void:
	var healed := false
	if body.has_node("HealthComponent"):
		var hc: HealthComponent = body.get_node("HealthComponent")
		if hc.current_health < hc.max_health:
			hc.heal(heal_amount)
			healed = true
	
	if healed:
		AudioManager.play_heal()
		queue_free()
