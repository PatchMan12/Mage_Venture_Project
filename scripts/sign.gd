extends Area2D

@export_multiline var message := "Hello, traveler!"
@export var bubble_offset_x := 0.0     
@export var bubble_offset_y := -40.0   

@onready var bubble: PanelContainer = $Bubble
@onready var label: Label = $Bubble/MessageLabel


func _ready() -> void:
	label.text = message
	bubble.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_show_bubble()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		bubble.hide()


func _show_bubble() -> void:
	
	bubble.size = bubble.get_combined_minimum_size()
	bubble.position = Vector2(
		-bubble.size.x / 2.0 + bubble_offset_x,
		bubble_offset_y - bubble.size.y
	)
	bubble.show()
