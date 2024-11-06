#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;

// The texture atlas
uniform sampler2D texture;

uniform sampler2D colortex1;
uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec2 texelSize;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float rainStrength;
uniform float nightVision;
uniform float frameTimeCounter;

#include "common.glsl"
#include "sky.glsl"

#define DRAW_SUN

float Fbm(in vec2 p, int s){
	float v = 0.0;
	float a = 0.5;
	for(int i = 0; i < s; i++){
		v += a*(Noise2(p)*2.0-1.0);
		a *= 0.5;
		p *= 2.0;
	}
	return v;
}

vec4 clouds(vec2 n, vec2 ligPos){
	vec4 v = vec4(0.0);
	float fbm = 0.0;
	float fbmLig = 0.0;
	for(int i = 0; i < 2; i++){
		float fbm    = Fbm(n+frameTimeCounter*0.05, 10);
		float fbmLig = Fbm(n+ligPos*0.5+frameTimeCounter*0.05, 10/2);
		vec4 col = vec4(mix(vec3(1.0), vec3(0.5), fbm), fbm);
		vec3 Light = mix(MoonColor, SunColor, SunVisibility2);
		col.rgb -= fbmLig*0.8*Light;
		col.rgb *= col.a;
		v = v + col * (1.0 - v.a);
	}

	return v;
}

void main(){
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    
    vec4 Albedo = vec4(GetSkyColor(FragmentPosition), 1.0);
    
    float SunFdotS = dot(FragmentPosition, normalize(SunDirection));
    #ifdef DRAW_SUN
    Albedo.rgb += clamp(pow(SunFdotS+0.0004, 20000.0)*(1.0-rainStrength*0.9), 0.0, 1.0)*SunColor;
    #endif
    
    vec3 FragmentPosition2 = ToScreenSpace(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    /*
    if(FragmentPosition.y > 0.0) {
   		vec4 SunPosition = vec4(sunPosition, 1.0) * gbufferModelView;
    	vec3 LightDirection = normalize(mix(-SunPosition.xyz, SunPosition.xyz, SunVisibility2));
    	vec4 Clouds = clouds(FragmentPosition.xz/(FragmentPosition.y*0.5), normalize(LightDirection.xz/LightDirection.y));
    	Albedo.rgb = mix(Albedo.rgb, clamp(0.5+Clouds.rgb, 0.0, 1.0), clamp(Clouds.a, 0.0, 1.0)*clamp(FragmentPosition.y*3.0, 0.0, 1.0));
    }*/
    
    /* DRAWBUFFERS:012 */
    // Write the values to the color textures
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
