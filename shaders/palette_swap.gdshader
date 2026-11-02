// Troca de paleta indexada: cada pixel com uma das 4 cores de origem (a rampa do escuro ao claro
// desenhada na folha) vira a cor de mesma posição na rampa de destino. O resto passa sem mudar.
// Usado no cabelo e nas roupas dos colonos (ColonistLooks), sem mexer no desenho nem no alinhamento.
shader_type canvas_item;

uniform vec4 source_ramp[4] : source_color;
uniform vec4 target_ramp[4] : source_color;
// Distância máxima para contar como a mesma cor (as rampas não têm cores vizinhas tão próximas).
const float MATCH = 0.02;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec3 rgb = texel.rgb;
	for (int i = 0; i < 4; i++) {
		if (distance(texel.rgb, source_ramp[i].rgb) < MATCH) {
			rgb = target_ramp[i].rgb;
		}
	}
	COLOR = vec4(rgb, texel.a);
}
