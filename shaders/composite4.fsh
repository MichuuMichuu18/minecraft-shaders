#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D noisetex;
uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;

#include "common.glsl"

#define BLOOM
#define SHARPENING
#define BLUR_2NDPASS

#ifdef SHARPENING
#define BLUR_1STPASS
#endif

#ifdef BLUR_2NDPASS
#define BLUR_1STPASS
#endif

#ifdef BLOOM
#define BLUR_1STPASS
#endif

#define BLUR_1STPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLUR_1STPASS_SAMPLES 64 //[4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 128]
#define BLUR_1STPASS_OFFSET_MULTIPLIER 16.0 //[1.0 2.0 4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0 20.0 22.0 24.0 26.0 28.0 30.0 32.0 34.0 36.0 38.0 40.0 42.0 44.0 46.0 48.0 50.0 52.0 54.0 56.0 58.0 60.0 62.0 64.0]
#define BLUR_1STPASS_STEP_STRENGTH_MULTIPLIER 0.95 //[0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0]

void main() {
	vec3 Albedo = vec3(0.0);
	
	if(TexCoords.x*(1.0/BLUR_1STPASS_RESOLUTION) < 1.0 && TexCoords.y*(1.0/BLUR_1STPASS_RESOLUTION) < 1.0){
    	float BlurSum = 0.0;
    	float StepStrength = 1.0;
    	for(int i = 0; i < BLUR_1STPASS_SAMPLES; ++i) {
    	    vec2 Offset = Vogel(i, BLUR_1STPASS_SAMPLES, 0.0) * texelSize * BLUR_1STPASS_OFFSET_MULTIPLIER;
    	    vec2 CurrentTexCoords = TexCoords*(1.0/BLUR_1STPASS_RESOLUTION)+Offset;
    	    Albedo += clamp(texture2D(colortex0, CurrentTexCoords).rgb, 0.0, 1.0)*StepStrength;
    	    BlurSum += 1.0*StepStrength;
    	    StepStrength *= BLUR_1STPASS_STEP_STRENGTH_MULTIPLIER;
    	}
    	Albedo /= BlurSum;
    } else {
    	Albedo = texture2D(colortex0, TexCoords*(1.0/BLUR_1STPASS_RESOLUTION)).rgb;
    }
    
    //if(Albedo.r > 1.0 || Albedo.g > 1.0 || Albedo.b > 1.0) Albedo *= vec3(1.0, 0.5, 0.5);
    
    /* DRAWBUFFERS:3 */
	gl_FragData[0] = vec4(Albedo, 1.0f);
}
