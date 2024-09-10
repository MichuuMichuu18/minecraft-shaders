#version 120

varying vec2 TexCoords;

uniform sampler2D colortex0;

uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;

#include "common.glsl"

//#define FXAA

void main(){
    vec3 Albedo = vec3(0.0);
    
    #ifdef FXAA
    float FXAA_SPAN_MAX   = 8.0;
	float FXAA_REDUCE_MUL = 1.0 / 8.0;
	float FXAA_REDUCE_MIN = 1.0 / 128.0;

	// 1st stage - Find edge
	vec3 rgbNW = texture2D(colortex0, TexCoords + vec2(-1.0/viewWidth, 1.0/viewHeight)).rgb;
	vec3 rgbNE = texture2D(colortex0, TexCoords + vec2(1.0/viewWidth, 1.0/viewHeight)).rgb;
	vec3 rgbSW = texture2D(colortex0, TexCoords + vec2(-1.0/viewWidth, -1.0/viewHeight)).rgb;
	vec3 rgbSE = texture2D(colortex0, TexCoords + vec2(1.0/viewWidth, -1.0/viewHeight)).rgb;
	vec3 rgbM  = texture2D(colortex0, TexCoords).rgb;

	float lumaNW = Luminance(rgbNW);
	float lumaNE = Luminance(rgbNE);
	float lumaSW = Luminance(rgbSW);
	float lumaSE = Luminance(rgbSE);
	float lumaM  = Luminance(rgbM);

	vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	float lumaSum   = lumaNW + lumaNE + lumaSW + lumaSE;
	float dirReduce = max(lumaSum * (0.5 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
	float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);

	dir = min(vec2(FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX), dir * rcpDirMin)) / vec2(viewWidth, viewHeight)*0.5;

	// 2nd stage - Blur
	vec3 rgbA = 0.5 * (texture2D(colortex0, TexCoords + dir * (1.0/3.0 - 0.5)).rgb +
										texture2D(colortex0, TexCoords + dir * (2.0/3.0 - 0.5)).rgb);
	vec3 rgbB = rgbA * 0.5 + 0.25 * (
										texture2D(colortex0, TexCoords + dir * (0.0/3.0 - 0.5)).rgb +
										texture2D(colortex0, TexCoords + dir * (3.0/3.0 - 0.5)).rgb);

	float lumaB = Luminance(rgbB);

	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

	Albedo = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
	
    #else
	Albedo = texture2D(colortex0, TexCoords).rgb;
    #endif
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(Albedo, 1.0);
}
