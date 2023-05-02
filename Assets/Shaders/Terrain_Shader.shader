Shader "Custom/Terrain_Shader"
{
    Properties
    {
		[Header(Shading)]
		_Color("Color", Color) = (1,1,1,1)
        _TesselationFactor("Tesselation Factor", int) = 2
		_TesselationInnerFactor("Tesselation Inner Factor", int) = 2
		_DistortionMap("Terrain Texture", 2D) = "white" {}
		_TerrainScale("Terrain Scale", Range(1,100)) = 10
    }

	//--------------------------------------------------------------------------
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"

	int _TesselationFactor;
	int _TesselationInnerFactor;
	float _TerrainScale;
	sampler2D _DistortionMap;

	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	//--------------------------------------------------------------------------

	struct VertexStage_Input{
		float4 vertex: POSITION;
		float3 normal: NORMAL;
		float4 tangent: TANGENT;
		float2 uv : TEXCOORD0;
	};

	struct VertexStage_Output{
		float4 vertex : SV_POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float2 uv : TEXCOORD0;
	};

	VertexStage_Output VertShader(VertexStage_Input v)
	{
		VertexStage_Output o;
		
		float3 displacement = tex2Dlod(_DistortionMap, float4(v.uv/_TerrainScale ,0 , 0)).xyz;
		float4 pos = v.vertex + float4(v.normal.x, v.normal.y, v.normal.z , 0.0f) * displacement.x;

		o.vertex = UnityObjectToClipPos(pos);
		o.normal = v.normal;
		o.tangent = v.tangent;
		o.uv = v.uv;
		return o;
	}

	VertexStage_Output TesselationVertShader(VertexStage_Input v)
	{
		VertexStage_Output o;
		o.vertex = v.vertex;
		o.normal = v.normal;
		o.tangent = v.tangent;
		o.uv = v.uv;
		return o;
	}

	//--------------------------------------------------------------------------

	struct GeometryStage_Output
	{
		float4 pos: SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	GeometryStage_Output GenerateVertex(VertexStage_Output v)
	{
		GeometryStage_Output o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = float2(0, 0);
		return o;
	}

	GeometryStage_Output GenerateVertex(float4 pos)
	{
		GeometryStage_Output o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = float2(0, 0);
		return o;
	}

 	[maxvertexcount(1)]
    void GeoShader(point VertexStage_Output IN[1], inout TriangleStream<GeometryStage_Output> triStream)
    {
		float3 pos = IN[0].vertex;
		triStream.Append(GenerateVertex(float4(pos, 1.0f)));
    }

	//--------------------------------------------------------------------------

	struct TessellationFactors {
		float edge[3] : SV_TessFactor;
		float inside : SV_InsideTessFactor;
	};

	TessellationFactors PatchConstantFunction(InputPatch<VertexStage_Input, 3> patch) {
		TessellationFactors f;
		f.edge[0] = _TesselationFactor;
		f.edge[1] = _TesselationFactor;
		f.edge[2] = _TesselationFactor;
		f.inside = _TesselationInnerFactor;
		return f;
	}

	[UNITY_domain("tri")]
	[UNITY_outputcontrolpoints(3)]
	[UNITY_outputtopology("triangle_cw")]
	[UNITY_partitioning("integer")]
	[UNITY_patchconstantfunc("PatchConstantFunction")]
	VertexStage_Input TessHullShader(InputPatch<VertexStage_Input, 3> patch, uint id : SV_OutputControlPointID) {
		return patch[id];
	}

	[UNITY_domain("tri")]
	VertexStage_Output TessDomainShader(TessellationFactors factors, OutputPatch<VertexStage_Input, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
		VertexStage_Input v;

		#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
					patch[0].fieldName * barycentricCoordinates.x + \
					patch[1].fieldName * barycentricCoordinates.y + \
					patch[2].fieldName * barycentricCoordinates.z;

		MY_DOMAIN_PROGRAM_INTERPOLATE(vertex);
		MY_DOMAIN_PROGRAM_INTERPOLATE(normal);
		MY_DOMAIN_PROGRAM_INTERPOLATE(tangent);
		MY_DOMAIN_PROGRAM_INTERPOLATE(uv);

		return VertShader(v);
	}

	ENDCG

	//--------------------------------------------------------------------------

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex TesselationVertShader
            #pragma fragment FragShader
			// #pragma geometry GeoShader
			#pragma hull TessHullShader
			#pragma domain TessDomainShader
			#pragma target 4.6
            
			#include "Lighting.cginc"

			float4 _Color;

			float4 FragShader (GeometryStage_Output i, fixed facing : VFACE) : SV_Target
            {	
				return _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
