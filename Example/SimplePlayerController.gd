extends CharacterBody3D

@export var speed: float = 20.0
@export var gravity: float = 8.0
@export var spawnHeight: float = 10.0
@export var deathHeight: float = -20.0
var axis = Vector2.ZERO

func _ready():
	global_transform.origin.y = spawnHeight

# Controls
func _unhandled_input(event):
	axis = Vector2.ZERO
	if Input.is_action_just_pressed("ui_up"):
		axis.y -= 1
	if Input.is_action_pressed("ui_down"):
		axis.y += 1
	if Input.is_action_pressed("ui_left"):
		axis.x -= 1
	if Input.is_action_pressed("ui_right"):
		axis.x += 1
		
# Movement
func _physics_process(delta):
	velocity = Vector3(axis.x,0,axis.y)*speed + Vector3.DOWN*gravity
	move_and_slide()
	# Fix endless fall
	if global_transform.origin.y < deathHeight:
		global_transform.origin.y = spawnHeight
