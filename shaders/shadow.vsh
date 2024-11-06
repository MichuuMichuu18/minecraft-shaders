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

vec3 DistortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}

void main(){
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
    Color = gl_Color;
    gl_Position.xyz = DistortShadowClipPos(gl_Position.xyz);
}
