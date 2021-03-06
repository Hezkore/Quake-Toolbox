
//@renderpasses 1,2

//material uniforms

uniform mat3 m_TextureMatrix;

//renderer uniforms...

uniform mat4 r_ModelViewMatrix;
uniform mat4 r_ModelViewProjectionMatrix;
uniform mat3 r_ModelViewNormalMatrix;

#if MX2_RENDERPASS==1

uniform vec4 r_AmbientDiffuse;
uniform samplerCube r_EnvTexture;
uniform mat3 r_EnvMatrix;

//pbr varyings...

varying vec3 v_Position;
varying vec2 v_TexCoord0;
varying vec2 v_TexCoord1;
varying vec3 v_Normal;
varying mat3 v_TanMatrix;

#endif

//@vertex

//vertex attribs....

attribute vec4 a_Position;

#if MX2_RENDERPASS==1 

attribute vec2 a_TexCoord0;
attribute vec2 a_TexCoord1;
attribute vec3 a_Normal;
attribute vec4 a_Tangent;

#endif

void main(){

#if MX2_RENDERPASS==1

	// texture coord0
	v_TexCoord0=(m_TextureMatrix * vec3(a_TexCoord0,1.0)).st;

	// texture coord1
	v_TexCoord1=(m_TextureMatrix * vec3(a_TexCoord1,1.0)).st;

	// view space position
	v_Position=( r_ModelViewMatrix * a_Position ).xyz;

	// viewspace normal
	v_Normal=r_ModelViewNormalMatrix * a_Normal;
	
	// viewspace tangent matrix
	v_TanMatrix[2]=v_Normal;
	v_TanMatrix[0]=r_ModelViewNormalMatrix * a_Tangent.xyz;
	v_TanMatrix[1]=cross( v_TanMatrix[0],v_TanMatrix[2] ) * a_Tangent.a;
	
#endif
	
	gl_Position=r_ModelViewProjectionMatrix * a_Position;
}

//@fragment

#if MX2_RENDERPASS==1

void main0( vec3 color,vec3 emissive,vec3 lightmap,float metalness,float roughness,float occlusion,vec3 normal ){

	normal=normalize( v_TanMatrix * normal );

	vec3 color0=vec3( 0.04,0.04,0.04 );
	
	vec3 diffuse=color * (1.0-metalness);
	
	vec3 specular=(color-color0) * metalness + color0;
	
	vec3 rvec=r_EnvMatrix * reflect( v_Position,normal );
	
	float lod=textureCube( r_EnvTexture,rvec,10.0 ).a * 255.0 - 10.0;
	
	if( lod>0.0 ) lod=textureCube( r_EnvTexture,rvec ).a * 255.0;
	
	vec3 env=pow( textureCube( r_EnvTexture,rvec,max( roughness*10.0-lod,0.0 ) ).rgb,vec3( 2.2 ) );

	vec3 vvec=normalize( -v_Position );
	
	float ndotv=max( dot( normal,vvec ),0.0 );
	
	vec3 fschlick=specular + (1.0-specular) * pow( 1.0-ndotv,5.0 ) * (1.0-roughness);

	vec3 ambdiff=diffuse * r_AmbientDiffuse.rgb;
		
	vec3 ambspec=env * fschlick;

	gl_FragData[0]=vec4( min( (ambdiff+ambspec) * occlusion + emissive,8.0 ),1.0 );

	gl_FragData[1]=vec4( color,metalness );
	
	gl_FragData[2]=vec4( normal * 0.5 + 0.5,roughness );
}

#endif

#if MX2_RENDERPASS==1

uniform sampler2D m_ColorTexture;
uniform vec4 m_ColorFactor;

uniform sampler2D m_EmissiveTexture;
uniform vec4 m_EmissiveFactor;

uniform sampler2D m_LightmapTexture;

uniform sampler2D m_MetalnessTexture;
uniform float m_MetalnessFactor;

uniform sampler2D m_RoughnessTexture;
uniform float m_RoughnessFactor;

uniform sampler2D m_OcclusionTexture;

uniform sampler2D m_NormalTexture;

uniform float m_UseMask;

#endif

void main(){

#if MX2_RENDERPASS==1

	if(m_UseMask > 0.5 && texture2D( m_EmissiveTexture,v_TexCoord0 ).a < 0.5) discard;

	vec3 color=pow( texture2D( m_ColorTexture,v_TexCoord0 ).rgb,vec3( 2.2 ) ) * m_ColorFactor.rgb;
	
	vec3 lightmap=texture2D( m_LightmapTexture,v_TexCoord1 ).rgb;

	vec3 emissive=pow( texture2D( m_EmissiveTexture,v_TexCoord0 ).rgb,vec3( 2.2 ) ) * m_EmissiveFactor.rgb;
	
	float metalness=texture2D( m_MetalnessTexture,v_TexCoord0 ).b * m_MetalnessFactor;
	
	float roughness=texture2D( m_RoughnessTexture,v_TexCoord0 ).g * m_RoughnessFactor;
	
	float occlusion=texture2D( m_OcclusionTexture,v_TexCoord0 ).r;

	vec3 normal=texture2D( m_NormalTexture,v_TexCoord0 ).xyz * 2.0 - 1.0;
	
	main0( color,emissive*lightmap,lightmap,metalness,roughness,occlusion,normal );
	
//	gl_FragColor=vec4( 1.0,0.5,0.0,1.0 );	
	
#else

	gl_FragColor=vec4( vec3( gl_FragCoord.z ),1.0 );

#endif

}
