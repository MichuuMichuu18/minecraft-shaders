uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

const float ShadowBias = 0.001;

#define COLORED_SHADOWS
#define WATER_SHADOW

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    return step(SampleCoords.z, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords); // with transparent objects
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords); // without transparent objects
    
    #ifdef COLORED_SHADOWS
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
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
#define SHADOW_FILTERING_SOFTNESS 2.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]

vec3 DistortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}

vec3 GetShadow(float Depth) {
    vec3 ClipSpace = vec3(TexCoords, Depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    
    #ifdef SHADOW_FILTERING
	float RandomAngle = GetIGNoise(TexCoords)*radians(360.0);
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    
    vec3 ShadowAccum = vec3(0.0f);
    float BlurSum = 0.0;
    int Samples = 16;
    for(int i = 0; i < Samples; ++i) {
        vec2 Offset = Rotation * Vogel(i, Samples, 0.0) / shadowMapResolution;
        vec4 OffsetShadowClipPos = ShadowSpace+vec4(Offset, 0.0, 0.0);
        OffsetShadowClipPos.z -= ShadowBias;
        OffsetShadowClipPos.xyz = DistortShadowClipPos(OffsetShadowClipPos.xyz);
        OffsetShadowClipPos.xyz /= OffsetShadowClipPos.w;
   		vec3 OffsetSampleCoords =OffsetShadowClipPos.xyz * 0.5f + 0.5f;
        ShadowAccum += TransparentShadow(OffsetSampleCoords);
        BlurSum++;
    }
    ShadowAccum /= BlurSum;
    
    return ShadowAccum;
    #else
    vec4 ShadowClipPos = ShadowSpace;
    ShadowClipPos.z -= ShadowBias;
    ShadowClipPos.xyz = DistortShadowClipPos(ShadowClipPos.xyz);
    ShadowClipPos.xyz /= ShadowClipPos.w;
   	vec3 SampleCoords = ShadowClipPos.xyz * 0.5f + 0.5f;
    return TransparentShadow(SampleCoords);
    #endif
}
