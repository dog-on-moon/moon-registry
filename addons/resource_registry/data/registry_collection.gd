@tool
extends Resource
class_name RegistryCollection
## A resource containing all defined registries within a project.

signal registry_added(r: Registry)
signal registry_removed(r: Registry)
signal registry_reordered

@export var registries: Array[Registry] = []

func add_registry(r: Registry) -> bool:
	if r not in registries:
		registries.append(r)
		registry_added.emit(r)
		save()
		return true
	return false

func remove_registry(r: Registry) -> bool:
	if r in registries:
		registries.erase(r)
		registry_removed.emit(r)
		save()
		return true
	return false

func sort_registry(r: Registry, offset := 0):
	if r in registries:
		var idx := registries.find(r)
		registries.remove_at(idx)
		var reinsert_pos := idx + offset
		reinsert_pos = clampi(reinsert_pos, 0, registries.size())
		registries.insert(reinsert_pos, r)
		registry_reordered.emit()

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
