extends Path2D

onready var path = get_node('PathFollow2D')
onready var tween = get_node('Tween')


func _send(start):
	var crv = get_curve().duplicate()

	# Update curve
	crv.set_point_pos(0, start)
	crv.set_point_pos(1, Vector2(start.x/2, start.y-200))
	crv.set_point_in(1, Vector2(start.x, 0))
	crv.set_point_pos(2, Vector2())

	set_curve(crv)

	var length = crv.get_baked_length()
	var time = length / 500 + randf()

	tween.interpolate_property(path, 'offset', 0, length, time, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()

func _on_fly_end(object, key):
	self.queue_free()
	Global.sfx('bubblein')