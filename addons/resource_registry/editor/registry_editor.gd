@tool
extends VBoxContainer

@onready var reload_button: Button = %ReloadButton
@onready var create_button: Button = %CreateButton
@onready var registry_container: VBoxContainer = %RegistryContainer

@export var base_style_box: StyleBoxFlat
@export var alt_style_box: StyleBoxFlat

var plugin: EditorPlugin

func _ready() -> void:
	#create_button.icon = EditorInterface.get_editor_theme().get_icon("FolderCreate", "EditorIcons")
	#reload_button.icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")
	if self == get_tree().edited_scene_root: return
	reload_button.pressed.connect(plugin.reload)
	create_button.pressed.connect(_create_registry)
	var c := RegistryCollection.get_collection()
	c.registries.map(add_registry)
	c.registry_added.connect(add_registry)
	c.registry_removed.connect(remove_registry)
	c.registry_reordered.connect(update_registry_styles)
	_rescan_complete()

const REGISTRY_PANEL = preload("res://addons/resource_registry/editor/registry_panel.tscn")

var registry_to_panel: Dictionary[Registry, Control] = {}
var registry_panels: Array[Control] = []

func add_registry(r: Registry):
	var panel := REGISTRY_PANEL.instantiate()
	panel.registry = r
	registry_to_panel[r] = panel
	registry_panels.append(panel)
	registry_container.add_child(panel)
	update_registry_styles()
	
	r.rescan_complete.connect.call_deferred(_rescan_complete)

func remove_registry(r: Registry):
	if r not in registry_to_panel:
		return
	var panel := registry_to_panel[r]
	registry_to_panel.erase(r)
	registry_panels.erase(panel)
	panel.queue_free()
	update_registry_styles()
	
	r.rescan_complete.disconnect(_rescan_complete)

func update_registry_styles():
	var c := RegistryCollection.get_collection()
	for idx in c.registries.size():
		var r: Registry = c.registries[idx]
		var panel: Control = registry_to_panel.get(r, null)
		if panel:
			registry_container.move_child(panel, idx)
			var sb := alt_style_box if idx % 2 else base_style_box
			panel.add_theme_stylebox_override(&"panel", sb)

func _create_registry():
	var registry := Registry.new()
	RegistryCollection.get_collection().add_registry(registry)
	EditorInterface.inspect_object(registry)

func _rescan_complete():
	RegistryCollection.get_collection().save()
