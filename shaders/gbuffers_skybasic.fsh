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

#include "common.glsl"
#include "sky.glsl"

void main(){
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    
    vec4 Albedo = vec4(GetSkyColor(FragmentPosition, true), 1.0);
    
    /* DRAWBUFFERS:012 */
    // Write the values to the color textures
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
