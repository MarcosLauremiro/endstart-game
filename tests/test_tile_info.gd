class_name TestTileInfo
extends TestCase
## Painel do tile: terreno com os dados do GDD, objetos e conteúdo, tarefa e o motivo de cada colono.
## Consultar pela interface nunca pode alterar a simulação.

const _SEED := 12345


func test_terrain_line_uses_gdd_values() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var rock := _first_cell_of(simulation, Terrain.Kind.ROCK)
	var lines := TileInfo.describe(simulation, rock)
	expect(lines[0].begins_with("Rocha · movimento intransponível"), "Rocha: %s" % lines[0])
	expect(lines[0].ends_with("construir: depois de escavar"), "Regra de construção do GDD: %s" % lines[0])
	var shallow := _first_cell_of(simulation, Terrain.Kind.SHALLOW_WATER)
	expect(TileInfo.describe(simulation, shallow)[0].contains("movimento 40%"), "Água rasa anda a 40%")


func test_container_lists_real_contents() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var crate: StorageContainer = simulation.state.containers.values()[0]
	var text := "\n".join(TileInfo.describe(simulation, crate.cell))
	expect(text.contains("Caixote #%d" % crate.id), "Deve nomear o caixote")
	for item in crate.contents():
		expect(text.contains("%s: %d" % [Defs.item(item).display_name, crate.contents()[item]]), "Deve listar %s" % item)


func test_task_shows_why_each_colonist_would_or_would_not() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var first := simulation.state.colonists[0]
	var second := simulation.state.colonists[1]
	simulation.set_work_priority(second.id, WorkType.Id.CUT, 0)
	var tree: WildTree = _nearest_tree(simulation, first.cell)
	simulation.designate(Designations.Tool.CUT, Rect2i(tree.cell, Vector2i.ONE))
	var text := "\n".join(TileInfo.describe(simulation, tree.cell))
	expect(text.contains("Tarefa: Cortar árvore"), "Deve mostrar a tarefa")
	expect(text.contains("%s: pode fazer" % first.display_name), "O primeiro pode fazer:\n%s" % text)
	expect(text.contains("%s: prioridade de Cortar plantas desligada" % second.display_name), "O segundo explica o motivo:\n%s" % text)


func test_explaining_does_not_change_the_simulation() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	var inner := _inner_rock(simulation)
	simulation.designate(Designations.Tool.MINE, Rect2i(inner, Vector2i.ONE))
	var task := simulation.state.task_board.designation_at(inner)
	expect_equal(simulation.explain_task(colonist, task), "sem caminho", "A explicação dá o motivo real")
	expect(not task.is_blocked(simulation.clock.tick), "Consultar não pode bloquear a tarefa")
	expect_equal(simulation.state.reservations.count_for(colonist.id), 0, "Consultar não reserva nada")


func _first_cell_of(simulation: Simulation, kind: int) -> Vector2i:
	for y in simulation.world.size.y:
		for x in simulation.world.size.x:
			if simulation.world.get_terrain(Vector2i(x, y)) == kind:
				return Vector2i(x, y)
	push_error("Terreno ausente: %d" % kind)
	return Vector2i.ZERO


func _nearest_tree(simulation: Simulation, from: Vector2i) -> WildTree:
	var best: WildTree
	for tree in simulation.state.trees.values():
		if not simulation.state.navigation.can_reach(from, tree.cell):
			continue
		if best == null or tree.cell.distance_squared_to(from) < best.cell.distance_squared_to(from):
			best = tree
	return best


func _inner_rock(simulation: Simulation) -> Vector2i:
	for y in range(1, simulation.world.size.y - 1):
		for x in range(1, simulation.world.size.x - 1):
			var cell := Vector2i(x, y)
			var enclosed := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if simulation.world.get_terrain(cell + Vector2i(dx, dy)) != Terrain.Kind.ROCK:
						enclosed = false
			if enclosed:
				return cell
	return Vector2i(-1, -1)
