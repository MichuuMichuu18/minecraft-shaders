// Original star code: https://www.shadertoy.com/view/Md2SR3, using different hash function

// Convert Noise2d() into a "star field" by stomping everthing below fThreshhold to zero.
float NoisyStarField( in vec2 vSamplePos, float fThreshhold )
{
    float StarVal = Hash2( vSamplePos );
        StarVal = clamp(StarVal/(1.0 - fThreshhold) - fThreshhold/(1.0 - fThreshhold),0.0,1.0);

    return StarVal;
}

// Stabilize NoisyStarField() by only sampling at integer values.
float StableStarField( in vec2 vSamplePos, float fThreshhold )
{
    // Linear interpolation between four samples.
    // Note: This approach has some visual artifacts.
    // There must be a better way to "anti alias" the star field.
    float fractX = fract( vSamplePos.x );
    float fractY = fract( vSamplePos.y );
    vec2 floorSample = floor( vSamplePos );
    float v1 = NoisyStarField( floorSample, fThreshhold );
    float v2 = NoisyStarField( floorSample + vec2( 0.0, 1.0 ), fThreshhold );
    float v3 = NoisyStarField( floorSample + vec2( 1.0, 0.0 ), fThreshhold );
    float v4 = NoisyStarField( floorSample + vec2( 1.0, 1.0 ), fThreshhold );

    float StarVal =   v1 * ( 1.0 - fractX ) * ( 1.0 - fractY )
        			+ v2 * ( 1.0 - fractX ) * fractY
        			+ v3 * fractX * ( 1.0 - fractY )
        			+ v4 * fractX * fractY;
	return StarVal;
}
