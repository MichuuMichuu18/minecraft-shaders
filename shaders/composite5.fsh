#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D noisetex;
uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;

#include "common.glsl"

#define BLUR_2NDPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLUR_2NDPASS_STEP_STRENGTH_MULTIPLIER 0.95 //[0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0]
#define BLUR_1STPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

void main() {
	vec3 Albedo = vec3(0.0);
	
	if(TexCoords.x*(1.0/BLUR_2NDPASS_RESOLUTION) < 1.0 && TexCoords.y*(1.0/BLUR_2NDPASS_RESOLUTION) < 1.0){
    	float BlurSum = 0.0;
    	int Samples = 64;
    	float StepStrength = 1.0;
    	for(int i = 0; i < Samples; ++i) {
    	    vec2 Offset = Vogel(i, Samples, 0.0) * texelSize * 32.0;
    	    vec2 CurrentTexCoords = TexCoords*BLUR_1STPASS_RESOLUTION*(1.0/BLUR_2NDPASS_RESOLUTION)+Offset;
    	    Albedo += texture2D(colortex3, CurrentTexCoords).rgb*StepStrength;
    	    BlurSum += 1.0*StepStrength;
    	    StepStrength *= BLUR_2NDPASS_STEP_STRENGTH_MULTIPLIER;
    	}
    	Albedo /= BlurSum;
    } else {
    	Albedo = texture2D(colortex0, TexCoords*(1.0/BLUR_1STPASS_RESOLUTION)).rgb;
    }
    
    /* DRAWBUFFERS:4 */
	gl_FragData[0] = vec4(Albedo, 1.0f);
}
