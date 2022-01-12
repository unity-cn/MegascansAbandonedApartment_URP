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

//};
struct MaterialStruct
{
	float4 VectorExpressions[68 ];
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
	Material.VectorExpressions[2] = float4(0.500000,0.500000,0.500000,1.000000);//Base Color
	Material.VectorExpressions[3] = float4(1.000000,1.000000,1.000000,1.000000);//(Unknown)
	Material.VectorExpressions[4] = float4(2.000000,2.000000,2.000000,2.000000);//(Unknown)
	Material.VectorExpressions[5] = float4(0.500000,0.500000,0.500000,0.000000);//(Unknown)
	Material.ScalarExpressions[0] = float4(0.000000,0.000000,1.716537,1.000000);//(Unknown) Color Variation Tiling Crop Y
	Material.ScalarExpressions[1] = float4(1.000000,1.000000,0.866185,0.714718);//Crop X Color Intensity Metallic Spec
	Material.ScalarExpressions[2] = float4(0.100000,1.000000,0.000000,0.000000);//Roughness Intensity Opacity Intensity RefractionDepthBias (Unknown)
}void CalcPixelMaterialInputs(in out FMaterialPixelParameters Parameters, in out FPixelMaterialInputs PixelMaterialInputs)
{
	float3 WorldNormalCopy = Parameters.WorldNormal;

	// Initial calculations (required for Normal)

	// The Normal is a special case as it might have its own expressions and also be used to calculate other inputs, so perform the assignment here
	PixelMaterialInputs.Normal = MaterialFloat3(0.00000000,0.00000000,1.00000000);


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
	MaterialFloat3 Local0 = lerp(MaterialFloat3(0.00000000,0.00000000,0.00000000),Material.VectorExpressions[1].rgb,MaterialFloat(Material.ScalarExpressions[0].x));
	MaterialFloat3 Local1 = (MaterialFloat3(100.00000000,10.00000000,1.00000000) * GetPerInstanceRandom(Parameters));
	MaterialFloat3 Local2 = (GetObjectWorldPosition(Parameters) * 0.01000000);
	MaterialFloat3 Local3 = (Local1 + Local2);
	MaterialFloat3 Local4 = frac(Local3);
	MaterialFloat Local5 = dot(Local4.rg, Local4.gb);
	MaterialFloat Local6 = (-0.50000000 + Local5);
	MaterialFloat Local7 = (Local6 * 2.00000000);
	MaterialFloat Local8 = (Material.ScalarExpressions[0].y * Local7);
	MaterialFloat Local9 = dot(Local4, Local4);
	MaterialFloat Local10 = sqrt(Local9);
	MaterialFloat3 Local11 = (Local4 / Local10);
	MaterialFloat3 Local12 = (Local8 * Local11);
	MaterialFloat2 Local13 = (Parameters.TexCoords[0].xy * Material.ScalarExpressions[0].z);
	MaterialFloat2 Local14 = (Local13 + Material.VectorExpressions[4].rg);
	MaterialFloat Local15 = MaterialStoreTexCoordScale(Parameters, Local14, 0);
	MaterialFloat4 Local16 = ProcessMaterialColorTextureLookup(Texture2DSample(Material_Texture2D_0, GetMaterialSharedSampler(Material_Texture2D_0Sampler,View.MaterialTextureBilinearWrapedSampler),Local14));
	MaterialFloat Local17 = MaterialStoreTexSample(Parameters, Local16, 0);
	MaterialFloat3 Local18 = (Material.VectorExpressions[5].rgb + Local16.r);
	MaterialFloat3 Local19 = lerp(MaterialFloat3(Material.ScalarExpressions[1].y,Material.ScalarExpressions[1].y,Material.ScalarExpressions[1].y),Local18,MaterialFloat(Local16.r));
	MaterialFloat3 Local20 = (Local12 + Local19);
	MaterialFloat Local21 = (Local16.r * Material.ScalarExpressions[2].x);
	MaterialFloat Local22 = (Local16.r * Material.ScalarExpressions[2].y);

	PixelMaterialInputs.EmissiveColor = Local0;
	PixelMaterialInputs.Opacity = Local22;
	PixelMaterialInputs.OpacityMask = 1.00000000;
	PixelMaterialInputs.BaseColor = Local20;
	PixelMaterialInputs.Metallic = Material.ScalarExpressions[1].z;
	PixelMaterialInputs.Specular = Material.ScalarExpressions[1].w;
	PixelMaterialInputs.Roughness = Local21;
	PixelMaterialInputs.Anisotropy = 0.00000000;
	PixelMaterialInputs.Tangent = MaterialFloat3(1.00000000,0.00000000,0.00000000);
	PixelMaterialInputs.Subsurface = 0;
	PixelMaterialInputs.AmbientOcclusion = 1.00000000;
	PixelMaterialInputs.Refraction = MaterialFloat2(MaterialFloat2(MaterialFloat2(1.00000000,0.00000000).r,0).r,Material.ScalarExpressions[2].z);
	PixelMaterialInputs.PixelDepthOffset = 0.00000000;
	PixelMaterialInputs.ShadingModel = 1;


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
	//if( PixelMaterialInputs.OpacityMask < 0.333 ) discard;

	o.Metallic = PixelMaterialInputs.Metallic;
	o.Smoothness = 1.0 - PixelMaterialInputs.Roughness;
	o.Normal = normalize( PixelMaterialInputs.Normal );
	o.Emission = PixelMaterialInputs.EmissiveColor.rgb;
	o.Occlusion = PixelMaterialInputs.AmbientOcclusion;
}