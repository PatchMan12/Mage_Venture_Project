extends Area2D

@export var speed := 110.0
@export var knockback_force := 300.0
@export var lifetime := 10.0

var direction := 1                   


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.flip_h = direction < 0   
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	  

	
	if body.is_in_group("player"):
		return

	if body.is_in_group("enemy") and body.has_method("take_hit"):
		body.take_hit(global_position, knockback_force)

	
	queue_free()
