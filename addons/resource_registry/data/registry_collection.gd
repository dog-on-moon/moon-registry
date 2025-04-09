@tool
extends Resource
class_name RegistryCollection
## A resource containing all defined registries within a project.

@export var registries: Array[Registry] = []

func add_registry(r: Registry) -> bool:
	if r not in registries:
		registries.append(r)
		save()
		emit_changed()
		return true
	return false

func remove_registry(r: Registry) -> bool:
	if r in registries:
		registries.erase(r)
		save()
		emit_changed()
		return true
	return false

## A cache for all named registries.
var _name_to_registry: Dictionary[StringName, Registry] = {}

func get_registry(n: StringName) -> Registry:
	if Engine.is_editor_hint():
		for r in registries:
			if r.name == n:
				return r
	elif not _name_to_registry:
		for r in registries:
			_name_to_registry[r.name] = r
	return _name_to_registry.get(n, null)

#region Registry Load

const SAVE_PATH := "res://addons/resource_registry/data/registry_collection.tres"

static var _self: RegistryCollection

static func get_collection() -> RegistryCollection:
	if not _self:
		if not FileAccess.file_exists(SAVE_PATH):
			_self = RegistryCollection.new()
			ResourceSaver.save(_self, SAVE_PATH)
		else:
			_self = load(SAVE_PATH)
	return _self

func save():
	ResourceSaver.save(self)

#endregion
