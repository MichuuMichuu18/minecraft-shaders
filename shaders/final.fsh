#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform vec2 texelSize;
uniform ivec2 eyeBrightnessSmooth;

//#define BLOOM
#define BLOOM_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_FINAL_BRIGHTNESS 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

vec3 Tonemap(vec3 col){
	col = exp(-1.0 / (2.72*col + 0.1));
	col = pow(col, vec3(1.0 / 2.2));
	return col;
}

//#define SHARPENING
#define SHARPENING_BLUR_QUALITY 1.0 //[1.0 2.0 3.0]
#define SHARPENING_BLUR_STEPS 2.0 //[1.0 2.0 3.0 4.0]
#define SHARPENING_BLUR_STEPS_MULTIPLIER 2.0 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define SHARPENING_BLUR_DIRECTIONS 5.0 //[4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0]
#define SHARPENING_STRENGTH 0.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define DESATURATE
//#define RETRO_FILTER
#define TONEMAP

#include "common.glsl"

void main() {
	vec3 Color = texture2D(colortex0, TexCoords).rgb;
	
	#ifdef SHARPENING
	vec3 ColorBlurred = vec3(0.0);
	
	float pi = 6.28318530718; // PI*2
	float blurSum = 0.0;
    
    for(float x = 0; x <= pi; x+=pi/SHARPENING_BLUR_DIRECTIONS){
        for(float y = 1.0/SHARPENING_BLUR_QUALITY; y <= SHARPENING_BLUR_STEPS; y+= 1.0/SHARPENING_BLUR_QUALITY){
            vec2 Offset = vec2(cos(x),sin(x))*texelSize*y*SHARPENING_BLUR_STEPS_MULTIPLIER;
            vec2 CurrentTexCoords = TexCoords+(Offset);
            ColorBlurred += texture2D(colortex0, CurrentTexCoords).rgb;
            blurSum += 1.0;
   		}
    }
    ColorBlurred /= blurSum;
    
    Color += (Color - ColorBlurred)*SHARPENING_STRENGTH;
    #endif
	
	#ifdef BLOOM
	Color += texture2D(colortex3, TexCoords/(1.0/BLOOM_RESOLUTION)).rgb*BLOOM_FINAL_BRIGHTNESS;
	#endif
	
	#ifdef DESATURATE
	Color = mix(vec3(Luminance(Color)), Color, 0.9);
	#endif
	
	#ifdef RETRO_FILTER
	Color *= vec3(1.3, 1.1, 0.7);
	Color += vec3(0.0, 0.02, 0.05);
	#endif
	
	Color = max(vec3(0.0), Color);
	
	#ifdef TONEMAP
	Color = Tonemap(Color);
	#endif
	
	gl_FragColor = vec4(Color, 1.0f);
}
