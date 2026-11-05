shader_type canvas_item;
// Pinta o desenho do cartão por regiões e faz a cor "explodir" do centro para fora,
// com uma borda brilhante ondulada. progresso = 1.3 mostra o desenho inteiro.

uniform sampler2D regioes : filter_nearest; // R: 0 = cor0, 1/3 = cor1, 2/3 = cor2, 1 = branco
uniform vec4 cor0 : source_color = vec4(1.0);
uniform vec4 cor1 : source_color = vec4(1.0);
uniform vec4 cor2 : source_color = vec4(1.0);
uniform float progresso : hint_range(0.0, 1.3) = 1.3;
uniform vec4 cor_borda : source_color = vec4(1.0, 0.96, 0.65, 1.0);
uniform vec2 centro = vec2(0.5, 0.55);
uniform float corte = 2.0; // some tudo abaixo desta altura (UV), atrás da moita

varying vec4 modula;

void vertex() {
	modula = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float k = texture(regioes, UV).r;
	vec3 cor = k < 0.17 ? cor0.rgb : (k < 0.5 ? cor1.rgb : (k < 0.83 ? cor2.rgb : vec3(1.0)));
	vec3 rgb = c.rgb * cor;

	vec2 p = UV - centro;
	float d = length(p) / 0.72;
	float onda = sin(atan(p.y, p.x) * 7.0 + TIME * 7.0) * 0.035;
	float r = progresso + onda;
	float dentro = 1.0 - smoothstep(r - 0.025, r + 0.025, d);
	float ativo = step(0.001, progresso) * (1.0 - smoothstep(1.05, 1.25, progresso));
	float borda = (1.0 - smoothstep(0.0, 0.09, abs(d - r))) * ativo;
	rgb = mix(rgb, cor_borda.rgb, borda * 0.85);
	float visivel = 1.0 - step(corte, UV.y);
	COLOR = vec4(rgb, c.a * max(dentro, borda) * visivel) * modula;
}
