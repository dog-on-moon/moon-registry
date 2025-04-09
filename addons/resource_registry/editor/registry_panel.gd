@tool
extends PanelContainer

@export var registry: Registry:
	set(x):
		if registry:
			registry.name_changed.disconnect(_update_name)
			registry.icon_changed.disconnect(_update_icon)
			registry.rescan_complete.disconnect(_reload)
			registry.rescan_requested.disconnect(_rescan_requested)
		registry = x
		if not is_node_ready(): await ready
		if self == get_tree().edited_scene_root: return
		if registry:
			registry.name_changed.connect(_update_name)
			registry.icon_changed.connect(_update_icon)
			registry.rescan_complete.connect(_reload)
			registry.rescan_requested.connect(_rescan_requested)
			registry.rescan()
		else:
			_reload()
		_update_name()
		_update_icon()

@onready var open_button: Button = %OpenButton
@onready var sort_up_button: Button = %SortUpButton
@onready var sort_down_button: Button = %SortDownButton
@onready var filesystem_button: Button = %FilesystemButton
@onready var delete_button: Button = %DeleteButton
@onready var margin_container: MarginContainer = %MarginContainer
@onready var resource_container: HFlowContainer = %ResourceContainer

func _ready() -> void:
	#sort_up_button.icon = 	EditorInterface.get_editor_theme().get_icon("ArrowUp", "EditorIcons")
	#sort_down_button.icon = 	EditorInterface.get_editor_theme().get_icon("ArrowDown", "EditorIcons")
	#filesystem_button.icon = 	EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons")
	#delete_button.icon = 	EditorInterface.get_editor_theme().get_icon("Remove", "EditorIcons")
	sort_up_button.pressed.connect(_request_sort_up)
	sort_down_button.pressed.connect(_request_sort_down)
	filesystem_button.pressed.connect(_open_filesystem)
	delete_button.pressed.connect(_request_delete)
	open_button.pressed.connect(_toggle_visibility)
	
	_update_icon()

func _toggle_visibility():
	margin_container.visible = not margin_container.visible
	EditorInterface.inspect_object(registry)

func _update_name():
	if registry:
		open_button.text = " &\"%s\" (%s)" % [registry.name, registry.get_resource_count()]
	else:
		open_button.text = " No Registry"

func _update_icon():
	if registry and registry.icon:
		open_button.icon = registry.icon
	else:
		open_button.icon = registry.get_icon() if registry else null

func _request_sort_up():
	var c := RegistryCollection.get_collection()
	c.sort_registry(registry, -1)

func _request_sort_down():
	var c := RegistryCollection.get_collection()
	c.sort_registry(registry, 1)

func _open_filesystem():
	EditorInterface.select_file(registry.directory)

func _request_delete():
	var win := ConfirmationDialog.new()
	win.title = "Delete Registry"
	win.dialog_text = "Delete registry '%s'?\n(This is permanent!)" % registry.name
	win.confirmed.connect(func ():
		var c := RegistryCollection.get_collection()
		c.remove_registry(registry)
	)
	EditorInterface.popup_dialog_centered(win)

func _rescan_requested():
	if registry:
		registry.rescan()

const RESOURCE_PANEL = preload("res://addons/resource_registry/editor/resource_panel.tscn")
const ResourcePanel = preload("res://addons/resource_registry/editor/resource_panel.gd")

var panels: Array[ResourcePanel] = []

func _reload():
	_update_name()
	
	for p in panels:
		p.queue_free()
	panels.clear()
	
	if not registry:
		return
	
	for res in registry.get_all_resources():
		var panel: ResourcePanel = RESOURCE_PANEL.instantiate()
		panel.registry = registry
		panel.resource = res
		panels.append(panel)
		resource_container.add_child(panel)
