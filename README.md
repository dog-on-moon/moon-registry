![screen-shot](https://github.com/dog-on-moon/moon-registry/blob/main/readme/banner.png)

# 🌙 moon-registry - see more: [moonSuite](https://dog-game.xyz/tools/)

moon-registry is a Resource plugin for Godot 4.4 that provides an API for accessing folders of Resources.

It features a new main screen editor for accessing all Registries.

![screen-shot](https://github.com/dog-on-moon/moon-registry/blob/main/readme/pic01.png)

## 🗄️ Registry Collection

Each plugin is loaded with one `RegistryCollection` resource, which holds all registries for the project.
It is located at `res://addons/moon-registry/data/registry_collection.tres`.

## 📂 Registry

Registries are created and modified in the new Registry menu of the editor.

Each registry has the following properties:
- Name: The name of the Registry.
- Icon: The icon used for the Registry in the editor view.
- Directory: The directory that the Registry scans resources from.
- Scan Subdirectories: Determines if resources are scanned from subdirectories.
- Type: Filters scanned resources to be of a given type.
- Use Exact Type: If true, the resource MUST be the exact type. Otherwise, subclasses are accepted as well.

Upon adding a new Resource to your filesystem, **the registry must be manually refreshed to load it in.**
This is because I don't trust Godot.

### 🛠️ API Access

You can access any named registry from code by calling `Registry.get_registry(name: StringName)`.
From there, you can call the following functions:

- `Registry.get_all_resources() -> Array`: Returns all resources within a registry.
- `Registry.get_resources_of_type(t: GDScript) -> Array`: Gets precise resources of a type.
- `Registry.get_resource(id: int) -> Resource`: Returns a resource associated with a unique ID.
- `Registry.has_resource(res: Resource) -> bool`: Determines if the registry has this resource.
- `Registry.get_id(res: Resource) -> int`: Returns a unique ID associated with a resource.
- `Registry.has_id(id: int) -> bool`: Determines if the registry has this id.
- `Registry.get_resource_count() -> int`: Counts the number of resources inside the registry.

### 🎨 Custom Render

Your Resources can implement the following functions to change how they're rendered in the Registry panel:

- `func get_registry_icon() -> Texture2D`: Gives the Resource an icon in the Registry view.
- `func get_registry_name() -> String`: Gives the Resource a custom name in the Registry view.

## Installation

This repository contains the plugin for v4.4.
Copy the contents of the `addons` folder into the `addons` folder in your own Godot project.
Be sure to enable the plugin from Project Settings.
