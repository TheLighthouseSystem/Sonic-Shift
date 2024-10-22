extends Area2D

signal ring_collected

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	animated_sprite.play("default")
	connect("body_entered", _on_body_entered)
	# Connect the signal to the _on_ring_collected() function
	connect("ring_collected", get_parent().get_node("Player")._on_ring_collected)

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("ring_collected")
		queue_free()
