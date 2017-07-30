extends Node

const DEAD_HEIGHT = 0

# Data storage
var playerSpawnPosition = null
var playerHp = null

var sfxNames = ['bubblein', 'bubbleout', 'checkpoint', 'damage', 'dead', 'jump', 'move', 'ressurect']
var sfxVolumes = [-4, -6, 0, 0, 0, -8, -10, 0]
var sfxResources = []


func _ready():
	for sfxn in sfxNames:
		sfxResources.push_back(load(str('res://sounds/', sfxn, '.wav')))
		sfxResources.back().set_loop_mode(0)


func sfx(name):
	var idx = sfxNames.find(name)
	var sfx
	var vol = 0

	if idx == -1: return

	# Pick free player
	for i in range(8):
		sfx = get_node(str('Sfx', i))

		if sfx.is_playing():
			sfx = null
		else:
			break

	# No free players, pick first
	if !sfx: sfx = get_node('Sfx0')
	if sfxVolumes.size() >= idx: vol = sfxVolumes[idx]

	sfx.stop()
	sfx.set_stream(sfxResources[idx])
	sfx.set_volume_db(vol)
	sfx.play()