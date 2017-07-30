extends Area2D

var active
signal checkpoint
onready var ready = true


func _on_Checkpoint_body_entered(body):
	if !ready or active: return

	# Only works with player, granted by collision mask
	if !is_connected('checkpoint', body, '_on_checkpoint'): connect('checkpoint', body, '_on_checkpoint')

	active = true
	emit_signal('checkpoint')

	Global.playerHp = body.hpMax
	Global.playerSpawnPosition = get_node('Lamp').get_global_position()
	Global.sfx('checkpoint')

	get_node('AnimationPlayer').play('activate')