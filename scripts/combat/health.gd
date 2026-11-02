class_name Health
extends RefCounted
## Saúde de colonos e saqueadores: ferimentos e perda de sangue. Usada pelo combate (M7).
## Caído com 60 de dano ou 50% de sangue perdido; morto com 100 de dano ou 100% de sangue.
## O sangue escorre e os ferimentos curam a cada hora; tratar estanca o sangramento e cura mais rápido.

var injuries: Array[Injury] = []
var blood_loss: float = 0.0


func damage() -> float:
	var total := 0.0
	for injury in injuries:
		total += injury.damage
	return total


func add_injury(kind: Injury.Kind, amount: float) -> void:
	injuries.append(Injury.new(kind, amount))


func is_hurt() -> bool:
	return not injuries.is_empty() or blood_loss > 0.0


func is_dead() -> bool:
	return damage() >= Balance.HEALTH_MAX or blood_loss >= Balance.MAX_BLOOD_LOSS


func is_downed() -> bool:
	return not is_dead() and (damage() >= Balance.DOWNED_DAMAGE or blood_loss >= Balance.DOWNED_BLOOD_LOSS)


func is_bleeding() -> bool:
	for injury in injuries:
		if injury.bleeds():
			return true
	return false


func needs_tending() -> bool:
	return is_bleeding()


## Sangue perdido por hora: 0,5% por ponto de dano dos ferimentos que sangram.
func bleeding_per_hour() -> float:
	var total := 0.0
	for injury in injuries:
		if injury.bleeds():
			total += injury.damage * Balance.BLEED_PER_DAMAGE_HOUR
	return total


func tend() -> void:
	for injury in injuries:
		injury.tended = true


## Saúde em %, para a interface: o pior entre o dano e o sangue.
func percent() -> int:
	var worst := maxf(damage() / Balance.HEALTH_MAX, blood_loss / Balance.MAX_BLOOD_LOSS)
	return clampi(roundi(100.0 * (1.0 - worst)), 0, 100)


## A dor tira até 50% da velocidade de trabalho e de movimento.
func pain_factor() -> float:
	return 1.0 - Balance.PAIN_SPEED_LOSS * clampf(damage() / Balance.HEALTH_MAX, 0.0, 1.0)


## Uma hora de jogo: sangra, recupera sangue se não sangra e cura os ferimentos.
func hour_passed(in_bed: bool) -> void:
	var bleeding := bleeding_per_hour()
	if bleeding > 0.0:
		blood_loss = minf(blood_loss + bleeding, Balance.MAX_BLOOD_LOSS)
	else:
		blood_loss = maxf(blood_loss - Balance.BLOOD_RECOVERY_PER_HOUR, 0.0)
	var bed := Balance.HEAL_BED_FACTOR if in_bed else 1.0
	for injury in injuries:
		var rate := Balance.HEAL_TENDED_PER_HOUR if injury.tended else Balance.HEAL_UNTENDED_PER_HOUR
		injury.damage -= rate * bed
	injuries = injuries.filter(func(injury: Injury) -> bool: return injury.damage > 0.0)


func status_text() -> String:
	if is_dead():
		return "Morto"
	if is_downed():
		return "Caído"
	if is_bleeding():
		return "Sangrando"
	if is_hurt():
		return "Ferido"
	return "Saudável"
