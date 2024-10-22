extends Control

var dialogue_text: String = ""
var is_dialogue_visible: bool = false

@onready var dialogue_panel = $Panel
@onready var dialogue_label = $Panel/Label

func show_dialogue(text: String) -> void:
	dialogue_text = text
	dialogue_label.text = dialogue_text
	dialogue_panel.visible = true
	is_dialogue_visible = true

func hide_dialogue() -> void:
	dialogue_panel.visible = false
	is_dialogue_visible = false
