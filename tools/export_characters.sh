#!/bin/sh
# Exporta as folhas dos colonos do Aseprite para PNG (o Godot não lê .aseprite).
# Uso, na raiz do projeto:  sh tools/export_characters.sh
# Outro caminho do Aseprite:  ASEPRITE="/caminho/Aseprite.exe" sh tools/export_characters.sh
ASEPRITE="${ASEPRITE:-/c/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe}"
for sheet in character_base hair clothing; do
	"$ASEPRITE" -b "assets/characters/colonists/$sheet.aseprite" --save-as "assets/characters/colonists/$sheet.png" || exit 1
	echo "assets/characters/colonists/$sheet.png"
done
