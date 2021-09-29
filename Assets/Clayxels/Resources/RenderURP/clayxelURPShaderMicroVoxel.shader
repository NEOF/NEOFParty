
Shader "Clayxels/ClayxelURPShaderMicroVoxel"
{
    Properties
    {
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        [ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SPECULARHIGHLIGHTS_OFF ("Specular Highlights", Float) = 1
        [Toggle(_EMISSION)] _EMISSION ("Enable Emission", Float) = 0
        [HDR]_EmissionColor("Emission", Color) = (0,0,0)

        [Toggle(_CLAYXELS_SSS)] _CLAYXELS_SSS ("Enable SubSurfaceScatter", Float) = 0
        [HDR]_subSurfaceScatter("SubSurfaceScatter", Color) = (0.0, 0.0, 0.0, 1.0)

        [ToggleOff(_RECEIVE_SHADOWS_OFF)] _RECEIVE_SHADOWS_OFF ("Receive Shadows", Float) = 1.0

        _roughColor("Rough Color", Range(0.0, 1.0)) = 0.0

        [KeywordEnum(Fine, Big, Blocky, Auto)] _LOD("Level Of Detail", Float) = 0
        
        _splatSizeLowDetail("BigSplat Size", Range(0.0, 1.0)) = 0.5
        _backFillDark("BigSplat Darkner", Range(0.0, 1.0)) = 0.0
        _alphaCutout("BigSplat Cutout", Range(0.0, 1.0)) = 0.0
        _roughOrientX("BigSplat Rough X", Range(-1.0, 1.0)) = 0.0
        _roughOrientY("BigSplat Rough Y", Range(-1.0, 1.0)) = 0.0
        _roughOffset("BigSplat Rough Offset", Range(-1.0, 1.0)) = 0.0

        [NoScaleOffset]_MainTex("BigSplat Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "StandardLit"
            Tags{"LightMode" = "UniversalForward"}

            ZWrite On 
            ZTest LEqual      
            Cull Back 

            HLSLPROGRAM

            #pragma target 4.5

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _OCCLUSIONMAP

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            #pragma shader_feature _CLAYXELS_SSS
            #pragma multi_compile _LOD_FINE _LOD_BIG _LOD_BLOCKY _LOD_AUTO
            #include "../clayxelMicroVoxelUtils.cginc"

            float _LOD;
            float _splatSizeLowDetail;
            float _backFillDark;
            float _alphaCutout;
            float4 _subSurfaceScatter;
            float _roughOrientX;
            float _roughOrientY;
            float _roughOffset;
            float _roughColor;

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
                float4 viewDirectionWS: TEXCOORD3;
                float3 boundsCenter: TEXCOORD4;
                float3 boundsSize: TEXCOORD5;
                float4 positionCS: SV_POSITION;
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                output.chunkId = input.vertexID / 8;

                float3 vertexPos;
                float3 boundsCenter;
                float3 boundsSize;
                clayxels_microVoxels_vert(output.chunkId, input.vertexID, input.positionOS.xyz, vertexPos, boundsCenter, boundsSize);

                output.boundsCenter = boundsCenter;
                output.boundsSize = boundsSize;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(mul((float3x3)objectMatrix, vertexPos.xyz));

                float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.voxelSpacePos = vertexPos;
                output.voxelSpaceViewDir = mul(objectMatrixInv, float4(GetCameraPositionWS().xyz, 1)).xyz;

                output.viewDirectionWS = float4(normalize(GetCameraPositionWS() - vertexInput.positionWS), fogFactor);

                output.positionCS = vertexInput.positionCS;

                return output;
            }

            half4 LitPassFragment(Varyings input, out float outDepth : SV_DepthGreaterEqual) : SV_Target
            {
                float3 positionWS = input.voxelSpacePos;
                float3 viewDirectionWS = normalize(input.voxelSpaceViewDir - positionWS);
                
                float3 hitNormal = 0;
                float3 hitColor = 0;
                float3 hitDepthPoint = 0;

                bool hit = false;

                float randomVal = (frac(sin(dot(float2(positionWS.x,positionWS.y),float2(12.9898,78.233+positionWS.z)))*43758.5453123) + 1.0);
                
                #if _LOD_FINE
                    hit = clayxels_microVoxelsMip3Splat_frag(_roughColor, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);
                #elif _LOD_BIG
                    float splatSize = lerp(0.3, 0.9, _splatSizeLowDetail);
                    float roughOffset = _roughOffset * 0.2;
                    hit = clayxels_microVoxelsMip2Tex_frag(_roughColor, splatSize, _roughOrientX, _roughOrientY, roughOffset, _alphaCutout * randomVal, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint); 
                    
                    if(!hit){
                        hit = clayxels_microVoxelsMip3Fast_frag(input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);     
                        hitColor *= 1.0 - _backFillDark;
                    }
                #elif _LOD_BLOCKY
                    hit = clayxels_microVoxelsMip3Vox_frag(_roughColor, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);
                #elif _LOD_AUTO
                    float distFromCamera = input.positionCS.w;
                    float lod = saturate(((distFromCamera - lodNear) / (lodFar - lodNear)));
                                
                    if(input.positionCS.z > (randomVal * 0.5) * lod){
                        hit = clayxels_microVoxelsMip3Splat_frag(_roughColor, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);
                    }
                    else{
                        if(input.positionCS.z > (randomVal * 0.1) * lod){
                            hit = clayxels_microVoxelsMip2Fast_frag(0.5, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);
                            
                            if(!hit){
                                hit = clayxels_microVoxelsMip3Fast_frag(input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint);     
                            }
                        }
                        else{
                            float splatSize = 1.0;
                            hit = clayxels_microVoxelsMip2Fast_frag(splatSize, input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitColor, hitDepthPoint); 
                        }
                    }
                #endif

                if(!hit){
                    discard;
                }

                hitNormal = normalize(mul((float3x3)objectMatrix, hitNormal).xyz);
                hitDepthPoint = mul(objectMatrix, float4(hitDepthPoint, 1)).xyz;
                
                float4 hitDepthPointScreen = mul(UNITY_MATRIX_VP, float4(hitDepthPoint, 1));

                outDepth = hitDepthPointScreen.z / hitDepthPointScreen.w;
                ////////////////////////////////////////////////

                // Surface data contains albedo, metallic, specular, smoothness, occlusion, emission and alpha
                // InitializeStandarLitSurfaceData initializes based on the rules for standard shader.
                // You can write your own function to initialize the surface data of your shader.
                SurfaceData surfaceData;
                float2 uv = float2(0, 0);
                InitializeStandardLitSurfaceData(uv, surfaceData);

                surfaceData.albedo = hitColor;

                #ifdef _CLAYXELS_SSS
                Light light = GetMainLight();
                float lightDistAttenuation = 0.0;
                float3 sssLightDir = light.direction;
                float3 sssLightColor = light.color;

                    #ifdef _ADDITIONAL_LIGHTS
                    int sssAdditionalLightsCount = GetAdditionalLightsCount();
                    for (int i = 0; i < sssAdditionalLightsCount; ++i){
                        Light sssExtraLight = GetAdditionalLight(i, hitDepthPoint);
                        sssLightColor += sssExtraLight.color * sssExtraLight.distanceAttenuation;
                    }
                    #endif

                surfaceData.emission += LightingSubsurface(sssLightDir, sssLightColor, hitNormal, _subSurfaceScatter, _subSurfaceScatter.w) + ((_subSurfaceScatter * lightDistAttenuation) * _subSurfaceScatter.w);
                #endif

#ifdef LIGHTMAP_ON
                float2 uvLM = float2(0, 0);
                half3 bakedGI = SampleLightmap(uvLM, hitNormal);
#else
                half3 bakedGI = SampleSH(hitNormal);
#endif
                
                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

#ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord = TransformWorldToShadowCoord(hitDepthPoint);
                Light mainLight = GetMainLight(shadowCoord);
#else
                Light mainLight = GetMainLight();
#endif

                half3 color = GlobalIllumination(brdfData, bakedGI, surfaceData.occlusion, hitNormal, input.viewDirectionWS.xyz);

                color += LightingPhysicallyBased(brdfData, mainLight, hitNormal, input.viewDirectionWS.xyz);

#ifdef _ADDITIONAL_LIGHTS

                int additionalLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < additionalLightsCount; ++i)
                {
                    Light light = GetAdditionalLight(i, hitDepthPoint);

                    color += LightingPhysicallyBased(brdfData, light, hitNormal, input.viewDirectionWS.xyz);
                }
#endif
                color += surfaceData.emission;

                float fogFactor = input.viewDirectionWS.w;

                color = MixFog(color, fogFactor);

                return half4(color, surfaceData.alpha);
            }

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible            
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.5

            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            #define AI_RENDERPIPELINE

            #include "../clayxelMicroVoxelUtils.cginc"

            #pragma shader_feature EFFECT_HUE_VARIATION

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

            Varyings ShadowPassVertex(Attributes input){
                Varyings output = (Varyings)0;
                
                output.chunkId = input.vertexID / 8;

                float3 vertexPos;
                float3 boundsCenter;
                float3 boundsSize;
                clayxels_microVoxels_vert(output.chunkId, input.vertexID, input.positionOS.xyz, vertexPos, boundsCenter, boundsSize);

                output.boundsCenter = boundsCenter;
                output.boundsSize = boundsSize;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(mul((float3x3)objectMatrix, vertexPos.xyz));

                output.positionCS = vertexInput.positionCS;

                output.voxelSpacePos = vertexPos;
                output.voxelSpaceViewDir = mul(objectMatrixInv, float4(_MainLightPosition.xyz, 1)).xyz;

                output.viewDirectionWS = mul((float3x3)objectMatrixInv, _MainLightPosition.xyz);

                return output;
            }

            half4 ShadowPassFragment(Varyings input, out float outDepth : SV_DepthGreaterEqual ) : SV_Target{
                float3 positionWS = input.voxelSpacePos;

                float3 viewDirectionWS = input.viewDirectionWS;

                float3 hitNormal;
                float3 hitColor;
                float3 hitDepthPoint;
                
                bool hit = clayxels_microVoxelsMip3Shadow_frag(input.chunkId, positionWS, viewDirectionWS, input.boundsCenter, input.boundsSize, hitNormal, hitDepthPoint);
                
                if(!hit){
                    discard;
                }

                hitDepthPoint = mul(objectMatrix, float4(hitDepthPoint, 1)).xyz;

                float4 hitDepthPointScreen = mul(UNITY_MATRIX_VP, float4(hitDepthPoint, 1));

                float shadowBias = 0.98; // force this bias to remove artifacts
                outDepth = ((hitDepthPointScreen.z / hitDepthPointScreen.w) * shadowBias);
                
                return 0;
            }

            ENDHLSL
        }

        // Used for depth prepass
        // If shadows cascade are enabled we need to perform a depth prepass. 
        // We also need to use a depth prepass in some cases camera require depth texture
        // (e.g, MSAA is enabled and we can't resolve with Texture2DMS
        // UsePass "Universal Render Pipeline/Lit/DepthOnly"

        // Used for Baking GI. This pass is stripped from build.
        // UsePass "Universal Render Pipeline/Lit/Meta"
    }
}