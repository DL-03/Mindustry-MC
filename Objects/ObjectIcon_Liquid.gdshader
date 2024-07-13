shader_type canvas_item;
#define HIGHP


uniform vec2 u_campos;


uniform bool water_effect = false;


varying vec2 v_texCoords;

const float mscl = 40.0;
const float mth = 7.0;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	

	if (water_effect) {
		vec2 c = UV;
	vec2 coords = vec2(-c.x / TEXTURE_PIXEL_SIZE.x + u_campos.x, c.y / TEXTURE_PIXEL_SIZE.y + u_campos.y);

	float stime = TIME*10.0;

    vec4 sampled = texture(TEXTURE, c + vec2(sin(stime/3.0 + coords.y/0.75) * TEXTURE_PIXEL_SIZE.x, 0.0));
    vec3 color = sampled.rgb * vec3(0.9, 0.9, 1);

    float tester = mod((coords.x + coords.y*1.1 + sin(stime / 8.0 + coords.x/5.0 - coords.y/100.0)*2.0) +
                           sin(stime / 20.0 + coords.y/3.0) * 1.0 +
                           sin(stime / 10.0 - coords.y/2.0) * 2.0 +
                           sin(stime / 7.0 + coords.y/1.0) * 0.5 +
                           sin(coords.x / 3.0 + coords.y / 2.0) +
                           sin(stime / 20.0 + coords.x/4.0) * 1.0, mscl);

    if(tester < mth){
        color *= 1.2;
    }

		COLOR = vec4(color.rgb, min(sampled.a * 100.0, 1.0));
	} else {
		
	}
	
	

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
