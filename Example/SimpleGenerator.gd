extends Node
export var noise: OpenSimplexNoise

# Returns value in position based on noise (value = texture index)
func get_value(pos):
	var value = noise.get_noise_2dv(pos)
	if value < -0.2:
		return 0
	elif value < -0.1:
		return 1
	elif value < 0.2:
		return 2
	else:
		return 3

# Returns height in position based on noise
func get_height(pos):
	var height = noise.get_noise_2dv(pos)
	height *= 6
	height *= abs(height)
	height = stepify(height,0.5)
	return height


# Radomises noise
func randomize_noise():
	if noise:
		randomize()
		noise.seed = randi()

# Random noise each time
func _ready():
	randomize_noise()

#########
## END ##
#########

# Additional enhancements

# Controls
var enterKeyPressed = false
func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ENTER:
			if event.pressed and not enterKeyPressed:
				randomize_noise()
				get_node("../SimplePCGTerrain").clean()
				enterKeyPressed = true
			elif !event.pressed and enterKeyPressed:
				enterKeyPressed = false

# Debug messages (from SimplePCGTerrain signals)
export var maxDebugLines: int = 20
var debugLines = 0
func chunk_spawned(chunkIndex):
	get_node("../ChunkDebug").text += "\nChunk spawned: "+str(chunkIndex)
	debugLines += 1
	skip_lines()

func chunk_removed(chunkIndex):
	get_node("../ChunkDebug").text += ". Chunk removed: "+str(chunkIndex)

func skip_lines():
	if debugLines > maxDebugLines:
		get_node("../ChunkDebug").lines_skipped += debugLines - maxDebugLines
		debugLines = maxDebugLines
