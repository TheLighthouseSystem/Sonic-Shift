extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100
@export var max_speed : float = 400.0  # Maximum speed
@export var acceleration : float = 800.0  # Acceleration rate
@export var friction : float = 5  # Friction rate
@export var rotation_speed : float = 5
@export var momentum_factor : float = 0.01  # Factor to apply momentum
@export var lives : int = 3 # Default lives
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var ring_count : int = 0
@onready var jump_sound : AudioStreamPlayer2D = $JumpSound
@onready var ring_collect_sound : AudioStreamPlayer2D = $RingCollectSound
@onready var ring_count_label : Label = $GUI/RingCountLabel
@onready var lives_count_label : Label = $GUI/LivesLabel
@export var respawn_position: Vector2 = Vector2(100, 300)  # Default respawn position
@onready var pause_screen : ColorRect = $Pause/PauseScreen


var elapsed_time: int = 0  # To keep track of elapsed seconds
@onready var timer_label: Label = $GUI/TimerLabel  # Label for the timer.
@onready var timer: Timer = $GUI/Timer
@onready var bored_timer: Timer = $BoredTimer  # Sonic's boredom timer.
var is_bored: bool = false  # Sonic is not bored by default.


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var dead : bool = false
var respawn : Vector2 = Vector2(0,0)
var is_paused = false

@onready var fade_rect : ColorRect = $FadeRect 

func _ready():
	#print("The name of this node is: ", self.name)
	add_to_group("player")
	lives_count_label.text = "LIVES: " + str(lives)
	# Set the base rotation to 90 degrees counterclockwise (-PI / 2 radians)
	rotation = 0  # This sets the initial rotation to face left
	var rings = get_tree().get_nodes_in_group("rings")
	for ring in rings:
		ring.connect("ring_collected", _on_ring_collected)
	timer.start()  # Start the timer
	print("Timer started")  # Debug print
	animated_sprite.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))

	# Connect the timeout signal to the function using Callable
	timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	# Sonic gets bored.
	bored_timer.connect("timeout", Callable(self, "_on_BoredTimer_timeout"))
	#print("Player position: ", position)
	respawn.x = position.x
	respawn.y = position.y

func _on_ring_collected():
	ring_count += 1
	ring_collect_sound.bus = "Ring Reverb" # Use the custom audio bus with reverb
	ring_collect_sound.play()
	ring_count_label.text = "RINGS: " + str(ring_count)
	
func _on_Timer_timeout():
	# Increment the elapsed time
	elapsed_time += 1
	
	# Update the TimerLabel
	var minutes: int = elapsed_time / 60  # This line is fine, but you can use float if needed
	var seconds: int = elapsed_time % 60
	timer_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

func _respawn():
	position = respawn
	dead = false
	bored_timer.paused = false

func fade_to_black(fade_rect: ColorRect, direction: float, duration: float) -> void:
	var start_alpha = fade_rect.modulate.a
	var end_alpha = 1.0 if direction > 0 else 0.0  # Ternary syntax for end alpha

	for t in range(0, 101):  # Loop from 0 to 100
		var alpha = lerp(start_alpha, end_alpha, t / 100.0)  # Interpolate alpha
		fade_rect.modulate.a = alpha  # Set the alpha value
		await get_tree().create_timer(duration / 100.0).timeout  # Wait a short time

	fade_rect.modulate.a = end_alpha  # Ensure we set the final alpha value

func _input(event):
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause():
	is_paused = !is_paused
	pause_screen.visible = is_paused
	if is_paused:
		pause_game_logic()
	else:
		unpause_game_logic()

func pause_game_logic():
	# Pause the player
	bored_timer.stop()  # Stop the timer
	bored_timer.paused = true  # Resume the bored timer
	timer.stop()
	timer.paused = true
	set_physics_process(false)

func unpause_game_logic():
	# Unpause the timers
	bored_timer.start()  # Stop the timer
	bored_timer.paused = false  # Resume the bored timer
	timer.start()
	timer.paused = false
	set_physics_process(true)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor_only() and not is_on_wall():
		velocity.y += gravity * delta
		was_in_air = true
		bored_timer.paused = true
	else:
		if was_in_air:
			land()
		was_in_air = false

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor_only():
		jump()

	# Get the input direction and handle the movement.
	direction = Input.get_vector("left", "right", "up", "down")

	# Apply friction to slow down the character.
	if direction.x == 0:
		# Apply friction directly to the velocity
		velocity.x = velocity.x * (1 - friction * delta)
		bored_timer.paused = false
	else:
		# Accelerate the character in the direction of the input.
		velocity.x += acceleration * direction.x * delta
		bored_timer.paused = true

	# Apply momentum
	velocity.x += momentum_factor * direction.x * delta

	# Clamp the horizontal velocity
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	# Move the character
	move_and_slide()  # No arguments in Godot 4.3
	
	# Handle bored state
	if direction == Vector2.ZERO:
		if bored_timer.is_stopped():
			bored_timer.start()
	else:
		if is_bored:
			is_bored = false
			animated_sprite.play("normal")  # Play normal animation
		bored_timer.stop()  # Stop the timer
		bored_timer.paused = false  # Resume the bored timer

	update_animation()
	update_facing_direction()
	
	if global_position.y > get_viewport_rect().size.y + 200 and not dead:  # Adjust the threshold as needed
		animation_locked = true  # Lock the animation to prevent interruptions
		animated_sprite.play("death")
		dead = true
		lives -= 1
		lives_count_label.text = "LIVES: " + str(lives)
		bored_timer.paused = true
		# Fade out
		fade_rect.visible = true  # Make the fade rect visible
		fade_rect.modulate.a = 0  # Start with transparent
		await fade_to_black(fade_rect, 1.0, 0.25)
		# Wait for a moment before respawning
		await get_tree().create_timer(0.25).timeout
		_respawn()  # Call the respawn function
		# Fade in
		await fade_to_black(fade_rect, -1.0, 0.25)   # Fade back in
		

func _on_animated_sprite_2d_animation_finished():
	if ["jump_end", "jump_double"].has(animated_sprite.animation):
		animation_locked = false
	elif animated_sprite.animation == "bored_enter":
		#print("Sonic: Snooze City in here...")
		animated_sprite.play("bored_loop")
		animation_locked = false  # Lock the animation to prevent interruptions
		bored_timer.paused = true

func update_animation():
	if not animation_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		elif is_bored:
			animated_sprite.play("bored_loop")
			bored_timer.paused = true
		else:
			if abs(velocity.x) < 1:
				animated_sprite.play("idle")
			elif abs(velocity.x) < 75:
				animated_sprite.play("slow_jog")
			elif abs(velocity.x) < 150:
				animated_sprite.play("jog")
			elif abs(velocity.x) < 370:
				animated_sprite.play("run")
			else:
				animated_sprite.play("run_fast")

func _on_BoredTimer_timeout():
	is_bored = true
	animation_locked = true
	animated_sprite.play("bored_enter")
	bored_timer.stop()  # Stop the bored timer
	bored_timer.paused = true  # Pause the bored timer



func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func jump():
	jump_sound.pitch_scale = randf_range(0.85, 1.15)
	jump_sound.play()
	velocity.y = jump_velocity
	animated_sprite.play("jump_loop")
	animation_locked = true


func land():
	if abs(velocity.x) < 1:
		animated_sprite.play("jump_end")
		animation_locked = true
	else:
		animation_locked=false
