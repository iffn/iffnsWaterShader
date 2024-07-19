Shader "iffnsShaders/WaterShader/InitializationShader"
{
    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        _depthTexture("DepthTexture", 2D) = "white"
        //OtherPublicParameterDefinitions
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    sampler2D _depthTexture;

    //OtherParameterDefinitions

    

    float4 frag(v2f_customrendertexture i) : SV_Target
    {
        //Retrn edge signal
        float2 uv = i.globalTexcoord;
        float pixelWidthU = 1.0 / _CustomRenderTextureWidth;
        float pixelWidthV = 1.0 / _CustomRenderTextureHeight;
        float4 duv = float4(pixelWidthU, pixelWidthV, 0 ,0);

        //Relative cell data:
        // r = current state, g = previous state
        float4 cellData = currentTexture(uv);
        float4 cellUpData = currentTexture(uv + duv.wy);
        float4 cellDownData = currentTexture(uv - duv.wy);
        float4 cellRightData = currentTexture(uv + duv.xw);
        float4 cellLeftData = currentTexture(uv - duv.xw);

        // Store edge values for boundary check
        float leftEdgeSignal = step(uv.x, pixelWidthU);

        float4 returnValue = float4(0.5, 0.5, 0, 0);

        //Center signal
        /*
        float horizontalCenter = -abs(uv.x-0.5)+0.1;
        float verticalCenter = -abs(uv.y-0.5)+0.1;
        float center = horizontalCenter + verticalCenter;
        center = max(center, 0) * 5;
        returnValue.xy += center;
        */
        
        //Left edge signal
        returnValue = (1-leftEdgeSignal) * returnValue + leftEdgeSignal * (1, 1, 0, 0);

        return returnValue;

        //Return flat
        return float4(0.5, 0.5, 0, 0);
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
