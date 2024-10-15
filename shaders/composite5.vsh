#version 120

varying vec4 TexCoords;
flat varying vec3 GlowColor;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;
uniform vec2 texelSize;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform float rainStrength;
uniform float aspectRatio;

#include "sky.glsl"

//#define SUN_GLOW

void main() {	
	#ifdef SUN_GLOW
	vec4 SunPosition = vec4(sunPosition, 1.0) * gbufferProjection;
    SunPosition = vec4(SunPosition.xyz/SunPosition.w, 1.0);
    vec2 SunPositionOnScreen = (SunPosition.xy/SunPosition.z)*0.5+0.5;
    vec2 SunMeanCenter = vec2(0.0);
    float Pi = 6.28318530718; // PI*2
    float SunVisibilitySum = 0.0;
    
    for(float x = Pi/12.0; x <= Pi; x+=Pi/12.0){
        for(float y = 0.0; y <= 10.0; y += 1.0){
            vec2 Offset = vec2(cos(x),sin(x))*texelSize*y;
            vec2 SunPositionBlur = SunPositionOnScreen+Offset;
            float SunVisibility = texture2D(depthtex0, SunPositionBlur).r < 1.0 ? 0.0 : 0.1;
            SunVisibilitySum += SunVisibility;
            SunMeanCenter += SunVisibility*SunPositionBlur;
   		}
    }
    
    if (SunVisibilitySum > 0.0) { SunMeanCenter /= SunVisibilitySum; }
    else { SunMeanCenter =  SunPositionOnScreen; }
    
    gl_Position = ftransform();
	TexCoords = vec4(gl_MultiTexCoord0.st, SunMeanCenter);
    
    float Daytime = 2.0-(sign(sunPosition.z)+1.0);
    GlowColor = SunColor*SunVisibilitySum*Daytime+MoonColor*SunVisibilitySum*0.2*(1.0-Daytime);
    #else
    TexCoords = vec4(gl_MultiTexCoord0.st, 0.0, 0.0);
    #endif
}
