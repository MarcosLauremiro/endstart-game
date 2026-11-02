class_name TestCombat
extends TestCase
## Ameaça e combate (M7): pontos de ameaça do GDD, aviso, saqueadores, convocar, ferimentos,
## socorro, morte permanente e calma depois do ataque. Aceite: um ataque é desafiador mas
## sobrevivível com preparação.

const _SEED := 12345


func test_threat_points_follow_the_gdd() -> void:
	var four: Array[float] = [1.0, 1.0, 1.0, 1.0]
	expect_equal(ThreatDirector.points_for(40000.0, four, 30, 1.0), 300, "Exemplo do GDD: dia 30, 4 colonos, riqueza 40.000")
	expect_equal(ThreatDirector.points_for(0.0, four, 6, 1.0), 72, "Dia 6: M_início 0,72")
	var alone: Array[float] = [Balance.WOUNDED_FIGHTER_SHARE]
	expect_equal(ThreatDirector.points_for(0.0, alone, 1, 1.0), Balance.THREAT_POINTS_MIN, "Nunca menos que 35")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var group := ThreatDirector.compose(300, rng)
	var cost := 0
	for kind in group:
		cost += Raider.cost_of(kind)
	expect(cost <= 300 and cost > 300 - Raider.cost_of(&"archer"), "300 pontos compram um grupo de quase 300 (%d)" % cost)
	expect_equal(ThreatDirector.compose(35, rng).size(), 1, "Sempre vem ao menos um")
	expect(is_equal_approx(ThreatDirector.calm_days(1, 4), 4.5), "Perder 1 de 4: 4,5 dias de calma")


func test_raid_is_warned_with_smoke_before_it_arrives() -> void:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	var messages: Array[String] = []
	state.message_posted.connect(func(text: String) -> void: messages.append(text))
	var threats := state.threats
	state.clock.tick = threats.next_raid_tick - Balance.RAID_WARNING_TICKS
	ThreatDirector.hour_passed(state)
	var raid := threats.raid
	expect(raid != null and raid.phase == Raid.Phase.WARNED, "O ataque é avisado")
	if raid == null:
		return
	expect_equal(raid.arrival_tick - raid.warned_tick, Balance.RAID_WARNING_TICKS, "Com 1,5 dia de antecedência (BALANÇA)")
	expect(messages.size() == 1 and messages[0].contains("Fumaça no horizonte"), "Aviso visual: fumaça no horizonte")
	expect(state.world.contains(raid.smoke_cell), "A fumaça fica no mapa, perto da borda")
	expect(TimePanel.threat_text(state).begins_with("Ataque em 1 dia e 12 h"), "O painel de tempo mostra quanto falta")
	state.clock.tick = raid.arrival_tick
	ThreatDirector.hour_passed(state)
	expect_equal(raid.phase, Raid.Phase.ACTIVE, "Na hora marcada, eles chegam")
	expect_equal(threats.raiders.size(), raid.group.size(), "O grupo comprado com os pontos")
	expect(state.research.is_branch_revealed(&"defense"), "O primeiro ataque revela Defesa e armas")


func test_undrafted_colonists_flee_and_drafted_ones_fight() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var fighter := state.colonists[0]
	var bystander := state.colonists[1]
	fighter.traits.clear()
	bystander.traits.clear()
	fighter.equipment.equip(&"wooden_spear")
	simulation.set_drafted(fighter.id, true)
	var group: Array[StringName] = [&"spear"]
	var raid := _raid_near(simulation, group, 7)
	var raider: Raider = state.threats.raiders.values()[0]
	var fled := SimHelpers.run_until(simulation, func() -> bool:
		return bystander.action != null and bystander.action.kind == Action.Kind.FLEE, 300)
	expect(fled, "Quem não está convocado foge do saqueador")
	var start_xp: float = fighter.skill(Skills.Id.MELEE).xp
	var hurt := SimHelpers.run_until(simulation, func() -> bool: return raider.health.is_hurt() or not state.threats.raiders.has(raider.id), 1800)
	expect(hurt, "O convocado vai até ele e luta")
	expect(fighter.skill(Skills.Id.MELEE).xp > start_xp, "Lutar treina Corpo a corpo")
	expect(raid.phase == Raid.Phase.ACTIVE or raid.phase == Raid.Phase.OVER, "O ataque está em andamento")


func test_downed_colonist_bleeds_out_without_help() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var victim := state.colonists[0]
	var other := state.colonists[1]
	other.work_priorities[WorkType.Id.EMERGENCY] = 0
	victim.health.add_injury(Injury.Kind.STAB, 62.0)
	var messages: Array[String] = []
	state.message_posted.connect(func(text: String) -> void: messages.append(text))
	SimHelpers.run_until(simulation, func() -> bool: return victim.action != null and victim.action.kind == Action.Kind.DOWNED, 60)
	expect(victim.is_lying(), "Com 62 de dano, cai")
	var died := SimHelpers.run_until(simulation, func() -> bool: return not state.colonists.has(victim), 12 * Balance.TICKS_PER_HOUR)
	expect(died, "Sem socorro, morre de perda de sangue em poucas horas")
	expect(state.colonist_by_id(victim.id) == null, "Morte permanente: sai da partida")
	expect(state.stacks.values().any(func(stack: ItemStack) -> bool: return stack.item == &"tunic"), "O que vestia fica no chão")
	expect(other.mood.memories.has(StringName("died_%d" % victim.id)), "Quem ficou sente a morte")
	expect(messages.any(func(text: String) -> bool: return text.contains("morreu por perda de sangue")), "O jogador é avisado")
	expect(is_equal_approx(state.threats.adaptation, 1.0 - Balance.ADAPTATION_DEATH_LOSS), "M_adaptação cai 0,15")


func test_downed_colonist_is_rescued_tended_and_recovers() -> void:
	var simulation := Simulation.new(_SEED, 2)
	var state := simulation.state
	var patient := state.colonists[0]
	var medic := state.colonists[1]
	medic.traits.clear()
	var origin := SimHelpers.clear_area(simulation, Vector2i(1, 2))
	var bed := SimHelpers.build_now(simulation, &"bed_rustic", origin)
	patient.health.add_injury(Injury.Kind.CUT, 35.0)
	patient.health.add_injury(Injury.Kind.STAB, 27.0)
	var in_bed := SimHelpers.run_until(simulation, func() -> bool: return patient.is_in_bed(), 2 * Balance.TICKS_PER_HOUR)
	expect(in_bed, "Um colono com Emergência leva o caído para a cama")
	expect_equal(patient.cell, bed.origin, "Ele fica deitado na cama")
	var tended := SimHelpers.run_until(simulation, func() -> bool: return not patient.health.is_bleeding(), 2 * Balance.TICKS_PER_HOUR)
	expect(tended, "E trata os ferimentos: o sangramento para")
	var stood := SimHelpers.run_until(simulation, func() -> bool: return not patient.health.is_downed(), Balance.TICKS_PER_DAY)
	expect(stood, "Tratado e na cama, ele se recupera e levanta")
	expect(state.colonists.has(patient), "E sobrevive")


func test_walking_wounded_tends_own_bleeding() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	colonist.health.add_injury(Injury.Kind.CUT, 12.0)
	var tended := SimHelpers.run_until(simulation, func() -> bool: return not colonist.health.is_bleeding(), Balance.TICKS_PER_HOUR)
	expect(tended, "Ferido de pé estanca o próprio sangramento (necessidade crítica)")


func test_coward_flees_from_further_away() -> void:
	var simulation := Simulation.new(_SEED, 1)
	var colonist := simulation.state.colonists[0]
	colonist.traits = [Traits.COWARD]
	var group: Array[StringName] = [&"spear"]
	_raid_near(simulation, group, Balance.COWARD_FLEE_RAIDER_RADIUS - 1)
	var fled := SimHelpers.run_until(simulation, func() -> bool:
		return colonist.action != null and colonist.action.kind == Action.Kind.FLEE, 120)
	expect(fled, "O Covarde foge de um saqueador a %d tiles" % (Balance.COWARD_FLEE_RAIDER_RADIUS - 1))


## Aceite do M7: 3 colonos armados com lanças e convocados enfrentam 2 saqueadores (100 pontos,
## um ataque do dia 10 com 4 colonos). Ninguém morre, os saqueadores são derrotados ou fogem,
## e alguém sai ferido. Sem preparação (sem armas, sem convocar), os saqueadores levam o que querem.
func test_a_raid_is_challenging_but_survivable_with_preparation() -> void:
	var prepared := _raid_scenario(true)
	expect_equal(prepared["dead"], 0, "Preparados, ninguém morre")
	expect(prepared["over"], "O ataque termina")
	expect(prepared["killed"] + prepared["fled"] >= 1, "Os saqueadores são derrotados ou fogem feridos (%d mortos, %d fugiram)" % [prepared["killed"], prepared["fled"]])
	expect(prepared["worst_damage"] > 0.0, "É desafiador: alguém sai ferido (pior dano %d)" % roundi(prepared["worst_damage"]))
	var unprepared := _raid_scenario(false)
	expect(unprepared["looted"] >= 1 or unprepared["downed"] >= 1, "Sem preparação, perdem itens ou alguém cai (saques %d, caídos %d)" % [unprepared["looted"], unprepared["downed"]])
	expect(unprepared["looted"] > prepared["looted"], "Preparar faz diferença (saques %d contra %d)" % [unprepared["looted"], prepared["looted"]])


func _raid_scenario(prepared: bool) -> Dictionary:
	var simulation := Simulation.new(_SEED, 3)
	var state := simulation.state
	for colonist in state.colonists:
		colonist.traits.clear()
		if prepared:
			colonist.equipment.equip(&"wooden_spear")
	if prepared:
		simulation.toggle_draft_all()
	var group: Array[StringName] = [&"spear", &"spear"]
	var raid := _raid_near(simulation, group, 16)
	var result := {"dead": 0, "downed": 0, "worst_damage": 0.0}
	var downed := {}
	var over := SimHelpers.run_until(simulation, func() -> bool:
		for colonist in state.colonists:
			result["worst_damage"] = maxf(result["worst_damage"], colonist.health.damage())
			if colonist.health.is_downed():
				downed[colonist.id] = true
		return raid.phase == Raid.Phase.OVER, Balance.TICKS_PER_DAY)
	result["over"] = over
	result["dead"] = 3 - state.colonists.size()
	result["downed"] = downed.size()
	result["killed"] = raid.raiders_killed
	result["fled"] = raid.raiders_fled
	result["looted"] = raid.raiders_looted
	return result


## Um ataque que chega agora, a tantos tiles do primeiro colono.
func _raid_near(simulation: Simulation, group: Array[StringName], distance: int) -> Raid:
	var state := simulation.state
	var raid := ThreatDirector.warn(state, state.clock.tick)
	raid.group = group
	raid.entry = state.nearest_walkable(state.colonists[0].cell + Vector2i(distance, 0))
	ThreatDirector.arrive(state, raid)
	return raid
