shader_type canvas_item;

uniform sampler2D texture2;
uniform vec2 offset;

void fragment() {
	vec4 tex1 = texture(TEXTURE, UV);
	vec4 tex2 = texture(texture2, UV + offset * TEXTURE_PIXEL_SIZE);

	float intersection = tex1.a * tex2.a;

	vec4 blended_color = mix(tex1, tex2, intersection > 0. ? 0.3 : 0.);
	if (blended_color.b > 0.2) blended_color += vec4(0.1, 0, 0.15, 0);

    COLOR = blended_color;
}
