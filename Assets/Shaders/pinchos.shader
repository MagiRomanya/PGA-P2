Shader "Custom/pinchos"
{
    Properties
    {
		[Header(Shading)]
        _Color("Color", Color) = (1,1,1,1)
        _SpikeHeight("Spike Height", float) = 1
		_QuadHalfLength("Quad Half Length", float) = 1
    }

	//--------------------------------------------------------------------------
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"

    float _SpikeHeight;
	float _QuadHalfLength;

	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	//--------------------------------------------------------------------------

	struct vertexInput{
		float4 vertex: POSITION;
		float3 normal: NORMAL;
		float4 tangent: TANGENT;
	};

	struct vertexOutput{
		float4 vertex : SV_POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
	};

	vertexOutput VertShader(vertexInput v)
	{
		// return UnityObjectToClipPos(vertex);
		vertexOutput o;
		o.vertex = v.vertex;
		o.normal = v.normal;
		o.tangent = v.tangent;
		return o;
	}

	//--------------------------------------------------------------------------

	struct geometryOutput
	{
		float4 pos: SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	geometryOutput GenerateVertex(vertexOutput v)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = float2(0, 0);
		return o;
	}

	geometryOutput GenerateVertex(float4 pos)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = float2(0, 0);
		return o;
	}

	//[maxvertexcount(10)]
 //   void GeoShader(triangle vertexOutput IN[3], inout TriangleStream<geometryOutput> triStream)
 //   {
	//	float3 centerPos = (IN[0].vertex + IN[1].vertex+ IN[2].vertex) / 3.0f;

 //       float3 triangleNormal = normalize(cross(IN[1].vertex - IN[0].vertex, IN[2].vertex - IN[0].vertex));

	//	triStream.Append(GenerateVertex(IN[0]));
	//	triStream.Append(GenerateVertex(IN[1]));
	//	triStream.Append(GenerateVertex(IN[2]));
	//	triStream.Append(GenerateVertex(float4(centerPos + triangleNormal, 1.0f)));
	//	triStream.Append(GenerateVertex(IN[0]));
	//	triStream.Append(GenerateVertex(IN[1]));
 //   }

 	[maxvertexcount(10)]
    void GeoShader(point vertexOutput IN[1], inout TriangleStream<geometryOutput> triStream)
    {
		float3 vPos = IN[0].vertex;

        float3 vNormal = IN[0].normal;
        float3 vTangent = IN[0].tangent;
        float3 vBitangent = cross(vNormal, vTangent);

        float offset = 0.25f;
		vPos = vPos + (vTangent * offset - vBitangent * offset)*2.0f;

		float3 p0 = vPos - vTangent * _QuadHalfLength + vBitangent * _QuadHalfLength; 
		float3 p1 = vPos + vTangent * _QuadHalfLength + vBitangent * _QuadHalfLength; 
		float3 p2 = vPos + vTangent * _QuadHalfLength - vBitangent * _QuadHalfLength; 
		float3 p3 = vPos - vTangent * _QuadHalfLength - vBitangent * _QuadHalfLength; 

        float3 p4 = vPos + vNormal * _SpikeHeight * (sin(_Time + vPos.x / 10)+2) / 3 + vBitangent * _QuadHalfLength * cos(_Time + vPos.x / 2);
        
		triStream.Append(GenerateVertex(float4(p0, 1.0f)));
		triStream.Append(GenerateVertex(float4(p1, 1.0f)));
		triStream.Append(GenerateVertex(float4(p4, 1.0f)));
		triStream.Append(GenerateVertex(float4(p2, 1.0f)));
		triStream.Append(GenerateVertex(float4(p3, 1.0f)));
		triStream.Append(GenerateVertex(float4(p0, 1.0f)));
		triStream.Append(GenerateVertex(float4(p4, 1.0f)));
		triStream.Append(GenerateVertex(float4(p3, 1.0f)));

		//triStream.Append(GenerateVertex(IN[0]));
		//triStream.Append(GenerateVertex(IN[1]));
		//triStream.Append(GenerateVertex(IN[2]));
		//triStream.Append(GenerateVertex(float4(centerPos + triangleNormal, 1.0f)));
		//triStream.Append(GenerateVertex(IN[0]));
		//triStream.Append(GenerateVertex(IN[1]));
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
            #pragma vertex VertShader
            #pragma fragment FragShader
			#pragma geometry GeoShader
			#pragma target 4.6
            
			#include "Lighting.cginc"

			float4 _Color;

			float4 FragShader (geometryOutput i, fixed facing : VFACE) : SV_Target
            {	
				return _Color * i.pos.z * 20;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
