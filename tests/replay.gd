extends SceneTree
func _initialize() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Supply journal path after --")
		quit(2)
		return
	var result = GameProbe.replay_journal(args[0])
	print(JSON.stringify(result))
	quit(0 if result.ok else 1)
