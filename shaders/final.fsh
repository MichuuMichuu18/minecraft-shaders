#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D noisetex;
uniform vec2 texelSize;
uniform ivec2 eyeBrightnessSmooth;

#define BLUR_1STPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLUR_2NDPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define BLOOM
#define BLOOM_FINAL_BRIGHTNESS 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

vec3 ACES(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.43;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 tonemap1(vec3 col){
	col = col/sqrt(col*col+1.0/2.2);
	return col;
}

//#define SHARPENING
#define SHARPENING_STRENGTH 0.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define DESATURATE
//#define RETRO_FILTER
#define TONEMAP

#include "common.glsl"

void main() {
	vec3 Color = texture2D(colortex0, TexCoords).rgb;
	
	#ifdef SHARPENING
    Color += (Color - texture2D(colortex3, TexCoords/(1.0/BLUR_1STPASS_RESOLUTION)).rgb)*SHARPENING_STRENGTH;
    #endif
	
	#ifdef BLOOM
	Color += pow(ACES(texture2D(colortex4, TexCoords/(1.0/BLUR_2NDPASS_RESOLUTION)).rgb), vec3(3.0))*BLOOM_FINAL_BRIGHTNESS;
	#endif
	
	#ifdef DESATURATE
	Color = mix(vec3(Luminance(Color)), Color, 0.8);
	#endif
	
	#ifdef RETRO_FILTER
	Color *= vec3(1.3, 1.1, 0.7);
	Color += vec3(0.0, 0.02, 0.05);
	#endif
	
	Color = max(vec3(0.0), Color);
	
	#ifdef TONEMAP
	Color = ACES(Color);
	#endif
	
	gl_FragColor = vec4(Color+InterleavedGradientNoise(gl_FragCoord.xy)*exp2(-8.0), 1.0f);
}
