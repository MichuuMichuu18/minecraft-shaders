#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform vec2 texelSize;
uniform int isEyeInWater;
uniform vec3 upPosition;
uniform vec3 fogColor;
uniform float rainStrength;
uniform float darknessFactor;
uniform float blindness;
uniform float nightVision;
uniform ivec2 eyeBrightnessSmooth;

#include "common.glsl"
#include "sky.glsl"

//#define VOLUMETRIC_CLOUDS
#define VOLUMETRIC_CLOUDS_RESOLUTION 0.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

void main(){
    vec3 Albedo = texture2D(colortex0, TexCoords).rgb;
    float Depth = texture2D(depthtex0, TexCoords).r;
    
    if(Depth == 1.0f && isEyeInWater != 1){
    	#ifdef VOLUMETRIC_CLOUDS
    	vec4 Fog = texture2D(colortex4, TexCoords*(VOLUMETRIC_CLOUDS_RESOLUTION-0.001));
 		Albedo = Albedo*(1.0-Fog.w) + Fog.xyz;
 		#endif
        gl_FragData[0] = mix(vec4(Albedo, 1.0), vec4(0,0,0,1), clamp(darknessFactor+blindness, 0.0, 1.0));
        return;
    }
    
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    vec4 FogColor = vec4(ToLinear(GetSkyColor(FragmentPosition, false))*(eyeBrightnessSmooth.y/255.0), mix(0.001, 0.01, rainStrength));
    vec2 Position = gbufferProjectionInverse[2].zw * Depth + gbufferProjectionInverse[3].zw;
	float WorldDistance = (Position.x/Position.y);
	//if(isEyeInWater == 1) { FogColor.rgb *= fogColor; FogColor.a = 0.005; Albedo *= vec3(0.9, 1.1, 1.3); }
	
	// Support for player effects
	FogColor = mix(FogColor, vec4(0,0,0,mix(0.2, 0.5, blindness)), clamp(darknessFactor+blindness, 0.0, 1.0));
	
	float FogDensity = exp2(WorldDistance*FogColor.a);
    Albedo = mix(FogColor.rgb,Albedo,FogDensity);
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Albedo, 1.0f);
}
