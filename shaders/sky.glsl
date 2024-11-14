const vec3 SunColor = vec3(1.0, 0.85, 0.6);
const vec3 MoonColor = vec3(0.13, 0.16, 0.21);

vec3 SunDirection = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);
float SunVisibility = clamp((dot(normalize(sunPosition), upPosition) + 0.5) * 0.025, 0.0, 1.0);
float SunVisibility2 = clamp((dot(normalize(sunPosition), upPosition) + 10.0) * 0.1, 0.0, 1.0);
float MoonVisibility = 1.0-SunVisibility;
float MoonVisibility2 = 1.0-SunVisibility2;

#define DRAW_SUN
//#define DRAW_MOON

#define PI 3.14159265359

#define RayleighCoefficient vec3(0.25,0.45,0.95)
#define MieCoefficient mix(0.2, 1.0, rainStrength)
#define MieMultiscatterRadius mix(0.05, 1.0, rainStrength)
#define EarthRadius 128.0
#define AtmosphereRadius 0.5

#define r(x,x2,y)(x*y+x2*y)					// Reflects incoming light
#define a(x,x2,y)exp2(-r(x,x2,y))			// Absorbs incoming light
#define d(x)abs(x+1.0e-32)					// Fixes divide by zero infinites
#define sA(x,y,z,w)d(x-y)/d(z-w)			// Absorbs scattered light
#define scatter(x,y,z,w,s)sA(x,y,z,w)*s		// Scatters reflected light

// Calculates the distance between the camera and the edge of the atmosphere
float GetDepth(float x){
	const float d2 = EarthRadius+AtmosphereRadius;
	const float EarthRadius2 = EarthRadius*EarthRadius;
	float b=-2.0*(x*EarthRadius)+EarthRadius;
	return sqrt(d2*d2+b*b-EarthRadius2)+b;
}

// Rayleigh phase function
float RayleighPhase(float x){
	return 0.75*(x*x+1.0);
}

// Henyey greenstein phase function
float GreensteinPhase(float x,float g){
	float g2 = g*g;
	return (3.0/8.0*PI)*((1.0-g2)/pow(1.0+g2-2.0*g*x, 1.5));
}

// Mie phase function
float MiePhase(float x,float d2){
	return GreensteinPhase(x,exp2(d2*-MieMultiscatterRadius));
}

// Calculates sunspot
float CalculateSunSpot(float x, float sunSize){
	return smoothstep(sunSize, sunSize+(1.0-sunSize), x);
}

vec3 CalculateAtmosphericScattering(vec3 p, vec3 lp, float intensity, bool renderSunSpot, float SunSize){
	float lDotV = 1.0-distance(p, lp); // float lDotV = dot(l, v);

	float OpticalDepth    = GetDepth(p.y);	// Get depth from viewpoint
	float OpticalSunDepth = GetDepth(lp.y);	// Get depth from lightpoint

	float PhaseRayleigh = RayleighPhase(lDotV);		// Rayleigh Phase
	float PhaseMie = MiePhase(lDotV, OpticalDepth);	// Mie Phase

	vec3 SunAbsorb    = a(RayleighCoefficient, MieCoefficient*intensity, OpticalSunDepth);
	vec3 ViewAbsorb   = a(RayleighCoefficient, MieCoefficient, OpticalDepth);
	vec3 SunCoeff     = r(RayleighCoefficient, MieCoefficient*intensity, OpticalSunDepth);
	vec3 ViewCoeff    = r(RayleighCoefficient, MieCoefficient, OpticalDepth);
	vec3 ViewScatter  = r(RayleighCoefficient * PhaseRayleigh, MieCoefficient * PhaseMie, OpticalDepth*intensity*5.0);

	vec3 FinalScatter = scatter(SunAbsorb, ViewAbsorb, SunCoeff, ViewCoeff, ViewScatter); // Scatters all sunlight

	vec3 SunSpot = (CalculateSunSpot(lDotV, SunSize) * ViewAbsorb) * 50.0; // Sunspot

	if(renderSunSpot) { return FinalScatter + SunSpot; }
	else { return FinalScatter; }
}

vec3 GetSkyColor(vec3 p, bool drawCircles){
	//vec3 DaySky = mix(mix( vec3(0.8, 0.9, 1.0), vec3(0.5, 0.7, 1.0), p.y*0.5+0.5), mix(vec3(0.5, 0.7, 1.0), vec3(0.25, 0.4, 0.6), p.y*0.5+0.5), p.y*0.5+0.5);
	//vec3 SunsetSky = mix(mix(vec3(1.0, 0.7, 0.4),  vec3(1.0, 0.3, 0.0), p.y*0.5+0.5), mix(vec3(1.0, 0.3, 0.0), vec3(0.25, 0.25, 0.3), p.y*0.5+0.5), p.y*0.5+0.5);
	//vec3 NightSky = mix(vec3(0.28, 0.31, 0.33), vec3(0.15, 0.18, 0.2), pow(p.y*0.5+0.6, 3.0))*(1.0+nightVision);
	//vec3 Sky = mix(NightSky, DaySky, SunVisibility2);//mix(mix(NightSky, SunsetSky, SunVisibility), mix(SunsetSky, DaySky, SunVisibility), SunVisibility2);
	
	//Sky *= 1.0-rainStrength*0.35;
	//Sky = mix(Sky, vec3(Luminance(Sky)), rainStrength*0.8);
	
	float dayIntensity = 1.0;
	float nightIntensity = 0.1;
	
	float sunSize = 0.98;
	float moonSize = 0.967;
	
	//////////////////////////////////////////
	
	vec3 DaySky = vec3(0.0);
	vec3 NightSky = vec3(0.0);
	
	vec3 AdjustedPosition = p*0.5+0.55;
	
	if(drawCircles){
		#ifdef DRAW_SUN
		DaySky = CalculateAtmosphericScattering(AdjustedPosition, SunDirection*0.5+0.55, dayIntensity, true, sunSize);
		#else
		DaySky = CalculateAtmosphericScattering(AdjustedPosition, SunDirection*0.5+0.55, dayIntensity, false, sunSize);
		#endif
		
		#ifdef DRAW_MOON
		NightSky = CalculateAtmosphericScattering(AdjustedPosition, (-SunDirection)*0.5+0.55, nightIntensity, true, moonSize);
		#else
		NightSky = CalculateAtmosphericScattering(AdjustedPosition, (-SunDirection)*0.5+0.55, nightIntensity, false, moonSize);
		#endif
	} else {
		NightSky = CalculateAtmosphericScattering(AdjustedPosition, (-SunDirection)*0.5+0.55, nightIntensity, false, 0.967);
		DaySky = CalculateAtmosphericScattering(AdjustedPosition, SunDirection*0.5+0.55, dayIntensity, false, sunSize);
	}
	
	vec3 Sky = mix(NightSky, DaySky, SunVisibility2);
	Sky = Sky/(1.0+Sky); // Additional tonemapping needed
	
	return clamp(Sky, 0.0, 1.0);
}
