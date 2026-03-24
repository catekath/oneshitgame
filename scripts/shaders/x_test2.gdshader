shader_type canvas_item;
//render_mode blend_disabled;

uniform vec4 mod = vec4(1, 0, 0, 1);
//uniform vec4 mod = vec4(1);

void fragment() {
	//COLOR *= mod;
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb = vec3(COLOR.r + COLOR.g + COLOR.b) / 3.0;
	
	
	//vec4 color = texture(TEXTURE, UV);
	//COLOR.rgb = vec3(dot(color.rgb, vector3(brightness, brightness, brightness)));
}
