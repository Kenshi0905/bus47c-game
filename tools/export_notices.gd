extends SceneTree
## Build-time only. Export notices from the pinned engine itself.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Expected the output notices directory")
		quit(1)
		return
	var destination := args[0]
	DirAccess.make_dir_recursive_absolute(destination)
	var license_file := FileAccess.open(destination.path_join("GODOT_LICENSE.txt"),FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	license_file.close()
	var notices := FileAccess.open(destination.path_join("GODOT_THIRD_PARTY.txt"),FileAccess.WRITE)
	notices.store_string("Godot "+Engine.get_version_info().string+"\n\n")
	for component in Engine.get_copyright_info():
		notices.store_string(str(component.name)+"\n")
		for part in component.parts:
			notices.store_string("Files: "+", ".join(part.files)+"\n")
			notices.store_string("Copyright: "+"\n".join(part.copyright)+"\n")
			notices.store_string("License: "+str(part.license)+"\n\n")
	for title in Engine.get_license_info():
		notices.store_string(str(title)+"\n"+str(Engine.get_license_info()[title])+"\n\n")
	notices.close()
	print("Generated notices from the pinned Godot engine")
	quit()
