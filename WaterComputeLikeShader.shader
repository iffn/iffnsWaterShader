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
        // Time adjustments:
        phaseVelocitySquared *= unity_DeltaTime.x;
        //attenuation = pow(attenuation, unity_DeltaTime.x);

        // Pixel coordinates:
        float2 uv = i.globalTexcoord;
        float pixelWidthU = 1.0 / _CustomRenderTextureWidth;
        float pixelWidthV = 1.0 / _CustomRenderTextureHeight;
        float4 duv = float4(pixelWidthU, pixelWidthV, 0 ,0);

        // Waves:
        // r = current state, g = previous state
        float2 prevState = tex2D(_SelfTexture2D, uv);

        // Store edge values for boundary check
        float leftEdge = step(uv.x, pixelWidthU);
        float topEdge = step(uv.y, pixelWidthV);
        float rightEdge = step(1.0 - pixelWidthU, uv.x);
        float bottomEdge = step(1.0 - pixelWidthV, uv.y);

        // Compute isBoundaryPixel by combining edge checks
        float isBoundaryPixel = saturate(leftEdge + topEdge + rightEdge + bottomEdge);

        // Compute the new state as usual
        float newState = (2 * prevState.r - prevState.g + phaseVelocitySquared * (
            tex2D(_SelfTexture2D, uv - duv.zy).r +
            tex2D(_SelfTexture2D, uv + duv.zy).r +
            tex2D(_SelfTexture2D, uv - duv.xz).r +
            tex2D(_SelfTexture2D, uv + duv.xz).r
            - 4 * prevState.r)
        ) * attenuation;

        // Prevent edge reflections
        newState = (1 - isBoundaryPixel) * newState;// + isBoundaryPixel * 0.5;

        float4 returnValue = float4(newState, prevState.r, 0, 0);

        // Depth camera
        float2 uvDepth = float2(-uv.x + 1, uv.y);
        float depthValueRaw = tex2D(_depthTexture, uvDepth);
        returnValue = saturate(sign(depthValueRaw) + returnValue);

        return returnValue;

        //Relative cells:
        /*
        float4 cell = A(uv);
        float4 cellUp = A(uv + duv.wy);
        float4 cellDown = A(uv - duv.wy);
        float4 cellRight = A(uv + duv.xw);
        float4 cellLeft = A(uv - duv.xw);
        */

        //Drop waves https://github.com/hecomi/UnityWaterSurface/blob/master/Assets/WaterSimulation.shader
        
        //Edge wave:
        /*
        float edgeWave = sin(_Time.x * 30) * 0.5 + 0.5;
        returnValue.x = edgeInverse * returnValue.x + leftEdge * edgeWave;
        */
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
