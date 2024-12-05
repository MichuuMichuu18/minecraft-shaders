#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec4 Normal;
varying vec4 Color;

// The texture atlas
uniform sampler2D texture;

uniform sampler2D colortex4;

uniform sampler2D noisetex;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec2 texelSize;
uniform float rainStrength;
uniform float nightVision;
uniform float frameTimeCounter;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

void main(){
    // Sample from texture atlas and account for biome color + ambient occlusion
    vec4 Albedo = texture2D(texture, TexCoords) * Color;
    
    if(Normal.a > 0.5) {
    	Albedo = vec4(0.1, 0.3, 0.5, 0.7);
    }
    
    /* DRAWBUFFERS:012 */
    // Write the values to the color textures
    gl_FragData[0] = Albedo;
    gl_FragData[1] = vec4(Normal.rgb * 0.5f + 0.5f, 1.0f);
    gl_FragData[2] = vec4(LightmapCoords, 0.0f, 1.0f);
}
