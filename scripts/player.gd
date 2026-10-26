extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal attack_changed(icon: Texture2D)
signal died

const SPEED = 300.0
const JUMP_VELOCITY = -300.0

@export_group("Attacks")

@export var attack_scenes: Array[PackedScene]
@export var attack_costs: Array[float] = [20.0, 25.0, 15.0, 30.0]
@export var attack_icons: Array[Texture2D]
@export var spawn_offset := Vector2(30, -5)   
@export var cast_delay := 0.15

@export_group("Health")
@export var max_health := 100.0
@export var invincible_time := 1.0     

@export_group("Mana")
@export var max_mana := 100.0
@export var mana_regen := 10.0         
@export var mana_regen_delay := 1.0   

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var health := 0.0
var mana := 0.0
var current_attack := 0
var is_attacking := false
var knockback_timer := 0.0
var invincible_timer := 0.0
var regen_timer := 0.0
var facing := 1                   
var is_dead := false


func _ready() -> void:
	add_to_group("player")
	health = max_health
	mana = max_mana
	animated_sprite.sprite_frames.set_animation_loop("attack", false)
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)

	
	if not is_on_floor():
		velocity += get_gravity() * delta

	
	if knockback_timer > 0.0:
		knockback_timer -= delta
		move_and_slide()
		_update_animation(0.0)
		return

	
	if Input.is_action_just_pressed("switch_attack") and not is_attacking:
		_switch_attack()

	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_start_attack()

	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction and not is_attacking:
		velocity.x = direction * SPEED
		facing = 1 if direction > 0 else -1
		animated_sprite.flip_h = facing < 0   
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_update_animation(direction)


func _update_timers(delta: float) -> void:
	
	if regen_timer > 0.0:
		regen_timer -= delta
	elif mana < max_mana:
		mana = minf(mana + mana_regen * delta, max_mana)
		mana_changed.emit(mana, max_mana)

	
	if invincible_timer > 0.0:
		invincible_timer -= delta
		animated_sprite.visible = int(invincible_timer * 20.0) % 2 == 0
		if invincible_timer <= 0.0:
			animated_sprite.visible = true


func _switch_attack() -> void:
	if attack_scenes.is_empty():
		return
	current_attack = (current_attack + 1) % attack_scenes.size()
	emit_attack_changed()


func emit_attack_changed() -> void:
	var icon: Texture2D = null
	if current_attack < attack_icons.size():
		icon = attack_icons[current_attack]
	attack_changed.emit(icon)


func _current_cost() -> float:
	if current_attack < attack_costs.size():
		return attack_costs[current_attack]
	return 20.0


func _start_attack() -> void:
	if attack_scenes.is_empty():
		push_warning("Add your attack scenes to Attack Scenes on the player.")
		return

	
	if mana < _current_cost():
		return

	is_attacking = true
	animated_sprite.play("attack")

	if cast_delay > 0.0:
		await get_tree().create_timer(cast_delay).timeout
		
		if not is_attacking or is_dead:
			return

	_shoot()


func _shoot() -> void:
	var scene := attack_scenes[current_attack]
	if scene == null:
		push_warning("Attack scene %d is empty." % current_attack)
		return

	
	mana -= _current_cost()
	regen_timer = mana_regen_delay
	mana_changed.emit(mana, max_mana)

	var projectile = scene.instantiate()
	projectile.direction = facing
	projectile.global_position = global_position + Vector2(spawn_offset.x * facing, spawn_offset.y)
	get_parent().add_child(projectile)   


func apply_knockback(from_position: Vector2, force: float, up_only := false, damage := 0.0) -> void:
	
	if invincible_timer > 0.0 or is_dead:
		return

	var dir := 0.0
	if not up_only:
		dir = signf(global_position.x - from_position.x)
		if dir == 0.0:
			dir = 1.0
	velocity = Vector2(dir * force, -force * 0.5) 
	knockback_timer = 0.25
	is_attacking = false

	invincible_timer = invincible_time
	take_damage(damage)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func die() -> void:
	
	if is_dead:
		return
	health = 0.0
	health_changed.emit(health, max_health)
	_die()


func _die() -> void:
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	animated_sprite.visible = true
	animated_sprite.modulate = Color(1.0, 0.3, 0.3)
	died.emit()


func _update_animation(direction: float) -> void:
	
	if is_attacking:
		return

	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")


func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
