extends RemoteTransform2D

@onready var camera : Camera2D = $Camera2D2

var player : CharacterBody2D

var follow_player = true
var follow_threshold = 100  # dead zone size
var dampening_factor = 0.05  # adjust this value to control the dampening effect

func _ready():
	player = get_node("../../Player") as CharacterBody2D
	print(player)

func _physics_process(delta):
	if player != null and follow_player:
		var target_position = player.position
		var current_position = position

		# calculate the offset from the target position
		var offset = target_position - current_position

		# apply dead zone
		if offset.length() < follow_threshold:
			return  # do nothing if within dead zone

		# apply dampening to the offset
		offset = offset.normalized() * (offset.length() - follow_threshold)
		offset *= dampening_factor

		# move the camera towards the target position
		position += offset
