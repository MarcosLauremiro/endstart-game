#!/bin/sh
# Exporta as folhas de terreno do Aseprite para PNG (o Godot não lê .aseprite).
# Uso, na raiz do projeto:  sh tools/export_terrain.sh
# Outro caminho do Aseprite:  ASEPRITE="/caminho/Aseprite.exe" sh tools/export_terrain.sh
ASEPRITE="${ASEPRITE:-/c/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe}"
for file in assets/tiles/terrain/*.aseprite; do
	"$ASEPRITE" -b "$file" --save-as "${file%.aseprite}.png" || exit 1
	echo "${file%.aseprite}.png"
done
