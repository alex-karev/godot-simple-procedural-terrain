extends Node
export var noise: OpenSimplexNoise
var enterKeyPressed = false

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
	height *= 4
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

# Controls
func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ENTER:
			if event.pressed and not enterKeyPressed:
				randomize_noise()
				get_node("../PCGTerrain").generate()
				enterKeyPressed = true
			elif !event.pressed and enterKeyPressed:
				enterKeyPressed = false
				
# Enhancements
func _process(delta):
	var terrain = get_node("../PCGTerrain")
	terrain.rotate_y(0.5*delta)
