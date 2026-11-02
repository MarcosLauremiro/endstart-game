class_name Medical
extends RefCounted
## Socorro, tratamento e morte (GDD: ferimentos e morte permanente). Quem cai ferido gera tarefas
## de Emergência no quadro: Socorrer (levar a uma cama livre) e Tratar (estancar o sangramento).
## Quem está de pé trata os próprios ferimentos (necessidade crítica, na IA). A morte é permanente.


## Mantém as tarefas de Emergência em dia: cria as que faltam, segue o paciente e tira as que
## perderam o sentido (curou, morreu, já está na cama).
static func sync(state: WorldState) -> void:
	var board := state.task_board
	var tick := state.clock.tick
	for patient in state.colonists:
		var rescue := board.rescue_for(patient.id)
		var tend := board.tend_for(patient.id)
		if rescue and not TaskEffects.is_still_valid(rescue, state):
			board.remove(rescue, Task.Status.CANCELLED)
			rescue = null
		if tend and not TaskEffects.is_still_valid(tend, state):
			board.remove(tend, Task.Status.CANCELLED)
			tend = null
		if not patient.health.is_downed():
			continue
		if rescue == null and not patient.is_in_bed() and free_bed(state, patient.cell) != null:
			rescue = board.create(Task.Kind.RESCUE, patient.cell, patient.id, 0.0, tick)
			rescue.title = "Socorrer %s" % patient.display_name
			rescue.urgency = Balance.RESCUE_URGENCY
		if tend == null and patient.health.needs_tending() and patient.carried_by == 0:
			tend = board.create(Task.Kind.TEND, patient.cell, patient.id, Balance.TEND_TICKS, tick)
			tend.title = "Tratar %s" % patient.display_name
			tend.urgency = Balance.TEND_URGENCY
		for task in [rescue, tend]:
			if task:
				task.cell = patient.cell


## Cama sem dono mais perto (em linha reta), ou null.
static func free_bed(state: WorldState, from: Vector2i) -> Structure:
	var best: Structure
	for bed in state.beds():
		if state.reservations.owner_of(Reservations.bed_key(bed.id)) != 0:
			continue
		if best == null or bed.origin.distance_squared_to(from) < best.origin.distance_squared_to(from):
			best = bed
	return best


## Morte permanente: o colono sai da partida, o que levava fica no chão e a comunidade sente.
## Quem chama já interrompeu a ação dele (o ActionRunner larga o que estava nas mãos).
static func bury(state: WorldState, colonist: Colonist) -> void:
	var cause := "por perda de sangue" if colonist.health.blood_loss >= Balance.MAX_BLOOD_LOSS else "dos ferimentos"
	for slot in Equipment.SLOT_NAMES:
		var item: StringName = colonist.equipment.in_slot(slot)
		if item != &"":
			colonist.equipment.clear(slot)
			state.drop_items(colonist.cell, item, 1)
	state.colonists.erase(colonist)
	state.release_all_for(colonist.id)
	for task in [state.task_board.rescue_for(colonist.id), state.task_board.tend_for(colonist.id)]:
		if task:
			state.task_board.remove(task, Task.Status.CANCELLED)
	var tick := state.clock.tick
	for other in state.colonists:
		if other.carried_by == colonist.id:
			other.carried_by = 0
		other.mood.remember(StringName("died_%d" % colonist.id), "%s morreu" % colonist.display_name,
			Balance.COLONIST_DIED_MOOD, Balance.COLONIST_DIED_HOURS, tick)
	ThreatDirector.colonist_died(state)
	state.post_message("%s morreu %s." % [colonist.display_name, cause])
