float Luminance(vec3 color) {
    return dot(color, vec3(0.2125, 0.7153, 0.0721));
}

vec3 ToLinear(vec3 col){
	return mix(col / 12.92, pow((col+0.055)/1.055,vec3(2.4)), step(0.04045, col));
}

uniform mat4 gbufferProjectionInverse;
vec3 ToScreenSpace(vec3 p) {
    vec3 p3 = p * 2. - 1.;
     vec4 FragmentPosition = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw) * p3.xyzz + gbufferProjectionInverse[3];
    return FragmentPosition.xyz / FragmentPosition.w;
}
vec3 ToScreenSpaceVector(vec3 p) {
    vec3 p3 = p * 2. - 1.;
    vec4 FragmentPosition = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw) * p3.xyzz + gbufferProjectionInverse[3];
    return normalize(FragmentPosition.xyz);
}
#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)
vec4 ToClipSpace3(vec3 viewSpacePosition) {
    return vec4(projMAD(gl_ProjectionMatrix, viewSpacePosition),-viewSpacePosition.z);
}

float InterleavedGradientNoise(vec2 p){
    vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract( magic.z * fract(dot(p,magic.xy)) );
}

float Hash3(in vec3 x){
	x  = fract(x * .1031);
    x += dot(x, x.zyx + 31.32);
    return fract((x.x + x.y) * x.z);
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

vec3 Hash33(in vec3 x){
	x = fract(x * vec3(.1031, .1030, .0973));
    x += dot(x, x.yxz+33.33);
    return fract((x.xxy + x.yxx)*x.zyx);
}

float Hash2(in vec2 x){
	vec3 x3  = fract(vec3(x.xyx) * .1031);
    x3 += dot(x3, x3.yzx + 33.33);
    return fract((x3.x + x3.y) * x3.z);
}

float Noise2(in vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(Hash2(b), Hash2(b + d.yx), f.x), mix(Hash2(b + d.xy), Hash2(b + d.yy), f.x), f.y);
}

vec3 Noise33(in vec3 x){
	return vec3(Noise2(x.xy), Noise2(x.yz), Noise2(x.zx));
}


