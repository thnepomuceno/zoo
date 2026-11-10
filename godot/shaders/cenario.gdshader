shader_type canvas_item;
// Fundo vivo de qualquer cenário: copas balançando ao vento, grama ondulando, água
// tremendo e a cor que some/volta.

uniform float saturacao : hint_range(0.0, 1.0) = 0.0;
uniform float brilho : hint_range(0.0, 1.5) = 0.8;
uniform float vinheta : hint_range(0.0, 1.0) = 0.5;
uniform float vento : hint_range(0.0, 3.0) = 1.0;
uniform float rajada : hint_range(0.0, 2.0) = 0.0; // pico curto, animado pelo script
uniform float copas : hint_range(0.0, 1.0) = 1.0; // 0 = nada balança no alto (ex.: celeiro)
uniform vec2 centro_lago = vec2(0.83, 0.835);
uniform vec2 raio_lago = vec2(0.13, 0.055);
uniform float submerso : hint_range(0.0, 1.0) = 0.0; // fundo do mar: tudo ondula e a luz dança

void fragment() {
	vec2 uv = UV;
	float forca = vento * (0.7 + 0.3 * sin(TIME * 0.45)) + rajada;

	// Copas: quanto mais alto, mais balança. Troncos e chão ficam firmes.
	float copa = (1.0 - smoothstep(0.22, 0.62, uv.y)) * copas;
	float onda = sin(TIME * 1.7 + uv.y * 9.0 + uv.x * 5.0) * 0.0045
		+ sin(TIME * 2.9 + uv.x * 14.0 + uv.y * 3.0) * 0.0018;
	uv.x += onda * copa * forca;
	uv.y += cos(TIME * 1.3 + uv.x * 11.0) * 0.0016 * copa * forca;

	// Grama: ondinhas rápidas na faixa de baixo.
	float grama = smoothstep(0.70, 0.95, uv.y);
	uv.x += sin(TIME * 2.4 + uv.x * 38.0 + uv.y * 16.0) * 0.0022 * grama * forca;

	// Espelho d'água do lago tremendo de leve.
	vec2 lago = (uv - centro_lago) / raio_lago;
	float agua = 1.0 - smoothstep(0.7, 1.0, length(lago));
	uv.y += sin(TIME * 3.0 + uv.x * 90.0) * 0.0012 * agua;

	// Debaixo d'água a imagem inteira ondula devagar.
	uv.x += sin(TIME * 1.1 + uv.y * 14.0) * 0.0022 * submerso * forca;
	uv.y += sin(TIME * 0.9 + uv.x * 10.0) * 0.0014 * submerso;

	vec4 c = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999)));
	// Cáusticas: manchinhas de luz se mexendo, mais fortes perto da superfície.
	float caustica = sin(uv.x * 46.0 + TIME * 1.6 + sin(uv.y * 30.0 + TIME)) * sin(uv.y * 38.0 - TIME * 1.2 + sin(uv.x * 24.0));
	c.rgb += vec3(0.06, 0.08, 0.08) * smoothstep(0.55, 1.0, caustica) * submerso * (1.0 - uv.y * 0.6) * saturacao;

	// Sem cor: cinza azulado e apagado. Com cor: vivo e quente.
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cinza = vec3(l) * vec3(0.93, 0.96, 1.04);
	vec3 viva = mix(vec3(l), c.rgb, 1.12); // um tiquinho mais saturado no fim
	c.rgb = mix(cinza, viva, saturacao) * brilho;

	float d = distance(UV, vec2(0.5, 0.48));
	c.rgb *= 1.0 - vinheta * smoothstep(0.35, 0.85, d);
	COLOR = c;
}
