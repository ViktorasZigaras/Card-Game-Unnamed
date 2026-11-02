extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var reports: Array = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/expeditions/results.json"))
	var failed = false
	var total = 0
	for report in reports:
		var folder = "res://experiments/expeditions/seed_%d_%s_%s" % [report.seed,"linked" if report.linked else "manual","expeditions" if report.expeditions_enabled else "control"]
		report.replay = GameProbe.replay_journal(folder+"/decisions.jsonl")
		failed = failed or not report.replay.ok
		total += int(report.replay.get("checked",0))
		print(JSON.stringify({"seed":report.seed,"linked":report.linked,"expeditions":report.expeditions_enabled,"replay":report.replay}))
	FileAccess.open("res://experiments/expeditions/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"\t"))
	print("VERIFIED ",total)
	quit(1 if failed else 0)
