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
#include "stars.glsl"

#define STARS

void main(){
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    vec4 Albedo = vec4(GetSkyColor(FragmentPosition, true), 1.0);
    
    if(FragmentPosition.y > 0.0){
    	#ifdef STARS
		vec2 StarsCoordinates = FragmentPosition.xz/(1.0+clamp(FragmentPosition.y, 0.0, 1.0));
		Albedo.rgb += StableStarField(StarsCoordinates*500.0, 0.997)*1.0*(1.0-rainStrength)*MoonVisibility2*(FragmentPosition.y+0.3);
		#endif
	}
    
    /* DRAWBUFFERS:012 */
    // Write the values to the color textures
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
