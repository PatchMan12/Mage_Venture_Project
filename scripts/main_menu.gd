extends Node2D

@export_file("*.tscn") var first_level: String   

@onready var play_button: Area2D = $PlayButton
@onready var background: Sprite2D = $Background

var hovering := false


func _ready() -> void:
	play_button.input_pickable = true
	play_button.mouse_entered.connect(_on_mouse_entered)
	play_button.mouse_exited.connect(_on_mouse_exited)
	play_button.input_event.connect(_on_play_input)


func _on_mouse_entered() -> void:
	hovering = true
	
	background.modulate = Color(1.15, 1.15, 1.15)


func _on_mouse_exited() -> void:
	hovering = false
	background.modulate = Color.WHITE


func _on_play_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play()


func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_accept"):
		_play()


func _play() -> void:
	if first_level.is_empty():
		push_warning("MainMenu: set First Level in the Inspector.")
		return
	set_process_unhandled_input(false)
	get_tree().change_scene_to_file.call_deferred(first_level)
