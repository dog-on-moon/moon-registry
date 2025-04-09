@tool
extends EditorPlugin

var main_panel_instance

func _enter_tree():
	main_panel_instance = load("res://addons/resource_registry/editor/registry_editor.tscn").instantiate()
	main_panel_instance.plugin = self
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)

func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()
		main_panel_instance = null

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name():
	return "Registry"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Object", "EditorIcons")

func reload():
	_exit_tree()
	_enter_tree()
	_make_visible(true)
	print('Registry Editor reloaded.')
