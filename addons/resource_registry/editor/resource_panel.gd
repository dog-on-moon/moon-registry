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
