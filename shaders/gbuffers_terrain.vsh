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
    
    vec3 Position = mat3(gl_ModelViewMatrix) * vec3(gl_Vertex) + gl_ModelViewMatrix[3].xyz;
    vec3 WorldPosition = mat3(gbufferModelViewInverse) * Position + gbufferModelViewInverse[3].xyz;
    
    if(mc_Entity.x == 4) {
    	WorldPosition += (Noise33(WorldPosition*0.3+frameTimeCounter*0.4)*2.0-1.0)*0.1;
    }
    
    if(mc_Entity.x == 6) {
    	Color.rgb *= 1.2;
    }
    
    Position = mat3(gbufferModelView) * WorldPosition + gbufferModelView[3].xyz;
    gl_Position = ToClipSpace3(Position);
}
