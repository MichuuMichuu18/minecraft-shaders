const vec3 SunColor = vec3(1.0, 0.7, 0.3);
const vec3 MoonColor = vec3(0.4, 0.47, 0.5);

#define DRAW_SUN

vec3 SunDirection = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);
float SunVisibility = clamp((dot(SunDirection, upPosition) + 0.5) * 0.05, 0.0, 1.0);
float SunVisibility2 = clamp((dot(SunDirection, upPosition) + 10.0) * 0.1, 0.0, 1.0);
float MoonVisibility = 1.0-SunVisibility;

vec3 GetSkyColor(vec3 p, bool drawSun){    
	//vec3 Sky = mix(vec3(0.38, 0.49, 0.6), vec3(0.5, 0.7, 0.9), p.y*0.5+0.5);
	//vec3 Sky = mix(mix(vec3(1,0,0), vec3(0,1,0), p.y*0.5+0.5), mix(vec3(0,1,0), vec3(0,0,1), p.y*0.5+0.5), p.y*0.5+0.5);
	vec3 Sky = mix(mix( vec3(0.8, 0.9, 1.0),  vec3(0.5, 0.7, 1.0), p.y*0.5+0.5), mix(vec3(0.5, 0.7, 1.0), vec3(0.25, 0.45, 0.6), p.y*0.5+0.5), p.y*0.5+0.5);
	//Sky = mix(vec3(0.09, 0.07, 0.17), Sky, SunVisibility);
	
	//vec3 SunsetSky = mix(vec3(1.0,0.4,0.1), Sky, p.y*0.5+0.5);
	vec3 SunsetSky = mix(mix(vec3(1.0, 0.7, 0.4),  vec3(1.0, 0.3, 0.0), p.y*0.5+0.5), mix(vec3(1.0, 0.3, 0.0), vec3(0.25, 0.25, 0.3), p.y*0.5+0.5), p.y*0.5+0.5);

	Sky = mix(mix(vec3(0.10, 0.09, 0.14)*(1.0+nightVision), SunsetSky, SunVisibility), mix(SunsetSky, Sky, SunVisibility), SunVisibility2);
	
	Sky *= 1.0-rainStrength*0.4;
	Sky = mix(Sky, vec3(Luminance(Sky)), rainStrength*0.7);
	
	float SunFdotS = dot(p, normalize(SunDirection));
	float MoonFdotS = dot(p, normalize(-SunDirection));
	
	#ifdef DRAW_SUN
	if (drawSun){
		Sky += pow(clamp(SunFdotS+0.0009, 0.0, 1.0), 20000.0)*(1.0-rainStrength*0.9)*SunColor*2.0;
	}
	#endif
	
	Sky += pow(clamp(SunFdotS, 0.0, 1.0), 1.7)*0.2*SunVisibility*mix(pow(SunColor, vec3(4.0)), SunColor, SunVisibility2);
	Sky += pow(clamp(MoonFdotS, 0.0, 1.0), 3.0)*0.1*(1.0-SunVisibility)*MoonColor;
	
	return Sky;
}
