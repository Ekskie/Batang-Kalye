extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("[NETCODE & 24-PLAYER SCALING TEST RUNNER]")
	print("==================================================")

	var exe := OS.get_executable_path()
	var args := ["--headless", "res://scenes/main/Main.tscn", "--run-netcode-test"]
	var output: Array = []
	var exit_code := OS.execute(exe, args, output, true)

	for line in output:
		print(line)

	if exit_code == 0:
		print("[NETCODE & 24-PLAYER SCALING TEST PASSED!]")
		quit(0)
	else:
		push_error("[NETCODE & 24-PLAYER SCALING TEST FAILED, exit code: %d]" % exit_code)
		quit(exit_code)
