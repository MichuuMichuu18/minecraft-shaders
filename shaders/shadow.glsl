uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

#define COLORED_SHADOWS
#define WATER_SHADOW

vec3 TransparentShadow(in vec3 SampleCoords){
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords); // with transparent objects
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords); // without transparent objects
    
    #ifdef COLORED_SHADOWS
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    ShadowColor0.rgb = mix(vec3(Luminance(ShadowColor0.rgb)), ShadowColor0.rgb, 2.0);
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
#define SHADOW_FILTERING_STEPS 1.0 //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
#define SHADOW_FILTERING_STEPS_MULTIPLIER 1.0 //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define SHADOW_FILTERING_DIRECTIONS 3.0 //[3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0]

vec3 GetShadow(float Depth) {
    vec3 ClipSpace = vec3(TexCoords, Depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    #ifdef SHADOW_FILTERING
	float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
	float sinTheta = sin(RandomAngle);
    mat2 Rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; 
    vec3 ShadowAccum = vec3(0.0f);
    float Pi = 6.28318530718; // PI*2
    float BlurSum = 0.0;
    for(float x = 0; x <= Pi; x+=Pi/SHADOW_FILTERING_DIRECTIONS){
        for(float y = 1.0/SHADOW_FILTERING_QUALITY; y <= SHADOW_FILTERING_STEPS; y+= 1.0/SHADOW_FILTERING_QUALITY){
            vec2 Offset = Rotation * vec2(cos(x),sin(x))*SHADOW_FILTERING_STEPS_MULTIPLIER*y;
            vec3 CurrentSampleCoordinate = SampleCoords+vec3(Offset, 0.0);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
            BlurSum += 1.0;
        }
    }
    ShadowAccum /= BlurSum;
    return ShadowAccum;
    #else
    return TransparentShadow(SampleCoords);
    #endif
}
