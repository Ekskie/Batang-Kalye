extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("[DYNAMIC MULTI-TAYA BALANCING TEST RUNNER]")
	print("==================================================")

	var exe := OS.get_executable_path()
	var args := ["--headless", "res://scenes/main/Main.tscn", "--run-multi-taya-test"]
	var output: Array = []
	var exit_code := OS.execute(exe, args, output, true)

	for line in output:
		print(line)

	if exit_code == 0:
		print("[DYNAMIC MULTI-TAYA BALANCING TEST PASSED!]")
		quit(0)
	else:
		push_error("[DYNAMIC MULTI-TAYA BALANCING TEST FAILED, exit code: %d]" % exit_code)
		quit(exit_code)
