extends Node2D

var player : CharacterBody2D
var camera : Camera2D

var follow_player = true
var follow_threshold = 50  # dead zone size (50px to the left and right)
var dampening_factor = 0.05  # adjust this value to control the dampening effect

func _ready():
	player = get_node("Player") as CharacterBody2D
	camera = get_node("Camera2D")
	if camera == null:
		push_error("Camera2D node not found in the scene.")
		set_process(false)

func _physics_process(delta):
	if follow_player and camera != null:
		var player_position = player.global_position
		var camera_position = camera.global_position

		# Calculate the difference between the player and camera positions
		var offset = player_position - camera_position

		# Apply the dead zone
		if abs(offset.x) < follow_threshold:
			offset.x = 0
		if abs(offset.y) < float("inf"):
			offset.y = 0

		# Apply the dampening effect
		camera_position += offset * dampening_factor

		# Update the camera's position
		camera.global_position = camera_position
