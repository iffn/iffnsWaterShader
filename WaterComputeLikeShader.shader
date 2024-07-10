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
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    sampler2D _depthTexture;

    //OtherParameterDefinitions

    float4 frag(v2f_customrendertexture i) : SV_Target
    {
        /*
        Naming convention:
        - Data: r = last frame state, g = state before last frame
        - Signal: 1 if it applies, 0 if not
        */

        // Time adjustments:
        //phaseVelocitySquared *= unity_DeltaTime.x;
        //attenuation = pow(attenuation, unity_DeltaTime.x);

        // Pixel coordinates:
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

        // Waves:
        // Store edge values for boundary check
        float leftEdgeSignal = step(uv.x, pixelWidthU);
        float topEdgeSignal = step(uv.y, pixelWidthV);
        float rightEdgeSignal = step(1.0 - pixelWidthU, uv.x);
        float bottomEdgeSignal = step(1.0 - pixelWidthV, uv.y);

        // Compute isBoundaryPixel by combining edge checks
        float isBoundaryPixelSignal = saturate(leftEdgeSignal + topEdgeSignal + rightEdgeSignal + bottomEdgeSignal);

        // Compute the new state as usual
        // Based on: https://github.com/hecomi/UnityWaterSurface/blob/master/Assets/WaterSimulation.shader
        
        float waveMotion = phaseVelocitySquared * (
            cellUpData.r +
            cellDownData.r +
            cellLeftData.r +
            cellRightData.r
            - 4 * cellData.r);
        
        //float newWaveHeight = (cellData.r + cellData.g)*0.5;// + waveMotion;
        float newWaveHeight = saturate(2 * cellData.r - cellData.g);// + waveMotion;    
        newWaveHeight = lerp(0.5, newWaveHeight, attenuation);
        
        // Prevent edge reflections
        //newWaveHeight = (1 - isBoundaryPixelSignal) * newWaveHeight;// + isBoundaryPixel * 0.5;

        float4 returnValue = float4(newWaveHeight, cellData.r, 1, 0);

        // Depth camera
        
        float2 uvDepth = float2(-uv.x + 1, uv.y);
        float depthValueRaw = tex2D(_depthTexture, uvDepth);
        returnValue = saturate(sign(depthValueRaw) + returnValue);
        
        return returnValue;
        //return cellData;
        
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
