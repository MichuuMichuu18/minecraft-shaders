#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;
uniform sampler2D noisetex;
uniform vec2 texelSize;

//#define BLOOM
#define BLOOM_BLUR_QUALITY 1.0 //[1.0 2.0 3.0]
#define BLOOM_BLUR_STEPS 13.0 //[4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0]
#define BLOOM_BLUR_STEPS_MULTIPLIER 4.0 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define BLOOM_BLUR_DIRECTIONS 11.0 //[4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0]
#define BLOOM_BLUR_NOISE
#define BLOOM_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_SAMPLE_BRIGHTNESS 1.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define BLOOM_STEP_STRENGTH_MULTIPLIER 0.95 //[0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0]

void main() {
	vec3 Albedo = vec3(0.0);
	
	if(TexCoords.x*(1.0/BLOOM_RESOLUTION) < 1.0 && TexCoords.y*(1.0/BLOOM_RESOLUTION) < 1.0){
	float Pi = 6.28318530718; // PI*2
	float BlurAccumulation = 0.0;
    
    for(float x = Pi/BLOOM_BLUR_DIRECTIONS; x <= Pi; x+=Pi/BLOOM_BLUR_DIRECTIONS){
    	float StepStrength = 1.0;
        for(float y = 1.0/BLOOM_BLUR_QUALITY; y <= BLOOM_BLUR_STEPS; y += 1.0/BLOOM_BLUR_QUALITY){
        	#ifdef BLOOM_BLUR_NOISE
        	vec2 Noise = vec2(texture2D(noisetex,TexCoords*10000.0).r, texture2D(noisetex,(TexCoords+1.0)*10000.0).r)*2.0-1.0;
        	#else
        	vec2 Noise = vec2(0.0);
        	#endif
            vec2 Offset = vec2(cos(x+Noise.x),sin(x+Noise.y))*texelSize*y*BLOOM_BLUR_STEPS_MULTIPLIER;
            vec2 CurrentTexCoords = TexCoords*(1.0/BLOOM_RESOLUTION)+(Offset);
            Albedo += texture2D(colortex0, CurrentTexCoords).rgb*StepStrength*BLOOM_SAMPLE_BRIGHTNESS;
            BlurAccumulation += 1.0;
            StepStrength *= BLOOM_STEP_STRENGTH_MULTIPLIER;
   		}
    }
    
    Albedo /= BlurAccumulation;
    
    }
    
    /* DRAWBUFFERS:3 */
	gl_FragData[0] = vec4(pow(Albedo, vec3(4.0)), 1.0f);
}
