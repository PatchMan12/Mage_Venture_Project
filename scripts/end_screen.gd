extends Control

@export_file("*.tscn") var first_level: String   

@onready var background: ColorRect = $Background
@onready var center: CenterContainer = $CenterContainer

var can_restart := false


func _ready() -> void:
	
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)
	tween.tween_callback(func(): can_restart = true)


func _input(event: InputEvent) -> void:
	if can_restart and event.is_action_pressed("ui_accept"):
		if first_level.is_empty():
			push_warning("EndScreen: set First Level in the Inspector.")
			return
		can_restart = false
		get_tree().change_scene_to_file.call_deferred(first_level)
