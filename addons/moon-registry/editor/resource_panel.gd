@tool
extends Button

@export var registry: Registry

@export var resource: Resource:
	set(x):
		resource = x
		if not is_node_ready(): await ready
		
		if registry:
			icon = registry.get_icon(resource)
			text = registry.get_resource_name(resource)
			tooltip_text = text
			text = " " + text

func _pressed() -> void:
	if resource:
		EditorInterface.inspect_object(resource)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if get_global_rect().has_point(get_global_mouse_position()):
					EditorInterface.select_file(resource.resource_path)
