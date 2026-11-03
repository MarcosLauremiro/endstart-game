extends SceneTree
## Executor dos testes headless. Uso:
##   godot --headless --path . -s res://tests/test_runner.gd
## Termina com código 1 se algum caso falhar.

const _SUITES := [
	"res://tests/test_game_clock.gd",
	"res://tests/test_world_generator.gd",
	"res://tests/test_simulation.gd",
	"res://tests/test_asset_catalog.gd",
	"res://tests/test_navigation.gd",
	"res://tests/test_needs_and_reservations.gd",
	"res://tests/test_colonist_ai.gd",
	"res://tests/test_tasks.gd",
	"res://tests/test_plants.gd",
	"res://tests/test_tile_info.gd",
	"res://tests/test_construction.gd",
	"res://tests/test_production.gd",
	"res://tests/test_food_sources.gd",
	"res://tests/test_context_actions.gd",
	"res://tests/test_ui_theme.gd",
	"res://tests/test_colonists.gd",
	"res://tests/test_daylight.gd",
	"res://tests/test_storage.gd",
	"res://tests/test_research.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_multi_select.gd",
	"res://tests/test_save_game.gd",
	"res://tests/test_alerts.gd",
	"res://tests/test_full_game.gd",
	"res://tests/test_colonist_looks.gd",
	"res://tests/test_terrain_tiles.gd",
	"res://tests/test_structures_view.gd",
]


func _init() -> void:
	var cases := 0
	var failed_cases := 0
	# Opcional: -- --only=combat roda só as suítes cujo caminho contém o texto.
	var only := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	for path in _SUITES:
		if not only.is_empty() and not path.contains(only):
			continue
		var suite_script: GDScript = load(path)
		for method in suite_script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var suite: TestCase = suite_script.new()
			suite.call(method_name)
			cases += 1
			if suite.failures.is_empty():
				print("PASS  %s::%s" % [path.get_file(), method_name])
			else:
				failed_cases += 1
				print("FAIL  %s::%s" % [path.get_file(), method_name])
				for failure in suite.failures:
					print("      - %s" % failure)
	print("\n%d casos, %d falhas" % [cases, failed_cases])
	quit(1 if failed_cases > 0 else 0)
