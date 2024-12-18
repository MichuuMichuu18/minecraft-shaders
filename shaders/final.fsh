#version 120

varying vec2 TexCoords;

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D noisetex;
uniform vec2 texelSize;
uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferPreviousProjection;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float frameTime;
uniform float viewWidth;
uniform float viewHeight;

#define BLUR_1STPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLUR_2NDPASS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define BLOOM
#define BLOOM_FINAL_BRIGHTNESS 0.7 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

//#define SHARPENING
#define SHARPENING_STRENGTH 0.2 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define DESATURATE
//#define RETRO_FILTER
#define TONEMAP
#define MOTION_BLUR

#include "common.glsl"

void main() {
	vec3 Color = texture2D(colortex0, TexCoords).rgb;
	
	#ifdef MOTION_BLUR
	float Depth = texture2D(depthtex0, TexCoords).r;
	
	// Calculate current fragment position in view space
    vec4 CurrentPosition = vec4(TexCoords * 2.0 - 1.0, Depth * 2.0 - 1.0, 1.0);
    vec4 WorldPosition = gbufferProjectionInverse * CurrentPosition;
    WorldPosition = gbufferModelViewInverse * WorldPosition;
    WorldPosition /= WorldPosition.w;
    WorldPosition.xyz += cameraPosition;

    // Calculate previous fragment position in clip space
    vec4 PreviousPosition = vec4(WorldPosition.xyz - previousCameraPosition, 1.0);
    PreviousPosition = gbufferPreviousModelView * PreviousPosition;
    PreviousPosition = gbufferPreviousProjection * PreviousPosition;
    PreviousPosition /= PreviousPosition.w;
	
	// Compute screen-space velocity
	vec2 Velocity = vec2(0.0);
    if (Depth > 0.6) {
        Velocity = clamp(
            (CurrentPosition.xy - PreviousPosition.xy) / frameTime * 0.005, 
            vec2(-0.1), 
            vec2(0.1)
        );
    }
    
    // Dithering for motion blur (to smooth it out)
	float Dithering = GetIGNoise(gl_FragCoord.xy);
	Color = vec3(0.0);
	int Samples = 0;
	
	for (int i = -2; i <= 2; ++i) {
		float SampleOffset = float(i) + Dithering;
        vec2 SampleCoords = TexCoords + Velocity * (SampleOffset / 2.0);
		
		// Ensure sample coordinates are within texture bounds
        if (all(greaterThan(SampleCoords, vec2(0.0))) && all(lessThan(SampleCoords, vec2(1.0)))) {
            Color += texture2D(colortex0, SampleCoords).rgb;
            Samples++;
        }
	}
	Color /= Samples;
	#endif
	
	#ifdef SHARPENING
    Color += (Color - texture2D(colortex3, TexCoords/(1.0/BLUR_1STPASS_RESOLUTION)).rgb)*SHARPENING_STRENGTH;
    #endif
	
	#ifdef BLOOM
	Color += pow(ACES(texture2D(colortex4, TexCoords/(1.0/BLUR_2NDPASS_RESOLUTION)).rgb), vec3(4.0))*BLOOM_FINAL_BRIGHTNESS;
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
	Color = ACES(Color);
	#endif
	
	gl_FragColor = vec4(Color+InterleavedGradientNoise(gl_FragCoord.xy)*exp2(-8.0), 1.0f);
}
