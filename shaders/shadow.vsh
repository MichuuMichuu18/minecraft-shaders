#version 120


varying vec2 TexCoords;
varying vec4 Color;

uniform sampler2D noisetex;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec2 mc_Entity;

#include "common.glsl"

vec2 DistortPosition(in vec2 position){
    float CenterDistance = length(position);
    float DistortionFactor = mix(1.0f, CenterDistance, 0.9f);
    return position / DistortionFactor;
}

void main(){
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;
    
    vec3 Position = mat3(gl_ModelViewMatrix) * vec3(gl_Vertex) + gl_ModelViewMatrix[3].xyz;
    vec3 WorldPosition = mat3(shadowModelViewInverse) * Position + shadowModelViewInverse[3].xyz;
    
    if(mc_Entity.x == 4) {
    	WorldPosition += (Noise3(WorldPosition*0.3+frameTimeCounter*0.4)*2.0-1.0)*0.1;
    }
    
    if(mc_Entity.x == 6) {
    	Color.rgb *= 1.2;
    }
    
    Position = mat3(shadowModelView) * WorldPosition + shadowModelView[3].xyz;
    gl_Position.xy = DistortPosition(ToClipSpace3(Position).xy);
}
