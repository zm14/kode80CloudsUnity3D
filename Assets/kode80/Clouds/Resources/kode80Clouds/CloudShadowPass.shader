﻿//***************************************************
//
//  Author: Ben Hopkins
//  Copyright (C) 2016 kode80 LLC, 
//  all rights reserved
// 
//  Free to use for non-commercial purposes, 
//  see full license in project root:
//  kode80CloudsNonCommercialLicense.html
//  
//  Commercial licenses available for purchase from:
//  http://kode80.com/
//
//***************************************************

Shader "hidden/kode80/CloudShadowPass"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 ray : TEXCOORD1;
			};

			
			sampler2D _MainTex;
			sampler2D _CloudCoverage;
			sampler2D_float _CameraDepthTexture;
			float4x4 _InvCamera;
			float4x4 _InvProjection;
			float3 _Offset;
			float _CoverageScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord;
				
				float4 cameraRay = float4( v.texcoord * 2.0 - 1.0, 1.0, 1.0);
				cameraRay = mul( _InvProjection, cameraRay);
				cameraRay = cameraRay / cameraRay.w;
				o.ray = cameraRay.xyz;
				
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 pixel = tex2D( _MainTex, i.uv);
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				depth = Linear01Depth( depth);
				float3 ray = i.ray * depth;
				float3 pos = mul( _InvCamera, float4( ray, 1.0)).xyz;
				
				float2 coverageUV = pos.xz * 0.0001;
				coverageUV += float2( 0.5, 0.5) + _Offset.xz * 0.2;
				
				float4 coverage = tex2D( _CloudCoverage, coverageUV);
				//half cloudShadow = step( 0.3, coverage.r * coverage.b) * 0.65;
				half cloudShadow = smoothstep( 0.0, 0.5, coverage.r) * 0.8;

				cloudShadow *= step( depth, 0.9999);
				cloudShadow = 1.0 - cloudShadow;
				
				// TEST PATTERN
				//return pixel * fmod( round(abs(pos.x)), 2.0) * fmod( round(abs(pos.z)), 2.0);
				
				return pixel * cloudShadow;
			}
			ENDCG
		}
	}
}
