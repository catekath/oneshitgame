shader_type canvas_item;

uniform vec2 Direction = vec2(1.0, 0.0);
uniform float Speed = 0.05;
//const float move_speed = -100.0f;

void vertex() {
	// Called for every vertex the material is visible on.
	
	//VERTEX.x += move_speed * cos(TIME);
	//VERTEX.x = clamp(VERTEX.x, -100, 100);
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, UV + vec2(TIME*0.05,0));
	
	//vec2 distortUV = UV;
	//distortUV.x += 1.0 * distortUV.y;
	//distortUV.y = distortUV.x;
	
	//vec4 pixelColor = texture(TEXTURE, distortUV);
	//COLOR = pixelColor;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
