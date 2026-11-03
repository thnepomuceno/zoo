shader_type canvas_item;
// A cor "explode" do centro do animal para fora, com uma borda brilhante ondulada.

uniform float progresso : hint_range(0.0, 1.3) = 0.0;
uniform vec4 cor_borda : source_color = vec4(1.0, 0.96, 0.65, 1.0);
uniform vec2 centro = vec2(0.5, 0.55);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = UV - centro;
	float d = length(p) / 0.72;
	float onda = sin(atan(p.y, p.x) * 7.0 + TIME * 7.0) * 0.035;
	float r = progresso + onda;
	float dentro = 1.0 - smoothstep(r - 0.025, r + 0.025, d);
	float ativo = step(0.001, progresso) * (1.0 - smoothstep(1.05, 1.25, progresso));
	float borda = (1.0 - smoothstep(0.0, 0.09, abs(d - r))) * ativo;
	vec3 rgb = mix(c.rgb, cor_borda.rgb, borda * 0.85);
	COLOR = vec4(rgb, c.a * max(dentro, borda));
}
