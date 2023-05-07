Shader "PGA/Terrain_Shader"
{
    Properties
    {
		[Header(Shading)]
		_Color("Color", Color) = (1,1,1,1)

		[Header(Resolution)]
		_TesselationFactor("Tesselation Factor", int) = 2
		_TesselationInnerFactor("Tesselation Inner Factor", int) = 2
		_RelativeToDistanceToCamera("Relative to Distance to Camera", int) = 0
		_MinCameraLODDistance("Min Camera LOD Distance", float) = 2.0
		_MaxCameraLODDistance("Max Camera LOD Distance", float) = 10.0

		[Header(Displacement)]
		_HeightMap("Height Map", 2D) = "white" {}
		_HeightMultiplier("Height Multiplier", float) = 1.0
    }

	//--------------------------------------------------------------------------
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"

	int _TesselationFactor;
	int _TesselationInnerFactor;
	int _RelativeToDistanceToCamera;
	float _MinCameraLODDistance;
	float _MaxCameraLODDistance;

	sampler2D _HeightMap;
	float _HeightMultiplier;

	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Vertex Shader
	//--------------------------------------------------------------------------

	struct VertexStage_Input{
		float4 pos: POSITION;
		float3 normal: NORMAL;
		float4 tangent: TANGENT;
		float2 uv : TEXCOORD0;
	};

	struct VertexStage_Output{
		float4 pos : SV_POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float2 uv : TEXCOORD0;
	};
	
	VertexStage_Output VertShader(VertexStage_Input v)
	{
		VertexStage_Output o;
		
		float3 displacement = tex2Dlod(_HeightMap, float4(v.uv ,0 , 0)).xyz;
		displacement *= _HeightMultiplier;
		float4 pos = v.pos + float4(v.normal.x, v.normal.y, v.normal.z , 0.0f) * displacement.x;

		o.pos = pos;
		o.normal = v.normal;
		o.tangent = v.tangent;
		o.uv = v.uv;
		return o;
	}

	VertexStage_Output TesselationVertShader(VertexStage_Input v)
	{
		VertexStage_Output o;
		o.pos = v.pos;
		o.normal = v.normal;
		o.tangent = v.tangent;
		o.uv = v.uv;
		return o;
	}

	// Geometry Shader
	//--------------------------------------------------------------------------

	struct GeometryStage_Output
	{
		float4 pos: SV_POSITION;
		float4 world_pos : POSITION1;
		float3 normal : NORMAL;
		float2 uv : TEXCOORD0;
	};

	GeometryStage_Output CreateGeometryStageOutput(float3 pos, float3 normal, float2 uv)
	{
		GeometryStage_Output o;
		
		o.pos = UnityObjectToClipPos(float4(pos, 1.0f));
		o.world_pos = mul(unity_ObjectToWorld, float4(pos, 1.0f));
		o.normal = normal;
		o.uv = uv;
		return o;
	}

 	[maxvertexcount(3)]
    void GeoShader(triangle VertexStage_Output IN[3], inout TriangleStream<GeometryStage_Output> triStream)
    {
		float3 pos0 = IN[0].pos;
		float3 pos1 = IN[1].pos;
		float3 pos2 = IN[2].pos;

		float3 v = pos1 - pos0;
		float3 u = pos2 - pos0;
		float3 normal = normalize(cross(v, u));

		triStream.Append(CreateGeometryStageOutput(pos0, normal, IN[0].uv));
		triStream.Append(CreateGeometryStageOutput(pos1, normal, IN[1].uv));
		triStream.Append(CreateGeometryStageOutput(pos2, normal, IN[2].uv));
    }

	// Tesselation Shader
	//--------------------------------------------------------------------------

	struct TessellationFactors {
		float edge[3] : SV_TessFactor;
		float inside : SV_InsideTessFactor;
	};

	struct TessOutputPatch {
		float3 b030;
		float3 b021;
		float3 b012;
		float3 b003;
		float3 b102;
		float3 b201;
		float3 b300;
		float3 b210;
		float3 b120;
		float3 b111;
		float3 normal[3];
		float2 uv[3];
	};

	TessellationFactors PatchConstantFunction(InputPatch<VertexStage_Input, 3> patch) {
		TessellationFactors f;

		if (_RelativeToDistanceToCamera == 1) {
			// LODs:
			// Change the amount of subdivisions based on the distance between the triangle and the camera
			// We first measure the distance from the camera to the triangle center

			// Calculate triangle center
			float3 v1 = mul(unity_ObjectToWorld, patch[0].pos).xyz;
			float3 v2 = mul(unity_ObjectToWorld, patch[1].pos).xyz;
			float3 v3 = mul(unity_ObjectToWorld, patch[2].pos).xyz;
			float3 vertPos = (v1 + v2 + v3) / 3.0f;

			// Calculate subdivision coeficients
			float dist = max(0.0f, (distance(_WorldSpaceCameraPos, vertPos) - _MinCameraLODDistance) / _MaxCameraLODDistance);
			int a = max(1.0f, float(_TesselationFactor) / dist);
			int b = max(1.0f, float(_TesselationInnerFactor) / dist);

			// Register subdivisions
			f.edge[0] = a;
			f.edge[1] = a;
			f.edge[2] = a;
			f.inside = b;
		}
		else {
			// Use fixed tesellation factors
			f.edge[0] = _TesselationFactor;
			f.edge[1] = _TesselationFactor;
			f.edge[2] = _TesselationFactor;
			f.inside = _TesselationInnerFactor;
		}
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

		#define TESS_DOMAIN_SHADER_INTERPOLATE(fieldName) v.fieldName = \
					patch[0].fieldName * barycentricCoordinates.x + \
					patch[1].fieldName * barycentricCoordinates.y + \
					patch[2].fieldName * barycentricCoordinates.z;

		TESS_DOMAIN_SHADER_INTERPOLATE(pos);
		TESS_DOMAIN_SHADER_INTERPOLATE(normal);
		TESS_DOMAIN_SHADER_INTERPOLATE(tangent);
		TESS_DOMAIN_SHADER_INTERPOLATE(uv);

		normalize(v.normal);
		normalize(v.tangent);

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
			#pragma geometry GeoShader
			#pragma hull TessHullShader
			#pragma domain TessDomainShader
			#pragma target 4.6
            
			#include "Lighting.cginc"

			float4 _Color;

			float4 FragShader(GeometryStage_Output i, fixed facing : VFACE) : SV_Target
			{
				float3 viewDir = normalize(_WorldSpaceLightPos0 - i.world_pos.xyz);
				float3 worldNormal = normalize(mul(unity_ObjectToWorld, float4(i.normal, 0)));
				float a = dot(viewDir, worldNormal);
				float3 color = _Color;
				if (a < 0.3f) { color *= 0.4; }
				else if (a < 0.5f) { color *= 0.8; }
				return float4(color, 1.0f);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
