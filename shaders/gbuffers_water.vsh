#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec4 Normal;
varying vec4 Color;

in vec2 mc_Entity;

void main() {
    // Transform the vertex
    gl_Position = ftransform();
    // Assign values to varying variables
    TexCoords = gl_MultiTexCoord0.st;
    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
    Normal = vec4(gl_NormalMatrix * gl_Normal, 0.0);
    Color = gl_Color;
    
    if(mc_Entity.x == 1) Normal.a = 1.0;
}
