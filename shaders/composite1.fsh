#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D noisetex;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform vec2 texelSize;
uniform int isEyeInWater;
uniform vec3 upPosition;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float eyeAltitude;
uniform float viewWidth;
uniform float viewHeight;

#include "common.glsl"
#include "sky.glsl"

//#define VOLUMETRIC_CLOUDS
#define VOLUMETRIC_CLOUDS_SAMPLE_SIZE 0.3 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5]
#define VOLUMETRIC_CLOUDS_DENSITY 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define VOLUMETRIC_CLOUDS_DITHERING_STRENGTH 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VOLUMETRIC_CLOUDS_NOISE_SAMPLES 5 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
#define VOLUMETRIC_CLOUDS_RESOLUTION 0.3 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define VOLUMETRIC_CLOUDS_HEIGHT 0.8 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]
#define VOLUMETRIC_CLOUDS_USE_LOD

const mat3 m3 = mat3(0.8,-0.6,0.6,0.8,0.8,-0.6,0.6,0.8,0.6);
float Fbm(in vec3 Position, int Samples){
	float Value = 0.0;
	float a = 0.5;
	for(int i = 0; i < Samples; i++){
		Value += a*Noise3(Position);
		a *= 0.5;
		Position *= m3 * 2.0;
		Position += 0.1;
	}
	return Value;
}

float MapClouds(in vec3 Position, in float t, out float RawData){
	#ifdef VOLUMETRIC_CLOUDS_USE_LOD
	int Samples = VOLUMETRIC_CLOUDS_NOISE_SAMPLES - int(log2(1.0+t*0.1));
	#else
	int Samples = VOLUMETRIC_CLOUDS_NOISE_SAMPLES;
	#endif

	float d = 1.0-(1.0-VOLUMETRIC_CLOUDS_HEIGHT)*abs(-Position.y);
	d -= (2.0-rainStrength)*Fbm(Position*0.1+frameTimeCounter*0.03, Samples);

	RawData = d;

	d = clamp(d, 0.0, 1.0);

	return d;
}

vec4 RaymarchClouds(in vec3 RayOrigin, in vec3 RayDirection, float tmax){
	vec4 sum = vec4(0.0);

	float t = 0.1;

	for(int i = 0; i < 1024; i++){
		vec3 Position = RayOrigin + t*RayDirection;
		float RawData, Garbage;
		float Density = MapClouds(Position, t, RawData);
		
		float Dithering = Hash3(vec3(gl_FragCoord.xy, t)*(1.0/VOLUMETRIC_CLOUDS_RESOLUTION))*VOLUMETRIC_CLOUDS_DITHERING_STRENGTH+(1.0-VOLUMETRIC_CLOUDS_DITHERING_STRENGTH);

		float dt = clamp(Dithering*t, 0.1, 1.0);
		
		//vec4 SunPosition = vec4(sunPosition, 1.0) * gbufferModelView;
		//float SunLight = clamp((Density-MapClouds(Position+0.3*normalize(mix(-SunPosition.xyz, SunPosition.xyz, SunVisibility2)), t, Garbage))/(0.05+rainStrength*0.2), 0.0, 1.0);
		vec3 SkyColor = GetSkyColor(RayDirection);
		
		vec3 Light = mix(MoonColor, SunColor, SunVisibility2);//(SunColor*SunLight*SunVisibility)+(MoonColor*MoonLight*(1.0-SunVisibility));
		vec4 Color = vec4(ToLinear(mix(SkyColor, SkyColor+Light*(1.0-rainStrength*0.7)*(Position.y+0.5), Density)), Density);
		
		float Fog = exp2(dot(Position, Position)*exp2(-11.0+rainStrength*2.0));
		Color.a /= Fog;

		Color.a *= VOLUMETRIC_CLOUDS_DENSITY;
		Color.rgb *= Color.a;

		sum = sum + Color*(1.0 - sum.a);

		// it somehow gives more FPS
		float sm = 1.0 + 1.5*(1.0 - clamp(RawData+1.0, 0.0, 1.0));
		t += dt*pow(sm, 1.5);
		
		// compared to this
		//t += dt;
		
		if(sum.w > 0.999 || t > tmax) break;
	}
	vec3 Position = RayOrigin + t*RayDirection;

	return clamp(sum, 0.0, 1.0);
}

void main(){
	#ifdef VOLUMETRIC_CLOUDS
	if(TexCoords.x*(1.0/VOLUMETRIC_CLOUDS_RESOLUTION) < 1.0 && TexCoords.y*(1.0/VOLUMETRIC_CLOUDS_RESOLUTION) < 1.0){
    
    	vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*(1.0/VOLUMETRIC_CLOUDS_RESOLUTION)*texelSize,1.)) * mat3(gbufferModelView);
	
		/* DRAWBUFFERS:4 */
    	gl_FragData[0] = RaymarchClouds(vec3(0, eyeAltitude/50.0-10.0, 0), FragmentPosition, 120.0);
    } else {
    	gl_FragData[0] = vec4(0.0);
    }
    #else
    
    // very important, do not remove
    /* DRAWBUFFERS:4 */
    gl_FragData[0] = vec4(0.0);
    // very important, do not remove
    
    #endif
}
