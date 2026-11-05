shader_type canvas_item;
// Tira a cor de um desenho (moitas, coruja) no mesmo tom cinza-azulado do fundo.

uniform float saturacao : hint_range(0.0, 1.0) = 0.0;

varying vec4 modula;

void vertex() {
	modula = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(l) * vec3(0.93, 0.96, 1.04), c.rgb, saturacao);
	COLOR = c * modula;
}
