shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float shake_amount = .005;
uniform float saturation : hint_range(0.0, 1.0) = 0.2;
uniform float contrast = 1.5;
uniform float brightness = .125;
uniform float grain_scale = 250.0;
uniform float grain_density : hint_range(0.0, 1.0) = .5;
uniform float flash_amount = .005;
uniform float vignette_width = .2;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

vec2 random2(vec2 st){
	st = vec2( dot(st,vec2(127.1,311.7)),
			  dot(st,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float noise(vec2 st, float seed) {
	vec2 cell_id = floor(st);
	vec2 cell_uv = fract(st);

	vec2 u = cell_uv*cell_uv*(3.0-2.0*cell_uv);

	return mix(
		mix(
			dot(random2(cell_id + vec2(0.0,0.0) + seed), cell_uv - vec2(0.0,0.0)),
			dot(random2(cell_id + vec2(1.0,0.0) + seed), cell_uv - vec2(1.0,0.0)), 
			u.x
		),
		mix(
			dot(random2(cell_id + vec2(0.0,1.0) + seed), cell_uv - vec2(0.0,1.0)),
			dot(random2(cell_id + vec2(1.0,1.0) + seed), cell_uv - vec2(1.0,1.0)), u.x),
			u.y
		);
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	vec2 aspect = normalize(vec2(textureSize(screen_texture, 0)));
	vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	
	// shaking
	float shake_offset = hash(TIME) * shake_amount;
	vec4 screen_sample = texture(
		screen_texture, vec2(UV.x, UV.y + shake_offset)
	);
	vec3 col = screen_sample.rgb;
	
	// desaturation
	vec3 luminance = vec3(0.2126, 0.7152, 0.0722);
	float desat_color = dot(col.rgb, luminance);
	col = mix(vec3(desat_color), col.rgb, saturation);
	
	// contrast and brightness
	col = (col - .5) * max(contrast, 0.0) + .5f;
	col += brightness;
	
	// grain noise
	col *= (
		noise(UV * aspect * grain_scale, TIME) 
		* grain_density + 1.0 - grain_density
	);
	
	// flashing
	col += hash(TIME) * flash_amount;
	
	// artifacts
	float streak_x = hash(floor(TIME * 2.0))
	 + fract(
		TIME * .1 * (hash(floor(TIME * 3.0)) > .5 ? -1.0 : 1.0)
	);
	float streak_width = pixel_size.x * 1.0;
	if (UV.x > streak_x && UV.x < streak_x + streak_width) {
		col *= vec3(
			clamp(noise(UV * 50.0, TIME * 2.0) * 10.0, 0.0, 1.0)
		);
	}
	
	// vignette
	vec2 vignette_size = 1.0 / aspect * vignette_width;
	float vignette_factor = min(
		min(
			mix(1.0, 0.0, 
				(vignette_size.x - UV.x) / vignette_size.x
			),
			mix(1.0, 0.0, 
				(UV.x - (1.0 - vignette_size.x)) / vignette_size.x
			)
		),
		min(
			mix(1.0, 0.0, 
				(vignette_size.y - UV.y) / vignette_size.y
			),
			mix(1.0, 0.0, 
				(UV.y - (1.0 - vignette_size.y)) / vignette_size.y
			)
		)
	);
	vignette_factor = min(1.0, vignette_factor);
	col *= vignette_factor;
	
	COLOR.rgb = col;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
