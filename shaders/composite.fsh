#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
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
uniform float far;
uniform float near;
uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;
uniform float frameTimeCounter;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB8;
const int colortex3Format = RGB16;
const int colortex4Format = RGBA16;
*/

const float ambientOcclusionLevel = 0.5;
const float sunPathRotation = -30.0f;
const int shadowMapResolution = 512; //[512 1024 2048 4096]
const int noiseTextureResolution = 64;
const float eyeBrightnessHalflife = 10.0;
const float wetnessHalflife = 600.0;
const float drynessHalflife = 300.0;

//const vec3 Ambient = vec3(0.145, 0.155, 0.15); // gray ambient
//const vec3 Ambient = vec3(0.13, 0.17, 0.16); // greenish blue ambient
//const vec3 Ambient = vec3(0.12, 0.1, 0.14);  // purple ambient
const vec3 Ambient = vec3(0.13, 0.11, 0.14);  // grayish purple ambient
const vec3 TorchColor = vec3(0.8, 0.35, 0.2);

#define SKY_AMBIENT_LIGHT_SAMPLING
#define SKY_REFLECTIONS
#define STARS

#include "common.glsl"
#include "sky.glsl"
#include "stars.glsl"

float AdjustLightmapTorch(in float torch) {
    return 3.0 * pow(torch, 2.0);
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
    
    float SkyCameraBrightness = (eyeBrightnessSmooth.y/255.0);
    #ifdef SKY_AMBIENT_LIGHT_SAMPLING    
    vec3 SkyAccum = vec3(0.0f);
    if(SkyCameraBrightness > 0.001){
    	float BlurSum = 0.0;
    	int Samples = 7;
    	for(int i = 0; i < Samples; ++i) {
     	    vec3 SampleCoords = VogelHemisphere(i, Samples, 0.0);
        	SkyAccum += ToLinear(GetSkyColor(SampleCoords, false));
        	BlurSum++;
    	}
    	SkyAccum /= BlurSum;
    }
    
    vec3 SkyLighting = Lightmap.y * SkyAccum * SkyCameraBrightness;
    #else
    vec3 Sky = ToLinear(GetSkyColor(vec3(0, 0, 0), false));
    vec3 SkyLighting = Lightmap.y * Sky * SkyCameraBrightness;
    #endif
    
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    // Return the value
    return LightmapLighting;
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
    vec3 NormalModelView = normalize((texture2D(colortex1, TexCoords).rgb * 2.0 - 1.0) * mat3(gbufferModelView));
    
    // Get the lightmap
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;
    vec3 LightmapColor = GetLightmapColor(Lightmap, NormalModelView);
    
    // Do the lighting calculations
    vec3 NdotL = max(dot(Normal, normalize(sunPosition)), 0.0)*SunVisibility*SunColor*3.0;
    NdotL += max(dot(Normal, normalize(-sunPosition)), 0.0)*MoonVisibility*MoonColor;
    NdotL *= 1.0-rainStrength*0.5;
    
    // Calculate shadow
    vec3 Shadow = GetShadow(Depth) * Lightmap.g;
    
    // Apply shadow
    if(Luminance(NdotL) > 0.001) {
    	NdotL *= mix(Shadow, 0.1+(LightmapColor/2.0), rainStrength*0.6);
    }
    
    vec3 Diffuse = Albedo * (LightmapColor + NdotL + Ambient*(1.0+nightVision*8.0));
    
    #ifdef SKY_REFLECTIONS
    bool isWater = Depth < texture2D(depthtex1, TexCoords).r;
    if(Lightmap.g > 0.001 || isWater) {
    	// Variables needed for reflections
    	vec3 FragmentPosition = normalize(ToScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.)));    
    	vec3 ReflectedProjectedFragmentPosition = normalize(reflect(FragmentPosition, Normal) * mat3(gbufferModelView));
    	
    	float Fresnel = clamp(1.0 + dot(Normal, FragmentPosition), 0.0, 1.0);
		float isWet = (rainStrength+wetness)/2.0;
    	
    	vec3 ReflectionColor = vec3(0.0);
    	if(isWater || isWet > 0.001) {
    		float Stars = 0.0;
			#ifdef STARS
			if(ReflectedProjectedFragmentPosition.y > 0.0) {
				vec2 StarsCoordinates = ReflectedProjectedFragmentPosition.xz/(1.0+clamp(ReflectedProjectedFragmentPosition.y, 0.0, 1.0));
				Stars = StableStarField(StarsCoordinates*500.0, 0.997)*1.0*(1.0-rainStrength)*MoonVisibility2*(ReflectedProjectedFragmentPosition.y+0.3);
			}
			#endif
			
    		ReflectionColor += ToLinear(GetSkyColor(ReflectedProjectedFragmentPosition, false)+Stars);
    		//ReflectionColor += pow(max(dot(FragmentPosition, reflect(normalize(mix(-sunPosition, sunPosition, SunVisibility2)), Normal)), 0.0), 128.0*(1.0+MoonVisibility2*2.0))*SunColor*10.0*(1.0-MoonVisibility2*0.5);
    		
    		// Compute the reflection direction
			vec3 SunDirection = normalize(mix(-sunPosition, sunPosition, SunVisibility2));
			vec3 ReflectedDirection = reflect(SunDirection, Normal);

			// Compute the specular intensity
			float SpecularFactor = max(dot(FragmentPosition, ReflectedDirection), 0.0);
			float SpecularPower = 256.0 * (1.0 + MoonVisibility2 * 1.0);
			float SpecularHighlight = pow(SpecularFactor, SpecularPower);

			// Scale by sunlight color and adjust for nighttime
			float NightFactor = (1.0 - MoonVisibility2 * 0.5);
			ReflectionColor += SpecularHighlight * SunColor * 10.0 * NightFactor * Shadow; // temporary fix - multiplying by shadow, remove that after implementing SSR.
    		
    		if(isWater) {
    			Diffuse = mix(Diffuse, ReflectionColor, Fresnel*Lightmap.g);
    		} else if(isWet > 0.001) {
    			Diffuse = mix(Diffuse, ReflectionColor, pow(Fresnel, 8.0)*wetness*Lightmap.g);
    		}
		}
	}
	#endif
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}
