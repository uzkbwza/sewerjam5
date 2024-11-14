uniform vec2 viewport_size;      
uniform vec2 canvas_size;
uniform sampler2D pixel_texture; 

uniform float tile_size = 1.0;   
uniform float image_size = 1.0;  

uniform float effect_strength = 0.2; 

uniform float brightness = 1.6;

vec4 lerp(vec4 a, vec4 b, float t) {
    return a + (b - a) * t;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 pixel_coords = texture_coords * viewport_size;
	vec2 pixel_uv = mod(pixel_coords, 1.0);


    vec2 tile_index = floor(pixel_coords / tile_size);

	vec2 offset = vec2(0.0);
	// vec2 pixel_size = 1.0 / viewport_size;
    // vec2 screen_pixel_size = 1.0 / canvas_size;
    // float pixel_scale = screen_pixel_size.x / pixel_size.x;

	// float brightness = brightness;

	// if (abs(pixel_scale - 3.0) < 0.001) {
	// 	offset = vec2(0.01, 0.01);
	// 	brightness = 0;
	// }
    float tile_range = ceil((image_size / 2.0) / tile_size);

    vec4 accumulated_color = vec4(0.0);
    int num_contributions = 0;

	vec4 pixel = Texel(pixel_texture, pixel_uv + offset);
	vec4 texel = Texel(texture, texture_coords);

	
    vec4 final_color = lerp(texel, texel * pixel * brightness, effect_strength);

    
    // final_color = clamp(final_color, 0.0, 1.0);

    
    

    return final_color;
}
