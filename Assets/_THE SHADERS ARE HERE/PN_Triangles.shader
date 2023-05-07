Shader "PGA/PN_Triangles"
{
    Properties
    {
		[Header(Shading)]
		_Color("Color", Color) = (1,1,1,1)

		[Header(Displacement)]
		_HeightMap("Height Map", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "normal" {}
		_HeightMultiplier("Height Multiplier", float) = 1.0
    }

	//--------------------------------------------------------------------------
	
	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _HeightMap;
	float4 _HeightMap_ST;
	sampler2D _NormalMap;
	float4 _NormalMap_ST;
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

		v.uv.x = v.uv.x * _HeightMap_ST.x + _HeightMap_ST.z;
		v.uv.y = v.uv.y * _HeightMap_ST.y + _HeightMap_ST.w;

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
		float3 tangent : TANGENT;
		float2 uv : TEXCOORD0;
	};

	GeometryStage_Output CreateGeometryStageOutput(float3 pos, float3 normal, float3 tangent, float2 uv)
	{
		GeometryStage_Output o;
		
		o.pos = UnityObjectToClipPos(float4(pos, 1.0f));
		o.world_pos = mul(unity_ObjectToWorld, float4(pos, 1.0f));
		o.normal = normal;
		o.uv = uv;
		o.tangent = tangent;
		return o;
	}

 	[maxvertexcount(3)]
    void GeoShader(triangle VertexStage_Output IN[3], inout TriangleStream<GeometryStage_Output> triStream)
    {
		float3 pos0 = IN[0].pos;
		float3 pos1 = IN[1].pos;
		float3 pos2 = IN[2].pos;

		triStream.Append(CreateGeometryStageOutput(pos0, IN[0].normal, IN[0].tangent, IN[0].uv));
		triStream.Append(CreateGeometryStageOutput(pos1, IN[1].normal, IN[1].tangent, IN[1].uv));
		triStream.Append(CreateGeometryStageOutput(pos2, IN[2].normal, IN[2].tangent, IN[2].uv));
    }

	// Tesselation Shader
	//--------------------------------------------------------------------------

	struct TessellationFactors {
		float edge[3] : SV_TessFactor;
		float inside : SV_InsideTessFactor;
		float a : PADDING;
		float3 b030 : BEZIER_POS0;
		float3 b021 : BEZIER_POS1;
		float3 b012 : BEZIER_POS2;
		float3 b003 : BEZIER_POS3;
		float3 b102 : BEZIER_POS4;
		float3 b201 : BEZIER_POS5;
		float3 b300 : BEZIER_POS6;
		float3 b210 : BEZIER_POS7;
		float3 b120 : BEZIER_POS8;
		float3 b111 : BEZIER_POS9;
	};

	float3 CalculateBezierPoints(float3 p0, float3 p0Normal, float3 p1) {
		float w = dot(p1 - p0, p0Normal);
		return (p0 * 2 + p1 - w * p0Normal) / 3.0;
	}

	TessellationFactors PatchConstantFunction(InputPatch<VertexStage_Input, 3> patch) {
		TessellationFactors f;
		f.a = 0;
		f.edge[0] = 3; 
		f.edge[1] = 3; 
		f.edge[2] = 3; 
		f.inside = 1;

		f.b300 = patch[0].pos;	// p1
		f.b030 = patch[1].pos;	// p2
		f.b003 = patch[2].pos;	// p3

		float3 n300 = patch[0].normal; // n1
		float3 n030 = patch[1].normal; // n2
		float3 n003 = patch[2].normal; // n3

		f.b210 = CalculateBezierPoints(f.b300, n300, f.b030);
		f.b120 = CalculateBezierPoints(f.b030, n030, f.b300);

		f.b021 = CalculateBezierPoints(f.b030, n030, f.b003);
		f.b012 = CalculateBezierPoints(f.b003, n003, f.b030);

		f.b201 = CalculateBezierPoints(f.b300, n300, f.b003);
		f.b102 = CalculateBezierPoints(f.b003, n003, f.b300);
		
		float3 ee = (f.b210 + f.b120 + f.b021 + f.b012 + f.b102 + f.b201) / 6.0f;
		float3 vv = (f.b300 + f.b030 + f.b003) / 3.;
		f.b111 = ee + (ee - vv) / 2.;

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

	float3 BarInterpolate(float3 barCoord, float3 p0, float3 p1, float3 p2) {
		return barCoord.x * p0 +
			barCoord.y * p1 +
			barCoord.z * p2;
	}


	[UNITY_domain("tri")]
	VertexStage_Output TessDomainShader(TessellationFactors f, OutputPatch<VertexStage_Input, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
		VertexStage_Input vInput;

		#define TESS_DOMAIN_SHADER_INTERPOLATE(fieldName) vInput.fieldName = \
					patch[0].fieldName * barycentricCoordinates.z + \
					patch[1].fieldName * barycentricCoordinates.x + \
					patch[2].fieldName * barycentricCoordinates.y;

		const float u = barycentricCoordinates.x;
		const float v = barycentricCoordinates.y;
		const float w = barycentricCoordinates.z;

		float3 position = f.b300*w*w*w + f.b030*u*u*u + f.b003*v*v*v +
						3.*(f.b210*u*w*w + f.b120*u*u*w + f.b201*v*w*w) + 
						3.*(f.b021*u*u*v + f.b102*v*v*w + f.b012*u*v*v) +
						6.*(f.b111*u*v*w);

		float3 n200 = normalize(patch[0].normal);
		float3 n020 = normalize(patch[1].normal);
		float3 n002 = normalize(patch[2].normal);

		float v12 = 2.0 * dot(f.b030 - f.b300, n200 + n020) / dot(f.b030 - f.b300, f.b030 - f.b300);
		float v23 = 2.0 * dot(f.b003 - f.b030, n020 + n002) / dot(f.b003 - f.b030, f.b003 - f.b030);
		float v31 = 2.0 * dot(f.b300 - f.b003, n002 + n200) / dot(f.b300 - f.b003, f.b300 - f.b003);

		float3 n110 = normalize(n200 + n020 - v12 * (f.b030 - f.b300));
		float3 n011 = normalize(n020 + n002 - v23 * (f.b003 - f.b030));
		float3 n101 = normalize(n002 + n200 - v31 * (f.b300 - f.b003));

		float3 normal = n200*w*w + n020*u*u + n002*v*v +
						n110*w*u + n011*u*v + n101*w*v;
		 
		TESS_DOMAIN_SHADER_INTERPOLATE(tangent);
		TESS_DOMAIN_SHADER_INTERPOLATE(uv);

		vInput.pos = float4(position, 1.);
		vInput.normal = normal;
		normalize(vInput.normal);
		normalize(vInput.tangent);

		return VertShader(vInput);
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
				float3 worldTangent = normalize(mul(unity_ObjectToWorld, float4(i.tangent, 0)));
				float3 worldBitangent = normalize(cross(worldNormal, worldTangent));

				float3 texNormal = normalize(tex2D(_NormalMap, i.uv) * 2.0f - 1.0f);
				float3x3 TBN = float3x3(worldTangent, worldBitangent, worldNormal);
				float3 n = normalize(mul(TBN, texNormal));

				float a = dot(viewDir, n);
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
