class_name Bush
extends Area2D

## Bụi Cây Ngụy Trang Quân Sự (Tactical Foliage / Concealment Bush)
## - Khi xe tăng đi vào bụi cây: Kích hoạt trạng thái ẩn thân (is_in_bush = true).
## - Giảm độ mờ của xe xuống 65% để người chơi nhận biết đang ẩn nấp.
## - Kẻ địch không thể nhìn thấy hoặc nhắm bắn người chơi trong bụi.
## - NẾU NGƯỜI CHƠI BẮN SÚNG TỪ TRONG BỤI: Vị trí sẽ bị lộ trong 2.5s (kẻ địch định vị được).

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var overlapping_tanks: Array[Node2D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 # Player (layer 2) & Enemy (layer 3 / mask 4)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body in overlapping_tanks:
		overlapping_tanks.append(body)
		
	if "is_in_bush" in body:
		body.is_in_bush = true
		
	# Hiệu ứng mờ nhẹ để báo hiệu đang ẩn thân
	if body.is_in_group("player"):
		var tween := create_tween()
		tween.tween_property(body, "modulate:a", 0.65, 0.2)
		# Rung nhẹ lá cây khi xe tiến vào
		if sprite:
			var sway := create_tween()
			sway.tween_property(sprite, "scale", Vector2(1.1, 0.95), 0.1)
			sway.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

func _on_body_exited(body: Node2D) -> void:
	overlapping_tanks.erase(body)
	
	# Kiểm tra xem xe này có đang nằm trong bụi cây nào khác không
	var still_in_another_bush := false
	var bushes := get_tree().get_nodes_in_group("bush")
	for b in bushes:
		if b != self and b is Bush and body in b.overlapping_tanks:
			still_in_another_bush = true
			break
			
	if not still_in_another_bush and "is_in_bush" in body:
		body.is_in_bush = false
		if body.is_in_group("player"):
			var tween := create_tween()
			tween.tween_property(body, "modulate:a", 1.0, 0.2)
