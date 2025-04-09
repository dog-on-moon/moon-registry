@tool
extends Resource
class_name Registry
## A Registry is a mass collection of one resource type.

signal name_changed
signal icon_changed
signal rescan_requested
signal rescan_complete

## The name associated with the registry.
@export var name := &"":
	set(x):
		name = x
		resource_name = x
		name_changed.emit()

## An optional icon associated with the registry.
@export var icon: Texture2D:
	set(x):
		icon = x
		icon_changed.emit()

## A mapping between resource to unique resource ID.
@export var resource_to_id: Dictionary[Resource, int] = {}

## A mapping between unique resource ID to resource.
@export var id_to_resource: Dictionary[int, Resource] = {}

@export_group("Directory")
## The target directory where resources are scanned from.
@export_dir() var directory := "":
	set(x):
		directory = x
		rescan_requested.emit()

## Determines if subdirectories should be scanned for resources within the target directory.
@export var scan_subdirectories := true:
	set(x):
		scan_subdirectories = x
		rescan_requested.emit()

@export_group("Type")
## The string type of the Registry (Resource, PackedScene, GDScript, etc)
@export var type := &"":
	set(x):
		type = x
		rescan_requested.emit()
		if not icon:
			icon_changed.emit()

## Determines if the registry should only load the exact type,
## or if subclasses can be used as well.
@export var use_exact_type := true:
	set(x):
		use_exact_type = x
		rescan_requested.emit()

## Returns a resource associated with a unique ID.
func get_resource(id: int) -> Resource:
	return resource_to_id.get(id, null)

## Returns a unique ID associated with a resource.
func get_id(resource: Resource) -> int:
	return id_to_resource.get(resource, -1)

## Returns all resources within a registry.
func get_all_resources() -> Array:
	return resource_to_id.keys()

## Counts the number of resources inside the registry.
func get_resource_count() -> int:
	return resource_to_id.size()

static var _packed_scene_icon: Texture2D
static var _script_icon: Texture2D
static var _object_icon: Texture2D

## Returns an icon associated with this registry.
func get_icon(resource: Resource = null) -> Texture2D:
	if resource:
		if is_instance_of(resource, Texture2D):
			return resource
		for prop in resource.get_property_list():
			var value := resource.get(prop.name)
			if value and value is Texture2D:
				return value
	match type:
		&"PackedScene":
			if not _packed_scene_icon:
				var ei := Engine.get_singleton(&"EditorInterface")
				if ei:
					_packed_scene_icon = ei.get_editor_theme().get_icon("PackedScene", "EditorIcons")
			return _packed_scene_icon
		&"GDScript":
			if not _script_icon:
				var ei := Engine.get_singleton(&"EditorInterface")
				if ei:
					_script_icon = ei.get_editor_theme().get_icon("Script", "EditorIcons")
			return _script_icon
		_:
			if not _object_icon:
				var ei := Engine.get_singleton(&"EditorInterface")
				if ei:
					_object_icon = ei.get_editor_theme().get_icon("Object", "EditorIcons")
			return _object_icon

func get_resource_name(resource: Resource = null) -> String:
	if resource:
		if resource.resource_name:
			return resource.resource_name
		if resource.resource_path:
			return resource.resource_path.get_file()
	return name

#region Rescan

## Rescans the registry, updating resource_to_id and id_to_resource.
func rescan():
	# Load all resources.
	var resources := _load_directory(directory, get_valid_extensions())
	var _resource_map: Dictionary[Resource, Object] = {}
	for r in resources:
		_resource_map[r] = null
	
	# Clear any dead resources.
	#for existing_resource in resource_to_id:
		#if existing_resource not in _resource_map:
			#id_to_resource.erase(resource_to_id[existing_resource])
			#resource_to_id.erase(existing_resource)
	
	# Add new resources.
	var _id := 0
	for resource in resources:
		if resource not in resource_to_id:
			while _id in id_to_resource:
				_id += 1
			resource_to_id[resource] = _id
			id_to_resource[_id] = resource
	
	# We are done.
	rescan_complete.emit()

func _load_directory(path: String, extensions: PackedStringArray) -> Array[Resource]:
	if not path.ends_with("/"):
		path += '/'
	if not DirAccess.dir_exists_absolute(path):
		push_error("Registry: could not find path: %s" % path)
		return []

	# First need to grab all relevant file paths
	var resources: Array[Resource] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and scan_subdirectories:
				resources.append_array(_load_directory(path + file_name, extensions))
			else:
				var valid_ext := extensions.size() > 0
				for ext in extensions:
					if file_name.ends_with(ext):
						valid_ext = true
						break
				if valid_ext:
					var res: Resource = load(path + file_name)
					var valid := false
					if not type:
						valid = true
					else:
						var script: Script = res.get_script()
						if script:
							if script.get_global_name() == type:
								valid = true
							elif not use_exact_type:
								while script:
									script = script.get_base_script()
									if script.get_global_name() == type:
										valid = true
										break
						else:
							if res.get_class() == type:
								valid = true
							elif not use_exact_type and ClassDB.is_parent_class(res.get_class(), type):
								valid = true
					if valid:
						resources.append(res)
					break
			file_name = dir.get_next()
	return resources

## Get all suffixes that this Registry needs to scan.
func get_valid_extensions() -> PackedStringArray:
	var suffixes := PackedStringArray()
	match type:
		&"PackedScene":
			suffixes.append(".tscn")
		&"GDScript":
			suffixes.append(".gd")
	return suffixes

#endregion

## Returns a registry of a given name.
static func get_registry(n: StringName) -> Registry:
	return RegistryCollection.get_collection().get_registry(n)
