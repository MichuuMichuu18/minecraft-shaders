#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

uniform float rainStrength;

in vec2 mc_Entity;

#include "common.glsl"

void main() {
    // Transform the vertex
    gl_Position = ftransform();
    // Assign values to varying variables
    TexCoords = gl_MultiTexCoord0.st;
    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
    Normal = gl_NormalMatrix * gl_Normal;
    Color = gl_Color;
    
    if(mc_Entity.x == 4){
    	vec3 vPosView = (gl_ModelViewMatrix * gl_Vertex).xyz;
    	vec3 vPosPlayer = mat3(gbufferModelViewInverse) * vPosView;
		vec3 worldPos = vPosPlayer + cameraPosition;
		
		worldPos += (Noise3(worldPos+frameTimeCounter*0.4)-0.05)*(0.1-0.05*rainStrength);
	
		vPosPlayer = worldPos - cameraPosition;
		vPosView = mat3(gbufferModelView) * vPosPlayer;
		gl_Position = gl_ProjectionMatrix * vec4(vPosView, 1.0);
	}
}
