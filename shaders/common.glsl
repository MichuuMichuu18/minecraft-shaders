float Luminance(vec3 color) {
    return dot(color, vec3(0.2125, 0.7153, 0.0721));
}

vec3 ToLinear(vec3 col){
	return mix(col / 12.92, pow((col+0.055)/1.055,vec3(2.4)), step(0.04045, col));
}

uniform mat4 gbufferProjectionInverse;
vec3 ToScreenSpaceVector(vec3 p) {
    vec3 p3 = p * 2. - 1.;
    vec4 FragmentPosition = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw) * p3.xyzz + gbufferProjectionInverse[3];
    return normalize(FragmentPosition.xyz);
}

float Hash3(vec3 n) {
	return fract(sin(dot(n, vec3(12.9898, 78.233, 471.169)))*43758.5453);
}

float Noise3(in vec3 x){
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = smoothstep(0.0, 1.0, f);

	return mix(mix(mix(Hash3(i+vec3(0,0,0)),
										Hash3(i+vec3(1,0,0)),f.x),
								mix(Hash3(i+vec3(0,1,0)),
										Hash3(i+vec3(1,1,0)),f.x),f.y),
						mix(mix(Hash3(i+vec3(0,0,1)),
										Hash3(i+vec3(1,0,1)),f.x),
								mix(Hash3(i+vec3(0,1,1)),
										Hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}

float Hash2(vec2 n) {
	n = vec2(dot(n, vec2(127.1, 331.7)), dot(n, vec2(269.5, 183.3)));
	return -1.0+2.0*fract(sin(dot(sin(n), vec2(12.9898, 78.233)))* 478.0);
}

float Noise2(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(Hash2(b), Hash2(b + d.yx), f.x), mix(Hash2(b + d.xy), Hash2(b + d.yy), f.x), f.y);
}


