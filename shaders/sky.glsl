//TODO: restore sky.glsl partially from 02.11.2024 backup

const vec3 SunColor = vec3(1.0, 0.7, 0.3);
const vec3 MoonColor = vec3(0.27, 0.24, 0.3);

vec3 SunDirection = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);
float SunVisibility = clamp((dot(normalize(sunPosition), upPosition) + 0.5) * 0.05, 0.0, 1.0);
float SunVisibility2 = clamp((dot(normalize(sunPosition), upPosition) + 10.0) * 0.1, 0.0, 1.0);
float MoonVisibility = 1.0-SunVisibility;
float MoonVisibility2 = 1.0-SunVisibility2;

vec3 GetSkyColor(vec3 p){
	vec3 DaySky = mix(mix( vec3(0.8, 0.9, 1.0), vec3(0.5, 0.7, 1.0), p.y*0.5+0.5), mix(vec3(0.5, 0.7, 1.0), vec3(0.25, 0.45, 0.6), p.y*0.5+0.5), p.y*0.5+0.5);
	vec3 SunsetSky = mix(mix(vec3(1.0, 0.7, 0.4),  vec3(1.0, 0.3, 0.0), p.y*0.5+0.5), mix(vec3(1.0, 0.3, 0.0), vec3(0.25, 0.25, 0.3), p.y*0.5+0.5), p.y*0.5+0.5);
	vec3 NightSky = vec3(0.19, 0.18, 0.2)*(1.0+nightVision);

	vec3 Sky = mix(mix(NightSky, SunsetSky, SunVisibility), mix(SunsetSky, DaySky, SunVisibility), SunVisibility2);
	
	Sky *= 1.0-rainStrength*0.35;
	Sky = mix(Sky, vec3(Luminance(Sky)), rainStrength*0.8);
	
	float SunFdotS = dot(p, normalize(SunDirection));
	float MoonFdotS = 1.0-SunFdotS;
	
	Sky += pow(clamp(SunFdotS, 0.0, 1.0), 1.7)*0.2*SunVisibility*mix(pow(SunColor, vec3(4.0)), SunColor, SunVisibility2);
	Sky += pow(clamp(MoonFdotS, 0.0, 1.0), 2.0)*0.1*(1.0-SunVisibility)*MoonColor;
	
	return Sky;
}
