@tool
extends Resource
class_name Registry
## A Registry is a mass collection of one resource type.

signal name_changed
signal icon_changed
signal rescan_requested
signal rescan_complete(changed: bool)

## The name associated with the registry.
@export var name := &"New Registry":
	set(x):
		name = x
		resource_name = x
		name_changed.emit()

## An optional icon associated with the registry.
@export var icon: Texture2D = null:
	set(x):
		icon = x
		icon_changed.emit()

## A mapping between resource to unique resource ID.
var resource_to_id: Dictionary[Resource, int] = {}

## A mapping between unique resource ID to resource.
@export_storage var id_to_resource: Dictionary[int, Resource] = {}

@export_group("Directory")
## The target directory where resources are scanned from.
@export_dir() var directory := "":
	set(x):
		directory = x
		rescan_requested.emit()

## Determines if subdirectories should be scanned for resources within the target directory.
@export var scan_subdirectories := false:
	set(x):
		scan_subdirectories = x
		rescan_requested.emit()

@export_group("Type")
## The string type of the Registry (Resource, PackedScene, GDScript, etc)
@export var type := &"Resource":
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

func _load():
	for id in id_to_resource:
		resource_to_id[id_to_resource[id]] = id

## Returns a resource associated with a unique ID.
func get_resource(id: int) -> Resource:
	return id_to_resource.get(id, null)

## Returns a unique ID associated with a resource.
func get_id(resource: Resource) -> int:
	return resource_to_id.get(resource, -1)

var _type_registry: Dictionary[GDScript, Array] = {}

## Gets precise registry definitions of a type.
func get_resources_of_type(t: GDScript, exact_type := false) -> Array:
	if t not in _type_registry:
		var types: Array = []
		for res: Resource in get_all_resources():
			if exact_type:
				if res.script == t:
					types.append(res)
			else:
				if is_instance_of(res, t):
					types.append(res)
		_type_registry[t] = types
	return _type_registry[t]

## Determines if the registry has this resource.
func has_resource(res: Resource) -> bool:
	return res in resource_to_id

## Determines if the registry has this id.
func has_id(id: int) -> bool:
	return id in id_to_resource

var _all_resources_cache: Array = []

## Returns all resources within a registry.
func get_all_resources() -> Array:
	if Engine.is_editor_hint():
		return resource_to_id.keys()
	if not _all_resources_cache:
		_all_resources_cache = resource_to_id.keys()
	return _all_resources_cache

## Counts the number of resources inside the registry.
func get_resource_count() -> int:
	return resource_to_id.size()

## Returns an icon associated with this registry.
func get_icon(resource: Resource = null) -> Texture2D:
	if resource:
		if resource.has_method(&"get_registry_icon"):
			return resource.call(&"get_registry_icon")
		if is_instance_of(resource, Texture2D):
			return resource
		for prop in resource.get_property_list():
			var value := resource.get(prop.name)
			if value and value is Texture2D:
				return value
	var default := get_cache_icon(type)
	if not default:
		return get_cache_icon(&"Object")
	return null

func get_resource_name(resource: Resource = null) -> String:
	if resource:
		if resource.has_method(&"get_registry_name"):
			return resource.call(&"get_registry_name")
		if resource.resource_name:
			return resource.resource_name
		if resource.resource_path:
			return resource.resource_path.get_file()
	return name

static var _icon_cache: Dictionary[StringName, Texture2D] = {}
static var _cache_theme: Theme = null

static func get_cache_icon(sn: StringName) -> Texture2D:
	if sn not in _icon_cache:
		var ei := Engine.get_singleton(&"EditorInterface")
		if ei:
			if not _cache_theme:
				_cache_theme = ei.get_editor_theme()
			if _cache_theme.has_icon(sn, &"EditorIcons"):
				_icon_cache[sn] = _cache_theme.get_icon(sn, &"EditorIcons")
			else:
				_icon_cache[sn] = null
		else:
			return null
	return _icon_cache[sn]

#region Rescan

## Rescans the registry, updating resource_to_id and id_to_resource.
func rescan() -> bool:
	# Load all resources.
	var resources := _load_directory(directory, get_valid_extensions())
	var changed := false
	var _resource_map: Dictionary[Resource, Object] = {}
	for r in resources:
		_resource_map[r] = null
	
	# Clear any dead resources.
	for existing_resource in resource_to_id.keys():
		if existing_resource not in _resource_map:
			id_to_resource.erase(resource_to_id[existing_resource])
			resource_to_id.erase(existing_resource)
			changed = true
	
	# Add new resources.
	var _id := 0
	for resource in resources:
		if resource not in resource_to_id:
			while _id in id_to_resource:
				_id += 1
			resource_to_id[resource] = _id
			id_to_resource[_id] = resource
			changed = true
	
	# We are done.
	rescan_complete.emit(changed)
	return changed

func _load_directory(path: String, extensions: PackedStringArray) -> Array[Resource]:
	var resources: Array[Resource] = []
	if not path:
		return resources
	if not path.ends_with("/"):
		path += '/'
	if not DirAccess.dir_exists_absolute(path):
		push_error("Registry: could not find path: %s" % path)
		return []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var c := RegistryCollection.get_collection()
		while file_name != "":
			if dir.current_is_dir():
				if not (path + file_name).begins_with("res://.") and scan_subdirectories:
					resources.append_array(_load_directory(path + file_name, extensions))
			else:
				var invalid_ext := false
				if file_name.ends_with(".uid"):
					invalid_ext = true
				elif file_name.ends_with(".import"):
					invalid_ext = true
				elif file_name.ends_with(".cfg"):
					invalid_ext = true
				elif file_name.ends_with(".txt"):
					invalid_ext = true
				elif file_name.ends_with("LICENSE"):
					invalid_ext = true
				elif file_name.ends_with("godot"):
					invalid_ext = true
				elif file_name.begins_with("."):
					invalid_ext = true
				if not invalid_ext:
					var valid_ext := extensions.size() == 0
					for ext in extensions:
						if file_name.ends_with(ext):
							valid_ext = true
							break
					if valid_ext and (path + file_name):
						var res: Resource = load(path + file_name)
						var valid := false
						if res == c or not res:
							pass
						elif not type:
							valid = true
						else:
							var script: Script = res.get_script()
							if script:
								if script.get_global_name() == type:
									valid = true
								elif not use_exact_type:
									if res.get_class() == type:
										valid = true
									elif ClassDB.is_parent_class(res.get_class(), type):
										valid = true
									else:
										while script:
											script = script.get_base_script()
											if not script:
												break
											elif script.get_global_name() == type:
												valid = true
												break
							else:
								if res.get_class() == type:
									valid = true
								elif not use_exact_type and ClassDB.is_parent_class(res.get_class(), type):
									valid = true
						if valid:
							resources.append(res)
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
		_:
			suffixes.append(".tres")
			suffixes.append(".res")
	return suffixes

#endregion

## Returns a registry of a given name.
static func get_registry(n: StringName) -> Registry:
	return RegistryCollection.get_collection().get_registry(n)
