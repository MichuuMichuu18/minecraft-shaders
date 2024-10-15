#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
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
uniform ivec2 eyeBrightnessSmooth;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB8;
const int colortex3Format = RGB8;
const int colortex4Format = RGBA16;
*/

#define INFO 0 //[0 1 2 3 4]

const float ambientOcclusionLevel = 0.3;
const float sunPathRotation = -30.0f;
const int shadowMapResolution = 512; //[512 1024 2048 4096]
const int noiseTextureResolution = 64;
const float eyeBrightnessHalflife = 10.0;

const vec3 Ambient = vec3(0.12, 0.1, 0.14);
const vec3 TorchColor = vec3(0.8, 0.4, 0.25);

#include "common.glsl"
#include "sky.glsl"

const float ShadowBias = 0.002;

vec2 DistortPosition(in vec2 position){
    float CenterDistance = length(position);
    float DistortionFactor = mix(1.0f, CenterDistance, 0.9f);
    return position / DistortionFactor;
}

float AdjustLightmapTorch(in float torch) {
    const float K = 4.0;
    const float P = 3.0;
    return K * pow(torch, P);
}

float AdjustLightmapSky(in float sky){
    return pow(sky, 2.0);
}

vec2 AdjustLightmap(in vec2 Lightmap){
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);
    return NewLightMap;
}

// Input is not adjusted lightmap coordinates
vec3 GetLightmapColor(in vec2 Lightmap, in vec3 Normal){
    // First adjust the lightmap
    Lightmap = AdjustLightmap(Lightmap);
    // Multiply each part of the light map with it's color
    vec3 TorchLighting = Lightmap.x * TorchColor;
    vec3 SkyLighting = Lightmap.y * GetSkyColor(Normal, false) * (eyeBrightnessSmooth.y/255.0);
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    // Return the value
    return LightmapLighting;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - ShadowBias, texture2D(ShadowMap, SampleCoords.xy).r);
}

#include "shadow.glsl"

void main(){
    // Account for gamma correction
    vec3 Albedo = ToLinear(texture2D(colortex0, TexCoords).rgb);
    float Depth = texture2D(depthtex0, TexCoords).r;
    if(Depth == 1.0f && isEyeInWater != 1){
        gl_FragData[0] = vec4(Albedo, 1.0);
        return;
    }
    // Get the normal
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2.0 - 1.0);
    // Get the lightmap
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    vec3 LightmapColor = GetLightmapColor(Lightmap, Normal);
    // Do the lighting calculations
    vec3 NdotL = max(dot(Normal, normalize(sunPosition)), 0.0)*SunVisibility*mix(pow(SunColor, vec3(4.0)), SunColor, SunVisibility2)*2.5;
    NdotL += max(dot(Normal, normalize(-sunPosition)), 0.0)*MoonVisibility*MoonColor;
    NdotL *= 1.0-rainStrength*0.4;
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    NdotL *= Lightmap.g;
    
    if(NdotL.x > 0.01) { NdotL *= mix(vec3(GetShadow(Depth)), 0.1+(LightmapColor/2.0), rainStrength*0.6); }
    
    vec3 Diffuse = Albedo * (LightmapColor + NdotL + Ambient*(1.0+nightVision*8.0));
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}
