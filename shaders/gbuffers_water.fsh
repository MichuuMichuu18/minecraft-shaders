#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;

// The texture atlas
uniform sampler2D texture;

uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec2 texelSize;
uniform float rainStrength;
uniform float nightVision;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

#include "common.glsl"
#include "sky.glsl"

void main(){
    // Sample from texture atlas and account for biome color + ambient occlusion
    vec4 Albedo = texture2D(texture, TexCoords) * Color;
    
    //vec3 FragmentPosition = ToScreenSpace(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    
    //Albedo.rgb = mix(Albedo.rgb, ToLinear(GetSkyColor(-normalize(FragmentPosition), true)), 1.0);
    
    /* DRAWBUFFERS:012 */
    // Write the values to the color textures
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
