#define NUM_TEX_COORD_INTERPOLATORS 1
#define NUM_CUSTOM_VERTEX_INTERPOLATORS 0

struct Input
{
	//float3 Normal;
	float2 uv_MainTex : TEXCOORD0;
	float2 uv2_Material_Texture2D_0 : TEXCOORD1;
	float4 color : COLOR;
	float4 tangent;
	//float4 normal;
	float3 viewDir;
	float4 screenPos;
	float3 worldPos;
	//float3 worldNormal;
	float3 normal2;
};
struct SurfaceOutputStandard
{
	float3 Albedo;		// base (diffuse or specular) color
	float3 Normal;		// tangent space normal, if written
	half3 Emission;
	half Metallic;		// 0=non-metal, 1=metal
	// Smoothness is the user facing name, it should be perceptual smoothness but user should not have to deal with it.
	// Everywhere in the code you meet smoothness it is perceptual smoothness
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;		// occlusion (default 1)
	float Alpha;		// alpha for transparencies
};

#define Texture2D sampler2D
#define TextureCube samplerCUBE
#define SamplerState int
//struct Material
//{
	//samplers start
			uniform sampler2D    Material_Texture2D_0;
			uniform SamplerState Material_Texture2D_0Sampler;
			uniform sampler2D    Material_Texture2D_1;
			uniform SamplerState Material_Texture2D_1Sampler;
			uniform sampler2D    Material_Texture2D_2;
			uniform SamplerState Material_Texture2D_2Sampler;
			uniform sampler2D    Material_Texture2D_3;
			uniform SamplerState Material_Texture2D_3Sampler;
			uniform sampler2D    Material_Texture2D_4;
			uniform SamplerState Material_Texture2D_4Sampler;

//};
struct MaterialStruct
{
	float4 VectorExpressions[108 ];
	float4 ScalarExpressions[31 ];
};
struct ViewStruct
{
	float GameTime;
	float MaterialTextureMipBias;
	SamplerState MaterialTextureBilinearWrapedSampler;
	SamplerState MaterialTextureBilinearClampedSampler;
	float4 PrimitiveSceneData[ 40 ];
	float2 TemporalAAParams;
	float2 ViewRectMin;
	float4 ViewSizeAndInvSize;
	float MaterialTextureDerivativeMultiply;
};
struct ResolvedViewStruct
{
	float3 WorldCameraOrigin;
	float4 ScreenPositionScaleBias;
	float4x4 TranslatedWorldToView;
	float4x4 TranslatedWorldToCameraView;
	float4x4 ViewToTranslatedWorld;
	float4x4 CameraViewToTranslatedWorld;
};
struct PrimitiveStruct
{
	float4x4 WorldToLocal;
	float4x4 LocalToWorld;
};

ViewStruct View;
ResolvedViewStruct ResolvedView;
PrimitiveStruct Primitive;
uniform float4 View_BufferSizeAndInvSize;
uniform int Material_Wrap_WorldGroupSettings;

#include "UnrealCommon.cginc"

MaterialStruct Material;
void InitializeExpressions()
{
	Material.VectorExpressions[0] = float4(0.000000,0.000000,0.000000,0.000000);//SelectionColor
	Material.VectorExpressions[1] = float4(0.000000,0.000000,0.000000,0.000000);//(Unknown)
	Material.VectorExpressions[2] = float4(1.000000,1.000000,1.000000,1.000000);//(Unknown)
	Material.VectorExpressions[3] = float4(2.000000,2.000000,2.000000,2.000000);//(Unknown)
	Material.VectorExpressions[4] = float4(0.000000,0.000000,0.000000,0.000000);//(Unknown)
	Material.VectorExpressions[5] = float4(0.000000,0.000000,0.000000,0.000000);//(Unknown)
	Material.VectorExpressions[6] = float4(0.616072,0.548148,0.482232,1.000000);//Color Tint
	Material.VectorExpressions[7] = float4(0.616072,0.548148,0.482232,0.000000);//(Unknown)
	Material.VectorExpressions[8] = float4(1.000000,1.000000,1.000000,1.000000);//SSS Color Tint
	Material.VectorExpressions[9] = float4(1.000000,1.000000,1.000000,0.000000);//(Unknown)
	Material.ScalarExpressions[0] = float4(0.000000,1.000000,1.000000,1.000000);//Normal Intensity Tiling Crop Y Crop X
	Material.ScalarExpressions[1] = float4(0.000000,0.000000,1.000000,1.000000);//(Unknown) Color Variation Color Intensity Roughness Intensity
	Material.ScalarExpressions[2] = float4(1.000000,1.000000,0.000000,0.000000);//Opacity Intensity SSS Color Intensity __SubsurfaceProfile (Unknown)
}void CalcPixelMaterialInputs(in out FMaterialPixelParameters Parameters, in out FPixelMaterialInputs PixelMaterialInputs)
{
	float3 WorldNormalCopy = Parameters.WorldNormal;

	// Initial calculations (required for Normal)
	MaterialFloat2 Local0 = (Parameters.TexCoords[0].xy * Material.ScalarExpressions[0].y);
	MaterialFloat2 Local1 = (Local0 + Material.VectorExpressions[3].rg);
	MaterialFloat Local2 = MaterialStoreTexCoordScale(Parameters, Local1, 1);
	MaterialFloat4 Local3 = UnpackNormalMap(Texture2DSample(Material_Texture2D_0, GetMaterialSharedSampler(Material_Texture2D_0Sampler,View.MaterialTextureBilinearWrapedSampler),Local1));
	MaterialFloat Local4 = MaterialStoreTexSample(Parameters, Local3, 1);
	MaterialFloat3 Local5 = (Material.VectorExpressions[4].rgb * Local3.rgb);
	MaterialFloat3 Local6 = (Local5 + Local3.rgb);

	// The Normal is a special case as it might have its own expressions and also be used to calculate other inputs, so perform the assignment here
	PixelMaterialInputs.Normal = Local6;


	// Note that here MaterialNormal can be in world space or tangent space
	float3 MaterialNormal = GetMaterialNormal(Parameters, PixelMaterialInputs);

#if MATERIAL_TANGENTSPACENORMAL
#if SIMPLE_FORWARD_SHADING
	Parameters.WorldNormal = float3(0, 0, 1);
#endif

#if FEATURE_LEVEL >= FEATURE_LEVEL_SM4
	// Mobile will rely on only the final normalize for performance
	MaterialNormal = normalize(MaterialNormal);
#endif

	// normalizing after the tangent space to world space conversion improves quality with sheared bases (UV layout to WS causes shrearing)
	// use full precision normalize to avoid overflows
	Parameters.WorldNormal = TransformTangentNormalToWorld(Parameters.TangentToWorld, MaterialNormal);

#else //MATERIAL_TANGENTSPACENORMAL

	Parameters.WorldNormal = normalize(MaterialNormal);

#endif //MATERIAL_TANGENTSPACENORMAL

#if MATERIAL_TANGENTSPACENORMAL
	// flip the normal for backfaces being rendered with a two-sided material
	Parameters.WorldNormal *= Parameters.TwoSidedSign;
#endif

	Parameters.ReflectionVector = ReflectionAboutCustomWorldNormal(Parameters, Parameters.WorldNormal, false);

#if !PARTICLE_SPRITE_FACTORY
	Parameters.Particle.MotionBlurFade = 1.0f;
#endif // !PARTICLE_SPRITE_FACTORY

	// Now the rest of the inputs
	MaterialFloat3 Local7 = lerp(MaterialFloat3(0.00000000,0.00000000,0.00000000),Material.VectorExpressions[5].rgb,MaterialFloat(Material.ScalarExpressions[1].x));
	MaterialFloat3 Local8 = (MaterialFloat3(100.00000000,10.00000000,1.00000000) * GetPerInstanceRandom(Parameters));
	MaterialFloat3 Local9 = (GetObjectWorldPosition(Parameters) * 0.01000000);
	MaterialFloat3 Local10 = (Local8 + Local9);
	MaterialFloat3 Local11 = frac(Local10);
	MaterialFloat Local12 = dot(Local11.rg, Local11.gb);
	MaterialFloat Local13 = (-0.50000000 + Local12);
	MaterialFloat Local14 = (Local13 * 2.00000000);
	MaterialFloat Local15 = (Material.ScalarExpressions[1].y * Local14);
	MaterialFloat Local16 = dot(Local11, Local11);
	MaterialFloat Local17 = sqrt(Local16);
	MaterialFloat3 Local18 = (Local11 / Local17);
	MaterialFloat3 Local19 = (Local15 * Local18);
	MaterialFloat Local20 = MaterialStoreTexCoordScale(Parameters, Local1, 0);
	MaterialFloat4 Local21 = ProcessMaterialColorTextureLookup(Texture2DSample(Material_Texture2D_1, GetMaterialSharedSampler(Material_Texture2D_1Sampler,View.MaterialTextureBilinearWrapedSampler),Local1));
	MaterialFloat Local22 = MaterialStoreTexSample(Parameters, Local21, 0);
	MaterialFloat3 Local23 = (Local21.rgb * Material.ScalarExpressions[1].z);
	MaterialFloat3 Local24 = (Local23 * Material.VectorExpressions[7].rgb);
	MaterialFloat3 Local25 = (Local19 + Local24);
	MaterialFloat Local26 = MaterialStoreTexCoordScale(Parameters, Local1, 2);
	MaterialFloat4 Local27 = ProcessMaterialColorTextureLookup(Texture2DSample(Material_Texture2D_2, GetMaterialSharedSampler(Material_Texture2D_2Sampler,View.MaterialTextureBilinearWrapedSampler),Local1));
	MaterialFloat Local28 = MaterialStoreTexSample(Parameters, Local27, 2);
	MaterialFloat Local29 = (Local27.r * Material.ScalarExpressions[1].w);
	MaterialFloat4 Local30 = ProcessMaterialColorTextureLookup(Texture2DSample(Material_Texture2D_3, GetMaterialSharedSampler(Material_Texture2D_3Sampler,View.MaterialTextureBilinearWrapedSampler),Local1));
	MaterialFloat Local31 = MaterialStoreTexSample(Parameters, Local30, 2);
	MaterialFloat Local32 = (Local30.r * Material.ScalarExpressions[2].x);
	MaterialFloat4 Local33 = ProcessMaterialColorTextureLookup(Texture2DSample(Material_Texture2D_4, GetMaterialSharedSampler(Material_Texture2D_4Sampler,View.MaterialTextureBilinearWrapedSampler),Local1));
	MaterialFloat Local34 = MaterialStoreTexSample(Parameters, Local33, 2);
	MaterialFloat3 Local35 = (Local33.rgb * Material.ScalarExpressions[2].y);
	MaterialFloat3 Local36 = (Local35 * Material.VectorExpressions[9].rgb);
	MaterialFloat3 Local37 = min(max(Local36,MaterialFloat3(0.00000000,0.00000000,0.00000000)),MaterialFloat3(1.00000000,1.00000000,1.00000000));

	PixelMaterialInputs.EmissiveColor = Local7;
	PixelMaterialInputs.Opacity = 1.00000000;
	PixelMaterialInputs.OpacityMask = Local32;
	PixelMaterialInputs.BaseColor = Local25;
	PixelMaterialInputs.Metallic = 0.00000000;
	PixelMaterialInputs.Specular = 0.50000000;
	PixelMaterialInputs.Roughness = Local29;
	PixelMaterialInputs.Anisotropy = 0.00000000;
	PixelMaterialInputs.Tangent = MaterialFloat3(1.00000000,0.00000000,0.00000000);
	PixelMaterialInputs.Subsurface = MaterialFloat4(Local37,Material.ScalarExpressions[2].z);
	PixelMaterialInputs.AmbientOcclusion = 1.00000000;
	PixelMaterialInputs.Refraction = 0;
	PixelMaterialInputs.PixelDepthOffset = 0.00000000;
	PixelMaterialInputs.ShadingModel = 6;


#if MATERIAL_USES_ANISOTROPY
	Parameters.WorldTangent = CalculateAnisotropyTangent(Parameters, PixelMaterialInputs);
#else
	Parameters.WorldTangent = 0;
#endif
}

#define UnityObjectToWorldDir TransformObjectToWorld
void SurfaceReplacement( Input In, out SurfaceOutputStandard o )
{
	InitializeExpressions();

	float3 Z3 = float3( 0, 0, 0 );
	float4 Z4 = float4( 0, 0, 0, 0 );

	float3 UnrealWorldPos = float3( In.worldPos.x, In.worldPos.y, In.worldPos.z );

	float3 UnrealNormal = In.normal2;

	FMaterialPixelParameters Parameters = (FMaterialPixelParameters)0;
#if NUM_TEX_COORD_INTERPOLATORS > 0			
	Parameters.TexCoords[ 0 ] = float2( In.uv_MainTex.x, In.uv_MainTex.y );
#endif
#if NUM_TEX_COORD_INTERPOLATORS > 1
	Parameters.TexCoords[ 1 ] = float2( In.uv2_Material_Texture2D_0.x, 1.0 - In.uv2_Material_Texture2D_0.y );
#endif
#if NUM_TEX_COORD_INTERPOLATORS > 2
	for( int i = 2; i < NUM_TEX_COORD_INTERPOLATORS; i++ )
	{
		Parameters.TexCoords[ i ] = float2( In.uv_MainTex.x, In.uv_MainTex.y );
	}
#endif
	Parameters.VertexColor = In.color;
	Parameters.WorldNormal = UnrealNormal;
	Parameters.ReflectionVector = half3( 0, 0, 1 );
	//Parameters.CameraVector = normalize( _WorldSpaceCameraPos.xyz - UnrealWorldPos.xyz );
	Parameters.CameraVector = mul( ( float3x3 )unity_CameraToWorld, float3( 0, 0, 1 ) ) * -1;
	Parameters.LightVector = half3( 0, 0, 0 );
	float4 screenpos = In.screenPos;
	screenpos /= screenpos.w;
	//screenpos.y = 1 - screenpos.y;
	Parameters.SvPosition = float4( screenpos.x, screenpos.y, 0, 0 );
	Parameters.ScreenPosition = Parameters.SvPosition;

	Parameters.UnMirrored = 1;

	Parameters.TwoSidedSign = 1;


	float3 InWorldNormal = UnrealNormal;
	float4 InTangent = In.tangent;
	float4 tangentWorld = float4( UnityObjectToWorldDir( InTangent.xyz ), InTangent.w );
	tangentWorld.xyz = normalize( tangentWorld.xyz );
	//float3x3 tangentToWorld = CreateTangentToWorldPerVertex( InWorldNormal, tangentWorld.xyz, tangentWorld.w );
	Parameters.TangentToWorld = float3x3( Z3, Z3, Z3 );// tangentToWorld;

	//WorldAlignedTexturing in UE relies on the fact that coords there are 100x larger, prepare values for that
	//but watch out for any computation that might get skewed as a side effect
	UnrealWorldPos = UnrealWorldPos * 100;

	//Parameters.TangentToWorld = half3x3( float3( 1, 1, 1 ), float3( 1, 1, 1 ), UnrealNormal.xyz );
	Parameters.AbsoluteWorldPosition = UnrealWorldPos;
	Parameters.WorldPosition_CamRelative = UnrealWorldPos;
	Parameters.WorldPosition_NoOffsets = UnrealWorldPos;

	Parameters.WorldPosition_NoOffsets_CamRelative = Parameters.WorldPosition_CamRelative;
	Parameters.LightingPositionOffset = float3( 0, 0, 0 );

	Parameters.AOMaterialMask = 0;

	Parameters.Particle.RelativeTime = 0;
	Parameters.Particle.MotionBlurFade;
	Parameters.Particle.Random = 0;
	Parameters.Particle.Velocity = half4( 1, 1, 1, 1 );
	Parameters.Particle.Color = half4( 1, 1, 1, 1 );
	Parameters.Particle.TranslatedWorldPositionAndSize = float4( UnrealWorldPos, 0 );
	Parameters.Particle.MacroUV = half4( 0, 0, 1, 1 );
	Parameters.Particle.DynamicParameter = half4( 0, 0, 0, 0 );
	Parameters.Particle.LocalToWorld = float4x4( Z4, Z4, Z4, Z4 );
	Parameters.Particle.Size = float2( 1, 1 );
	Parameters.TexCoordScalesParams = float2( 0, 0 );
	Parameters.PrimitiveId = 0;

	FPixelMaterialInputs PixelMaterialInputs = (FPixelMaterialInputs)0;
	PixelMaterialInputs.Normal = float3( 0, 0, 1 );
	PixelMaterialInputs.ShadingModel = 0;

	//Extra
	View.GameTime = -_Time.y;// _Time is (t/20, t, t*2, t*3), run in reverse because it works better with ElementalDemo
	View.MaterialTextureMipBias = 0.0;
	View.TemporalAAParams = float2( 0, 0 );
	View.ViewRectMin = float2( 0, 0 );
	View.ViewSizeAndInvSize = View_BufferSizeAndInvSize;
	View.MaterialTextureDerivativeMultiply = 1.0f;
	for( int i2 = 0; i2 < 40; i2++ )
		View.PrimitiveSceneData[ i2 ] = float4( 0, 0, 0, 0 );

	uint PrimitiveBaseOffset = Parameters.PrimitiveId * PRIMITIVE_SCENE_DATA_STRIDE;
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 0 ] = unity_ObjectToWorld[ 0 ];//LocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 1 ] = unity_ObjectToWorld[ 1 ];//LocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 2 ] = unity_ObjectToWorld[ 2 ];//LocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 3 ] = unity_ObjectToWorld[ 3 ];//LocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 6 ] = unity_WorldToObject[ 0 ];//WorldToLocal
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 7 ] = unity_WorldToObject[ 1 ];//WorldToLocal
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 8 ] = unity_WorldToObject[ 2 ];//WorldToLocal
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 9 ] = unity_WorldToObject[ 3 ];//WorldToLocal
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 10 ] = unity_WorldToObject[ 0 ];//PreviousLocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 11 ] = unity_WorldToObject[ 1 ];//PreviousLocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 12 ] = unity_WorldToObject[ 2 ];//PreviousLocalToWorld
	View.PrimitiveSceneData[ PrimitiveBaseOffset + 13 ] = unity_WorldToObject[ 3 ];//PreviousLocalToWorld

	ResolvedView.WorldCameraOrigin = _WorldSpaceCameraPos.xyz;
	ResolvedView.ScreenPositionScaleBias = float4( 1, 1, 0, 0 );
	ResolvedView.TranslatedWorldToView = unity_MatrixV;
	ResolvedView.TranslatedWorldToCameraView = unity_MatrixV;
	ResolvedView.ViewToTranslatedWorld = unity_MatrixInvV;
	ResolvedView.CameraViewToTranslatedWorld = unity_MatrixInvV;
	Primitive.WorldToLocal = unity_WorldToObject;
	Primitive.LocalToWorld = unity_ObjectToWorld;
	CalcPixelMaterialInputs( Parameters, PixelMaterialInputs );

	#define HAS_WORLDSPACE_NORMAL 0
	#if HAS_WORLDSPACE_NORMAL
		PixelMaterialInputs.Normal = mul( PixelMaterialInputs.Normal, (MaterialFloat3x3)( transpose( Parameters.TangentToWorld ) ) );
	#endif

	o.Albedo = PixelMaterialInputs.BaseColor.rgb;
	o.Alpha = PixelMaterialInputs.Opacity;
	if( PixelMaterialInputs.OpacityMask < 0.333 ) discard;

	o.Metallic = PixelMaterialInputs.Metallic;
	o.Smoothness = 1.0 - PixelMaterialInputs.Roughness;
	o.Normal = normalize( PixelMaterialInputs.Normal );
	o.Emission = PixelMaterialInputs.EmissiveColor.rgb;
	o.Occlusion = PixelMaterialInputs.AmbientOcclusion;
}