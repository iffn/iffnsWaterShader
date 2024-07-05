Shader "iffnsShaders/WaterShader/WaterComputeLikeShader"
{
    

    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
        _depthTexture("DepthTexture", 2D) = "white"
        //OtherPublicParameterDefinitions
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define A(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    sampler2D _depthTexture;

    //OtherParameterDefinitions

    float4 frag(v2f_customrendertexture i) : SV_Target
    {
        //Time adjustments:
        float adjustetdPhaseVelocitySquared = phaseVelocitySquared * unity_DeltaTime.x;
        float adjustedAttenuation = 1 - ((1 - attenuation) * unity_DeltaTime.x);

        //Pixel coordinates:
        float2 uv = i.globalTexcoord;
        float pixelWidthU = 1.0 / _CustomRenderTextureWidth;
        float pixelWidthV = 1.0 / _CustomRenderTextureHeight;
        float4 duv = float4(pixelWidthU, pixelWidthV, 0 ,0);
        
        //Relative cells:
        float4 cell = A(uv);
        float4 cellUp = A(uv + duv.wy);
        float4 cellDown = A(uv - duv.wy);
        float4 cellRight = A(uv + duv.xw);
        float4 cellLeft = A(uv - duv.xw);

        //Edge:
        float leftEdge = 1 - saturate(sign(uv.x - pixelWidthU));
        float topEdge = 1 - saturate(sign(uv.y - pixelWidthV));
        float rightEdge = 1 - saturate(sign(1 - pixelWidthU - uv.x));
        float bottomEdge = 1 - saturate(sign(1 - pixelWidthV - uv.y));
        float edgeInverse = 1 - saturate(leftEdge + rightEdge + topEdge + bottomEdge);

        //Drop waves https://github.com/hecomi/UnityWaterSurface/blob/master/Assets/WaterSimulation.shader
        //r = current state, g = previous state
        float2 prevState = tex2D(_SelfTexture2D, uv);
        float newState = (2 * prevState.r - prevState.g + adjustetdPhaseVelocitySquared * (
            tex2D(_SelfTexture2D, uv - duv.zy).r +
            + tex2D(_SelfTexture2D, uv + duv.zy).r +
            + tex2D(_SelfTexture2D, uv - duv.xz).r +
            + tex2D(_SelfTexture2D, uv + duv.xz).r
            - 4 * prevState.r)
            ) * adjustedAttenuation;
        float4 returnValue = float4(newState, prevState.r, 0, 0);

        //Edge wave:
        float edgeWave = sin(_Time.x * 30) * 0.5 + 0.5;
        returnValue.x = edgeInverse * returnValue.x + leftEdge * edgeWave;

        //Depth camera
        float2 uvDepth = float2(-uv.x + 1, uv.y);
        float depthValueRaw = tex2D(_depthTexture, uvDepth);
        returnValue = saturate(sign(depthValueRaw) + returnValue);
        
        return returnValue;
    }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            Name "Update"
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            ENDCG
        }
    }
}
