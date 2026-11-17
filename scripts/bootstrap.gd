class_name GameBootstrap
extends RefCounted
## Safety net for manager singletons.
##
## Normally project.godot's [autoload] section instantiates ItemDatabase,
## GameStateStore, SaveGame and SoundFx (in that order) and each assigns its
## static `instance` in _enter_tree. If a session ever starts without those
## autoloads (e.g. an editor that had the blank project open before the game
## files were pulled, so its autoload registration is stale), `instance`
## would be Nil and the first access would crash.
##
## ensure_managers() instead creates any missing manager as a child of the
## calling scene root. Adding to the tree root directly fails while the
## entry scene is being set up ("Parent node is busy"), but adding to the
## scene node itself during its _ready is fine, and _enter_tree/_ready of
## the new child run immediately, in dependency order. When the scene
## changes, those children are freed and the next scene's ensure call
## recreates them (guarded by is_instance_valid); run state is restored
## from the save file by the game scene, so the fallback stays consistent.
## When autoloads load normally this is a no-op.

static func ensure_managers(host: Node) -> void:
	if host == null:
		return
	if not is_instance_valid(ItemDatabase.instance):
		host.add_child(ItemDatabase.new())
	if not is_instance_valid(GameStateStore.instance):
		host.add_child(GameStateStore.new())
	if not is_instance_valid(SaveGame.instance):
		host.add_child(SaveGame.new())
	if not is_instance_valid(SoundFx.instance):
		host.add_child(SoundFx.new())
