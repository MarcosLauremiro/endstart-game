class_name TestSaveGame
extends TestCase
## Salvar e carregar (GDD: restaura o estado exatamente): a partida carregada continua igual à
## original tick a tick, inclusive no meio de um ataque; objetos compartilhados continuam um só;
## o arquivo grava, lista e apaga.

const _SEED := 12345
const _TEST_SAVE := "teste_automatico"


func test_loaded_game_continues_exactly_like_the_original() -> void:
	var original := Simulation.new(_SEED, 3)
	SimHelpers.run_until(original, func() -> bool: return false, 20000)
	var copy := Simulation.from_state(SaveGame.restore(SaveGame.snapshot(original.state)))
	expect(SaveGame.snapshot(copy.state) == SaveGame.snapshot(original.state), "Logo depois de carregar, o estado é o mesmo")
	for _i in 20000:
		original.step()
		copy.step()
	expect_equal(copy.clock.tick, original.clock.tick, "Mesmo tick")
	expect(SaveGame.snapshot(copy.state) == SaveGame.snapshot(original.state), "20 mil ticks depois, continua idêntico")
	copy.state.colonists[0].needs.food -= 0.001
	expect(SaveGame.snapshot(copy.state) != SaveGame.snapshot(original.state), "A comparação percebe uma diferença mínima")


func test_save_in_the_middle_of_a_raid() -> void:
	var original := Simulation.new(_SEED, 3)
	var state := original.state
	for colonist in state.colonists:
		colonist.equipment.equip(&"wooden_spear")
	original.toggle_draft_all()
	var raid := ThreatDirector.warn(state, state.clock.tick)
	raid.group = [&"spear", &"archer"] as Array[StringName]
	raid.entry = state.nearest_walkable(state.colonists[0].cell + Vector2i(12, 0))
	ThreatDirector.arrive(state, raid)
	SimHelpers.run_until(original, func() -> bool: return state.colonists.any(func(c: Colonist) -> bool: return c.health.is_hurt()), 6000)
	var copy := Simulation.from_state(SaveGame.restore(SaveGame.snapshot(state)))
	expect_equal(copy.state.threats.raiders.size(), state.threats.raiders.size(), "Os saqueadores vêm junto")
	for _i in 6000:
		original.step()
		copy.step()
	expect(SaveGame.snapshot(copy.state) == SaveGame.snapshot(state), "O combate segue igual depois de carregar")


func test_shared_objects_stay_shared() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var loaded := SaveGame.restore(SaveGame.snapshot(simulation.state))
	var container: StorageContainer = loaded.containers.values()[0]
	expect(loaded.containers_by_cell[container.cell] == container, "O contêiner do índice por célula é o mesmo objeto")
	var tree: WildTree = loaded.trees.values()[0]
	expect(loaded.trees_by_cell[tree.cell] == tree, "A árvore também")
	expect(loaded.clock is GameClock and loaded.colonists[0] is Colonist, "Classes certas")
	expect(loaded.colonists[0].skills.values()[0] is SkillState, "Habilidades restauradas")
	expect(container.def == Defs.container(container.def.id), "Definições voltam como o mesmo recurso")
	var cell := loaded.colonists[0].cell
	expect(not loaded.navigation.find_path(cell, cell + Vector2i(3, 0)).is_empty() or not loaded.navigation.is_walkable(cell + Vector2i(3, 0)),
		"A navegação é refeita")


func test_file_save_list_and_delete() -> void:
	var simulation := Simulation.new(_SEED, 2)
	SimHelpers.run_until(simulation, func() -> bool: return false, 3000)
	expect_equal(SaveGame.save(simulation, _TEST_SAVE), OK, "Grava o arquivo")
	var saves := SaveGame.list_saves().filter(func(s: Dictionary) -> bool: return s["name"] == _TEST_SAVE)
	expect_equal(saves.size(), 1, "Aparece na lista")
	if not saves.is_empty():
		expect_equal(saves[0]["header"]["colonists"], 2, "Cabeçalho com os colonos")
		expect_equal(saves[0]["header"]["day"], simulation.clock.day(), "Cabeçalho com o dia")
	var loaded := SaveGame.load_simulation(_TEST_SAVE)
	expect(loaded != null, "Carrega do arquivo")
	if loaded:
		expect(SaveGame.snapshot(loaded.state) == SaveGame.snapshot(simulation.state), "O arquivo guarda o estado exato")
	expect_equal(SaveGame.delete_save(_TEST_SAVE), OK, "Apaga")
	expect(SaveGame.load_simulation(_TEST_SAVE) == null, "Depois de apagar, não carrega")
	expect_equal(SaveGame.clean_name("  Minha: partida?  "), "Minha_ partida_", "Nome vira nome de arquivo válido")
