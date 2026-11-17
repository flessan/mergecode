class_name GameBootstrap
extends RefCounted
## Safety net for manager singletons.
##
## Normally project.godot's [autoload] section instantiates ItemDatabase,
## GameStateStore, SaveGame and SoundFx (in that order) and each assigns its
## static `instance` in _enter_tree. If a session ever starts without those
## autoloads (e.g. an editor that had the blank project open before the game
## files were pulled, so its autoload registration is stale), `instance`
## would be Nil and the first access would crash. ensure_managers() creates
## any missing manager as a root child instead — root children persist
## across scene changes, exactly like autoloads. It is a no-op when the
## autoloads loaded normally.

static func ensure_managers(tree: SceneTree) -> void:
	if tree == null:
		return
	var root := tree.root
	if ItemDatabase.instance == null:
		root.add_child(ItemDatabase.new())
	if GameStateStore.instance == null:
		root.add_child(GameStateStore.new())
	if SaveGame.instance == null:
		root.add_child(SaveGame.new())
	if SoundFx.instance == null:
		root.add_child(SoundFx.new())
