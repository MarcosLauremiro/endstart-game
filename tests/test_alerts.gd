class_name TestAlerts
extends TestCase
## Alertas (GDD: até 5 por urgência, com o motivo e um atalho): caído antes de faminto, ataque
## em cima de tudo, aviso de ataque com os armados, pouca comida, sem cama, item sem lugar e o
## painel com "+N alertas".

const _SEED := 12345


func test_colonist_alerts_follow_urgency() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var first := state.colonists[0]
	var second := state.colonists[1]
	first.needs.food = 5.0
	second.health.add_injury(Injury.Kind.CUT, Balance.DOWNED_DAMAGE + 1.0)
	var alerts := Alerts.compute(state)
	var keys := alerts.map(func(a: Dictionary) -> String: return a["key"])
	expect(keys.find("downed") >= 0 and keys.find("downed") < keys.find("starving"), "Caído vem antes de faminto (havia %s)" % [keys])
	var starving: Dictionary = alerts[keys.find("starving")]
	expect_equal(starving["text"], "Faminto: %s" % first.display_name, "Nomeia quem está com fome")
	expect_equal(starving["colonist_id"], first.id, "O clique seleciona o colono")
	expect(starving["danger"], "Fome crítica é perigo")
	state.colonists[2].needs.food = 5.0
	var both: Dictionary = Alerts.compute(state).filter(func(a: Dictionary) -> bool: return a["key"] == "starving")[0]
	expect_equal(both["text"], "Famintos: %s, %s" % [first.display_name, state.colonists[2].display_name], "Vários colonos numa linha só")


func test_raid_alerts() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	state.colonists[0].equipment.equip(&"wooden_spear")
	var raid := ThreatDirector.warn(state, state.clock.tick)
	var warned: Array = Alerts.compute(state).filter(func(a: Dictionary) -> bool: return a["key"] == "raid_warned")
	expect_equal(warned.size(), 1, "Aviso de ataque vira alerta")
	if not warned.is_empty():
		expect(warned[0]["tooltip"].contains("1 de 3 colonos armados"), "Diz quantos estão armados")
		expect_equal(warned[0]["cell"], raid.smoke_cell, "O clique leva à fumaça")
	raid.group = [&"spear"] as Array[StringName]
	raid.entry = state.nearest_walkable(state.colonists[0].cell + Vector2i(15, 0))
	ThreatDirector.arrive(state, raid)
	var alerts := Alerts.compute(state)
	expect_equal(alerts[0]["key"], "raid", "Ataque em andamento é o mais urgente")
	expect_equal(alerts[0]["text"], "Ataque! 1 saqueador(es)", "Conta os saqueadores")


func test_food_beds_and_storage_alerts() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var keys := Alerts.compute(state).map(func(a: Dictionary) -> String: return a["key"])
	expect(keys.has("beds"), "Começo sem camas: alerta de cama")
	expect(not keys.has("low_food"), "Começa com comida guardada")
	for container in state.containers.values():
		for definition in Defs.items():
			if definition.is_edible():
				container.take_all(definition.id)
		simulation.set_container_filter(container.id, ItemDef.Category.WEAPON, false)
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 1))
	state.drop_items(origin, &"bow", 1)
	var alerts := Alerts.compute(state)
	keys = alerts.map(func(a: Dictionary) -> String: return a["key"])
	expect(keys.has("low_food"), "Sem comida guardada: alerta")
	var homeless: Array = alerts.filter(func(a: Dictionary) -> bool: return a["key"] == "no_storage")
	expect(not homeless.is_empty() and homeless[0]["text"] == "Sem lugar: arco", "Arco sem contêiner que aceite")
	if not homeless.is_empty():
		expect_equal(homeless[0]["cell"], origin, "O clique leva à pilha")


func test_panel_shows_five_and_counts_the_rest() -> void:
	var panel := AlertsPanel.new()
	panel._ready()
	var alerts: Array[Dictionary] = []
	for i in 7:
		alerts.append(Alerts._alert("a%d" % i, "Alerta %d" % i, "motivo", i == 0, 10 - i, Vector2i(i, i)))
	panel.show_alerts(alerts)
	expect_equal(panel.shown_count(), AlertsPanel.MAX_VISIBLE, "Mostra até 5")
	expect(panel._more.visible and panel._more.text == "+2 alertas", "O resto vira +2 alertas")
	var chosen := []
	panel.alert_chosen.connect(func(cell: Vector2i, id: int) -> void: chosen.append(cell))
	(panel.get_child(0) as Button).pressed.emit()
	expect_equal(chosen, [Vector2i(0, 0)], "Clicar leva até o problema")
	panel.show_alerts([] as Array[Dictionary])
	expect(panel.shown_count() == 0 and not panel._more.visible, "Sem alertas, painel vazio")
	panel.free()


func test_colonist_bar_shows_everyone_and_why() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var bar := ColonistBar.new()
	bar._ready()
	var first := state.colonists[0]
	bar.refresh(state, [first.id] as Array[int])
	expect_equal(bar.get_child_count(), 3, "Um botão por colono")
	var button: Button = bar._buttons[first.id]
	expect(button.button_pressed and button.text == first.display_name, "O selecionado aparece marcado")
	SimHelpers.run_until(simulation, func() -> bool: return first.action != null, 600)
	expect(ColonistBar.tooltip(first).contains("Por quê: %s" % first.action.reason), "A dica diz por quê")
	var chosen := []
	bar.colonist_focused.connect(func(id: int) -> void: chosen.append(id))
	button.pressed.emit()
	expect_equal(chosen, [first.id], "Clicar seleciona o colono")
	bar.free()
