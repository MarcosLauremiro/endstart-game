class_name Threats
extends RefCounted
## Estado da ameaça na partida (dados; as regras estão em ThreatDirector e RaiderAI):
## o próximo ataque, o ataque avisado ou em andamento, os saqueadores no mapa e a adaptação.

## id → Raider
var raiders := {}
## Ataque avisado ou em andamento (null = nenhum).
var raid: Raid
var next_raid_tick: int = (Balance.FIRST_RAID_DAY - 1) * Balance.TICKS_PER_DAY \
	+ ((Balance.RAID_EARLIEST_HOUR + Balance.RAID_LATEST_HOUR) / 2) * Balance.TICKS_PER_HOUR
## M_adaptação do GDD.
var adaptation: float = 1.0
var colonists_lost_today: int = 0
var raids_survived: int = 0
## Fim da calma depois do último ataque (tick).
var calm_until: int = 0
