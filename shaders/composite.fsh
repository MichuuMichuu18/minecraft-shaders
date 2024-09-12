#version 120

#include "distort.glsl"

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

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

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex3Format = RGB8;
const int colortex4Format = RGBA16;
*/

#define INFO 0 //[0 1 2 3 4]

const float ambientOcclusionLevel = 0.3;
const float sunPathRotation = -30.0f;
const int shadowMapResolution = 512; //[512 1024 2048 4096]
const int noiseTextureResolution = 64;
const float eyeBrightnessHalflife = 20.0;

const vec3 Ambient = vec3(0.02, 0.04, 0.06);
const vec3 TorchColor = vec3(1.0, 0.3, 0.05);

#include "common.glsl"
#include "sky.glsl"

const float ShadowBias = 0.001;

float AdjustLightmapTorch(in float torch) {
    const float K = 3.0;
    const float P = 3.0;
    return K * pow(torch, P);
}

float AdjustLightmapSky(in float sky){
    return pow(sky, 5.0);
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
    vec3 SkyLighting = Lightmap.y * GetSkyColor(Normal, false);
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    // Return the value
    return LightmapLighting;
}

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z - ShadowBias, texture2D(ShadowMap, SampleCoords.xy).r);
}

#define COLORED_SHADOWS
#define WATER_SHADOW

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords); // with transparent objects
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords); // without transparent objects
    
    #ifdef COLORED_SHADOWS
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    ShadowColor0.rgb = mix(vec3(Luminance(ShadowColor0.rgb)), ShadowColor0.rgb, 2.0);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0f - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
    #else
    #ifdef WATER_SHADOW
    return vec3(ShadowVisibility0);
    #else
    return vec3(ShadowVisibility1);
    #endif
    #endif
}

//#define SHADOW_FILTERING
#define SHADOW_FILTERING_QUALITY 1.0 //[1.0 2.0 3.0]
#define SHADOW_FILTERING_STEPS 1.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
#define SHADOW_FILTERING_STEPS_MULTIPLIER 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define SHADOW_FILTERING_DIRECTIONS 3.0 //[3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0]

vec3 GetShadow(float depth) {
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    #ifdef SHADOW_FILTERING
	float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
    vec3 ShadowAccum = vec3(0.0f);
    float pi = 6.28318530718; // PI*2
    float blurSum = 0.0;
    for(float x = 0; x <= pi; x+=pi/SHADOW_FILTERING_DIRECTIONS){
        for(float y = 1.0/SHADOW_FILTERING_QUALITY; y <= SHADOW_FILTERING_STEPS; y+= 1.0/SHADOW_FILTERING_QUALITY){
            vec2 Offset = Rotation * vec2(cos(x),sin(x))*SHADOW_FILTERING_STEPS_MULTIPLIER*y*(shadowMapResolution/512.0);
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
            blurSum += 1.0;
        }
    }
    ShadowAccum /= blurSum;
    return ShadowAccum;
    #else
    return TransparentShadow(SampleCoords);
    #endif
}

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
    vec3 NdotL = max(dot(Normal, normalize(sunPosition)), 0.0)*SunVisibility*mix(pow(SunColor, vec3(4.0)), SunColor, SunVisibility2);
    NdotL += max(dot(Normal, normalize(-sunPosition)), 0.0)*MoonVisibility*MoonColor;
    NdotL *= 1.7;
    vec3 FragmentPosition = ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)) * mat3(gbufferModelView);
    NdotL *= (Luminance(GetSkyColor(FragmentPosition, false))+0.2);
    NdotL *= Lightmap.g;
    
    vec3 Shadow = mix(vec3(GetShadow(Depth)), 0.1+(LightmapColor/2.0), rainStrength*0.5);
    vec3 Diffuse = Albedo * (LightmapColor + NdotL * Shadow + Ambient*(1.0+nightVision*8.0));
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}
