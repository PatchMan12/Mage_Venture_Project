extends Area2D

@export_file("*.tscn") var next_scene: String   
@export var prompt_text := "Press E"

@onready var prompt: Label = $PromptLabel

var player_in_range := false


func _ready() -> void:
	prompt.text = prompt_text
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		_enter()


func _enter() -> void:
	if next_scene.is_empty():
		push_warning("Door: set Next Scene in the Inspector.")
		return
	player_in_range = false
	get_tree().change_scene_to_file.call_deferred(next_scene)
