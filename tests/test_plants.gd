class_name TestPlants
extends TestCase
## Plantas e estações: calendário, crescimento, tocos, arbusto que começa como muda e planta de fibra.

const _SEED := 12345


func test_seasons_follow_the_gdd_calendar() -> void:
	var clock := GameClock.new()
	expect_equal(clock.season(), GameClock.Season.SPRING, "O ano começa na primavera")
	clock.tick = 15 * Balance.TICKS_PER_DAY
	expect_equal(clock.season(), GameClock.Season.SUMMER, "Dia 16 é verão")
	clock.tick = 45 * Balance.TICKS_PER_DAY
	expect_equal(clock.season(), GameClock.Season.WINTER, "Dia 46 é inverno")
	clock.tick = 60 * Balance.TICKS_PER_DAY
	expect_equal(clock.season(), GameClock.Season.SPRING, "Dia 61 começa um ano novo")


func test_plant_sheets_have_a_row_per_season() -> void:
	for id in ["plants/trees", "plants/berry_bushs", "plants/low_growing_vegetation"]:
		expect_equal(AssetCatalog.frame_grid(id).y, Balance.SEASONS_PER_YEAR, "%s deve ter uma linha por estação" % id)
		var frame := Vector2i(32, 32) if id == "plants/trees" else Vector2i(16, 16)
		expect_equal(AssetCatalog.frame_size(id), frame, "%s deve ter quadros de %d×%d" % [id, frame.x, frame.y])


func test_young_tree_grows_into_adult() -> void:
	var tree := WildTree.new(1, Vector2i.ZERO)
	tree.growth_hours = 0
	expect(not tree.is_adult(), "Começa jovem")
	expect_equal(tree.wood_yield(), Balance.TREE_YOUNG_WOOD_YIELD, "Jovem rende menos madeira")
	for _hour in Balance.TREE_GROWTH_HOURS:
		tree.grow_hour()
	expect(tree.is_adult(), "Depois do tempo de crescimento vira adulta")
	expect_equal(tree.wood_yield(), Balance.TREE_WOOD_YIELD, "Adulta rende a madeira cheia")


func test_cutting_leaves_a_stump_that_decays() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var tree: WildTree = state.trees.values()[0]
	tree.growth_hours = 0
	var task := state.task_board.create(Task.Kind.CUT, tree.cell, tree.id, tree.cut_work_ticks(), 0)
	var wood_before := state.total_count(&"wood")
	TaskEffects.complete(task, state)
	expect(not state.trees.has(tree.id), "A árvore sai do mapa")
	var stump: Stump = state.stumps_by_cell.get(tree.cell)
	expect(stump != null and not stump.from_adult, "Fica o toco de árvore jovem")
	expect_equal(state.total_count(&"wood"), wood_before + Balance.TREE_YOUNG_WOOD_YIELD, "Rende a madeira da jovem")
	for _hour in Balance.STUMP_DECAY_HOURS:
		state.grow_plants_hour()
	expect(not state.stumps_by_cell.has(tree.cell), "O toco some sozinho com o tempo")


func test_seedling_bush_has_no_berries_until_grown() -> void:
	var bush := BerryBush.new(1, Vector2i.ZERO)
	bush.growth_hours = 0
	bush.portions = 0
	for _hour in Balance.BERRY_REGROW_HOURS * 2:
		bush.grow_hour()
	expect_equal(bush.portions, 0, "Muda não dá frutas")
	bush.growth_hours = Balance.BUSH_GROWTH_HOURS
	for _hour in Balance.BERRY_REGROW_HOURS:
		bush.grow_hour()
	expect_equal(bush.portions, 1, "Arbusto crescido refaz as frutas")


func test_fiber_plant_harvest_yields_fiber_and_regrows() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	expect(not state.fiber_plants.is_empty(), "O mapa deve ter plantas de fibra")
	var plant: FiberPlant = state.fiber_plants.values()[0]
	plant.growth_hours = Balance.FIBER_GROWTH_HOURS
	expect_equal(simulation.designate(Designations.Tool.HARVEST, Rect2i(plant.cell, Vector2i.ONE)), 1, "Planta crescida pode ser colhida")
	var task := state.task_board.designation_at(plant.cell)
	var fiber_before := state.total_count(&"fiber")
	TaskEffects.complete(task, state)
	expect_equal(state.total_count(&"fiber"), fiber_before + Balance.FIBER_YIELD, "A colheita rende fibra de verdade")
	expect(not plant.is_mature(), "Depois da colheita a planta volta a ser pequena")
	expect_equal(simulation.designate(Designations.Tool.HARVEST, Rect2i(plant.cell, Vector2i.ONE)), 0, "Planta pequena não pode ser colhida")
	for _hour in Balance.FIBER_GROWTH_HOURS:
		plant.grow_hour()
	expect(plant.is_mature(), "A planta cresce de novo")


func test_map_has_young_and_adult_plants() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var young_trees := simulation.state.trees.values().filter(func(t: WildTree) -> bool: return not t.is_adult()).size()
	var seedlings := simulation.state.bushes.filter(func(b: BerryBush) -> bool: return not b.is_mature()).size()
	expect(young_trees > 0 and young_trees < simulation.state.trees.size(), "Deve haver árvores jovens e adultas (%d jovens)" % young_trees)
	expect(seedlings < simulation.state.bushes.size(), "A maioria dos arbustos começa crescida")


func test_trees_view_sorts_with_colonists() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var state := simulation.state
	var view := TreesView.new()
	view._ready()
	view.sync(state)
	expect_equal(view.sprite_count(), state.trees.size(), "Um sprite por árvore")
	var tree: WildTree = state.trees.values()[0]
	var sprite: Sprite2D = view._sprites[tree.id]
	var tile := Balance.TILE_SIZE
	var bottom := sprite.position.y + sprite.offset.y + 16.0
	expect_equal(bottom, float(tree.cell.y * tile + tile), "A base da árvore fica na base do tile")
	expect_equal(sprite.position.x + sprite.offset.x, tree.cell.x * tile + tile / 2.0, "Centrada no tile")
	var colonist := state.colonists[0]
	colonist.cell = tree.cell + Vector2i.UP
	expect(ColonistsView.cell_center(colonist).y < sprite.position.y, "Colono atrás (ao norte) é desenhado antes: a copa o esconde")
	colonist.cell = tree.cell + Vector2i.RIGHT
	expect(ColonistsView.cell_center(colonist).y > sprite.position.y, "Colono ao lado, na mesma linha, fica na frente")
	state.trees.erase(tree.id)
	view.sync(state)
	expect(not view._sprites.has(tree.id), "Árvore cortada perde o sprite")
	view.clear()
	expect_equal(view.sprite_count(), 0, "Mapa novo limpa os sprites")
	view.free()
