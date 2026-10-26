extends CharacterBody2D

enum Behavior { PATROL, WATCH }
enum State { IDLE, CHASE }

@export_group("Behavior")
@export var behavior: Behavior = Behavior.PATROL  
@export var patrol_speed := 60.0
@export var patrol_distance := 150.0
@export var watch_interval := 2.0

@export_group("Vision")
@export var vision_range := 220.0
@export var vision_angle := 140.0
@export var lose_range := 350.0
@export var lose_sight_time := 1.5

@export_group("Chase")
@export var chase_speed := 140.0

@export_group("Ledge")
@export var ledge_check_distance := 20.0   
@export var ledge_check_depth := 40.0      

@export_group("Health")
@export var lives := 3
@export var invincible_time := 0.4
@export var hurt_stun_time := 0.25

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var state := State.IDLE
var facing := 1                
var start_x := 0.0
var watch_timer := 0.0
var lost_sight_timer := 0.0
var hurt_timer := 0.0
var invincible_timer := 0.0
var is_dead := false
var flash_tween: Tween
var player: Node2D


func _ready() -> void:
	add_to_group("enemy")
	start_x = global_position.x
	watch_timer = watch_interval


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if invincible_timer > 0.0:
		invincible_timer -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta

	
	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0, 600.0 * delta)
		move_and_slide()
		return

	match state:
		State.IDLE:
			_idle_state(delta)
		State.CHASE:
			_chase_state(delta)

	move_and_slide()
	animated_sprite.flip_h = facing > 0   


func take_hit(from_position: Vector2, force: float) -> void:
	if is_dead or invincible_timer > 0.0:
		return

	lives -= 1
	invincible_timer = invincible_time
	_flash_red()

	if lives <= 0:
		_die()
		return

	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity = Vector2(dir * force, -force * 0.4)
	hurt_timer = hurt_stun_time

	
	state = State.CHASE
	lost_sight_timer = 0.0


func _flash_red() -> void:
	if flash_tween:
		flash_tween.kill()
	animated_sprite.modulate = Color(1.0, 0.3, 0.3)
	flash_tween = create_tween()
	flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.3)


func _die() -> void:
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	var hazard := get_node_or_null("HazardBox")
	if hazard:
		hazard.set_deferred("monitoring", false)

	if flash_tween:
		flash_tween.kill()
	animated_sprite.modulate = Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _idle_state(delta: float) -> void:
	if _can_see_player():
		state = State.CHASE
		lost_sight_timer = 0.0
		return

	match behavior:
		Behavior.PATROL:
			velocity.x = facing * patrol_speed
			var at_right_limit := facing == 1 and global_position.x >= start_x + patrol_distance
			var at_left_limit := facing == -1 and global_position.x <= start_x - patrol_distance
			if is_on_wall() or at_right_limit or at_left_limit or _ledge_ahead():
				facing *= -1
			_play("walk")

		Behavior.WATCH:
			velocity.x = move_toward(velocity.x, 0, patrol_speed)
			watch_timer -= delta
			if watch_timer <= 0.0:
				facing *= -1
				watch_timer = watch_interval
			_play("idle")


func _chase_state(delta: float) -> void:
	if player == null:
		state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if _has_line_of_sight():
		lost_sight_timer = 0.0
	else:
		lost_sight_timer += delta

	if distance > lose_range or lost_sight_timer >= lose_sight_time:
		state = State.IDLE
		start_x = global_position.x
		watch_timer = watch_interval
		return

	var dx := player.global_position.x - global_position.x
	if absf(dx) > 4.0:
		facing = 1 if dx > 0 else -1
		if _ledge_ahead():
			
			velocity.x = 0.0
			_play("idle")
		else:
			velocity.x = facing * chase_speed
			_play("walk")
	else:
		velocity.x = 0.0
		_play("idle")


func _can_see_player() -> bool:
	if player == null:
		return false

	var to_player := player.global_position - global_position
	if to_player.length() > vision_range:
		return false

	var angle := rad_to_deg(Vector2(facing, 0).angle_to(to_player))
	if absf(angle) > vision_angle / 2.0:
		return false

	return _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, player.global_position, 1, [get_rid()]
	)
	var result := space.intersect_ray(query)
	return result.is_empty() or result.collider == player


func _ledge_ahead() -> bool:
	if not is_on_floor():
		return false

	
	var from := global_position + Vector2(facing * ledge_check_distance, 0.0)
	var to := from + Vector2(0.0, ledge_check_depth)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1, [get_rid()])
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()   


func _play(anim: StringName) -> void:
	var frames := animated_sprite.sprite_frames
	if frames and frames.has_animation(anim) and animated_sprite.animation != anim:
		animated_sprite.play(anim)
