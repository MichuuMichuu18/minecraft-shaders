#version 120

#include "distort.glsl"

varying vec4 TexCoords;
flat varying vec3 GlowColor;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform int isEyeInWater;
uniform float rainStrength;
uniform vec3 upPosition;
uniform vec3 skyColor;
uniform vec2 texelSize;
uniform float nightVision;
uniform float aspectRatio;

#include "common.glsl"

//#define SUN_GLOW

void main(){
    vec3 Albedo = texture2D(colortex0, TexCoords.xy).rgb;
    
    #ifdef SUN_GLOW
    vec2 FinalSunPosition = (TexCoords.zw - TexCoords.xy)/(vec2(1.0, aspectRatio)*0.01);
    Albedo += (1.0-rainStrength*0.97)*GlowColor*(1.0/(1.0+dot(FinalSunPosition, FinalSunPosition)));
    #endif
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Albedo, 1.0f);
}
