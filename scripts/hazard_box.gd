class_name HazardBox
extends Area2D

@export var damage := 10.0
@export var knockback_force := 350.0
@export var launch_up_only := false   
@export var rehit_delay := 0.8        

var cooldown := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	
	if not monitoring:
		return

	if cooldown > 0.0:
		cooldown -= delta
		return

	
	for body in get_overlapping_bodies():
		_hit(body)


func _on_body_entered(body: Node2D) -> void:
	_hit(body)


func _hit(body: Node2D) -> void:
	if cooldown > 0.0:
		return
	if body.is_in_group("player") and body.has_method("apply_knockback"):
		body.apply_knockback(global_position, knockback_force, launch_up_only, damage)
		cooldown = rehit_delay
