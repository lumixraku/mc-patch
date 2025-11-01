#version 120

/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

#define WAVY_STUFF		//disable and gain some more fps

#define ENTITY_LEAVES        18.0
#define ENTITY_VINES        106.0
#define ENTITY_TALLGRASS     31.0
#define ENTITY_DANDELION     37.0
#define ENTITY_ROSE          38.0
#define ENTITY_WHEAT         59.0
#define ENTITY_LILYPAD      111.0
#define ENTITY_FIRE          51.0
#define ENTITY_LAVAFLOWING   10.0
#define ENTITY_LAVASTILL     11.0

varying vec4 color;
varying vec2 texcoord;

varying vec4 ambientNdotL;
varying vec4 sunlightMat;


attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;
const float PI48 = 150.796447372;
float pi2wt = PI48*frameTimeCounter;
uniform int heldBlockLightValue;

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {

    float magnitude = sin(dot(vec4(pi2wt*fm, pos.x, pos.z, pos.y),vec4(0.5))) * mm + ma;
	vec3 d012 = sin(pi2wt*vec3(f0,f1,f2));
	vec3 ret = sin(pi2wt*vec3(f3,f4,f5) + vec3(d012.x + d012.y,d012.y + d012.z,d012.z + d012.x) - pos) * magnitude;
	
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0054, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.07, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}


const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.005),
								vec3(0.58597,0.31,0.08),
								vec3(0.58597,0.45,0.16),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));
								
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {


	bool istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t;
	
	
	//optimisation to get only one comparison to do per waving move
	vec4 idtest = vec4(ENTITY_TALLGRASS,ENTITY_DANDELION,ENTITY_ROSE,ENTITY_WHEAT)-mc_Entity.x;
	bool wavy1 = idtest.x*idtest.y*idtest.z*idtest.w == 0.0;
	
	vec2 id2 = vec2(161.0,ENTITY_LEAVES)-mc_Entity.x;
	bool wavy2 = id2.x*id2.y == 0.0;
	
	
	idtest = vec4(50.0,62.0,76.0,89.0)-mc_Entity.x;
	bool emissive = idtest.x*idtest.y*idtest.z*idtest.w == 0.0;
	
	idtest = vec4(141.0,142.0,175.0,106.0)-mc_Entity.x;
	
	bool mat = idtest.x*idtest.y*idtest.z*idtest.w == 0.0;
	color = (emissive? vec4(1.0) : gl_Color);
	




		
	gl_Position = ftransform();

	/*--------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = mix(temp,temp2,fract(hour));
	const vec3 rainC = vec3(0.01,0.01,0.01);
	sunlight = mix(sunlight,rainC*sunlight,rainStrength);
	
	texcoord = (gl_MultiTexCoord0).xy;

	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	

	

	float skyL = lmcoord.t*1.03225806452-0.5/16.0*1.03225806452;
	/*
	const float fact = 15.0;
	float modlmap = 15.5-min(lmcoord.s*16.,14.5); 
	float torch_lightmap = 1.0/modlmap/modlmap-1.0/fact/fact;

*/
	float torch_lightmap = 16.0-min(15.,(lmcoord.s-0.5/16.)*16.*16./15);


	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	const vec3 moonlight = vec3(0.5, 0.9, 1.4) * 0.002;

	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);


	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));

	float NdotL = dot(normal,normalize(sunPosition));
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = clamp(min(trCalc.x,trCalc.y)/375.0-1.0,0.0,1.0);
	visibility = clamp(visibility/0.15+1.0,0.0,1.0);
	visibility *= visibility;
	visibility *= visibility;

	
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);


	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.33,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);

	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);


	vec3 sun_ambient = bounced.w * (vec3(0.1, 0.5, 1.1)*2.4+rainStrength*2.3*vec3(0.05,-0.33,-0.9))+ 1.6*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.99);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(4.0-rainStrength*0.95*4.0);


	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03*0.65+tr*0.17*0.65);
	ambientNdotL.rgb =  amb1 + vec3(1.0,0.42,0.045)*torch_lightmap*0.66 + 0.002*min(skyL+6/16.,9/16.)*normalize(amb1+0.0001);



	



	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;
	
	sunlightMat = vec4(sunlight*skyL,0.0);		//due to forward shading limitation we have to multiply sunlight by sky visibility in order to make underwater look acceptable

	ambientNdotL.a = (worldTime > 12700 && worldTime < 23250)? -NdotL : NdotL;
		
	ambientNdotL.a = clamp(ambientNdotL.a,0.0,1.0);
	
	if (mat || wavy1 || wavy2) {
		mat = true;
		ambientNdotL.a = abs(dot(sunVec,upVec))*0.25+NdotL*0.25+0.5;
		sunlightMat.a = 1.0;
		color *= vec4(1.17,1.17,1.17,1.0);	
		#ifdef WAVY_STUFF
		if ((istopv && wavy1) || wavy2){
			vec4 position = gl_ModelViewMatrix * gl_Vertex;
			position = gbufferModelViewInverse * position;
			vec3 worldpos = position.xyz + cameraPosition;
			position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5))*1.4;
			position = gbufferModelView * position;	
			gl_Position = gl_ProjectionMatrix * position;
		}
		#endif
		
	}

	


}