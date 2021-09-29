
Shader "Clayxels/ClayxelPickingShaderMicroVoxel" {
	SubShader {
		Tags { "Queue" = "Geometry" "RenderType"="Opaque" }

		Pass {
			Lighting Off

			ZWrite On     
			
			CGPROGRAM
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag

			#include "clayxelMicroVoxelUtils.cginc"

			int selectMode = 0;
			int containerId = 0;

			struct Attributes
            {
                float4 positionOS   : POSITION;
                uint vertexID: SV_VertexID;
            };

            struct Varyings
            {
                float chunkId: TEXCOORD0;
                float3 voxelSpacePos: TEXCOORD1;
                float3 voxelSpaceViewDir: TEXCOORD2;
                float3 viewDirectionWS: TEXCOORD3;
                float3 boundsCenter: TEXCOORD4;
                float3 boundsSize: TEXCOORD5;
                float4 positionCS: SV_POSITION;
            };

			Varyings vert(Attributes input){
				Varyings output = (Varyings)0;

                output.chunkId = input.vertexID / 8;

                float3 vertexPos;
                float3 boundsCenter;
                float3 boundsSize;
                clayxels_microVoxels_vert(output.chunkId, input.vertexID, input.positionOS.xyz, vertexPos, boundsCenter, boundsSize);

                output.boundsCenter = boundsCenter;
                output.boundsSize = boundsSize;
                
                float4 positionWS = mul(objectMatrix, float4(vertexPos.xyz, 1));

                output.voxelSpacePos = vertexPos;
                output.voxelSpaceViewDir = mul(objectMatrixInv, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;

                output.viewDirectionWS = normalize(_WorldSpaceCameraPos - positionWS);

                output.positionCS = mul(UNITY_MATRIX_VP, positionWS);

                return output;
			}

			float4 frag(Varyings input, out float outDepth : SV_DepthLessEqual) : SV_Target {
				uint clayObjId = 0;
				
				float3 positionWS = input.voxelSpacePos;
                float3 viewDirectionWS = normalize(input.voxelSpaceViewDir - positionWS);
                
                float3 hitDepthPoint = 0;
				bool hit = clayxels_microVoxelsMip3Pick_frag(input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, clayObjId, hitDepthPoint);
				
				if(!hit){
					discard;
				}

				hitDepthPoint = mul(objectMatrix, float4(hitDepthPoint, 1)).xyz;
                float4 hitDepthPointScreen = mul(UNITY_MATRIX_VP, float4(hitDepthPoint, 1));
                outDepth = hitDepthPointScreen.z / hitDepthPointScreen.w;

				uint r = (clayObjId & 0x000000FF) >>  0;
				uint g = (clayObjId & 0x0000FF00) >>  8;
				uint b = (clayObjId & 0x00FF0000) >> 16;
				
				float4 outCol = float4(r / 255.0, g / 255.0, b / 255.0, containerId / 255.0);
				
				return outCol;
			}

			ENDCG
		}
	}
}