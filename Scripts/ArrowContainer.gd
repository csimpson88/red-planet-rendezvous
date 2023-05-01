extends Container

@onready var arrow : Sprite2D = $Arrow

func set_direction(angle : float):
	arrow.rotation = angle - PI/2.0
	var center = size/2.0
	var p = Vector2.RIGHT.rotated(angle) * size.x
	arrow.position.x = center.x + clamp(p.x, -size.x/2.0, size.x/2.0)
	arrow.position.y = center.y + clamp(p.y, -size.y/2.0, size.y/2.0)
