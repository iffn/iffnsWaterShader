Shader "iffnsShaders/WaterShader/WaterComputeLikeShader"
{
    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    sampler2D _depthTexture;

    float pixelWidthU;
    float pixelWidthV;
    
    //Absorbtion caluclation based on: newAbsorbed in Buffer A from https://www.shadertoy.com/view/ctS3Dh
    float absorbtionValueNew(float valuePrev, float neighborNew, float neighborPrev, float timeStep)
    {
        return neighborPrev + (neighborNew - valuePrev) * (timeStep - 1.0) / (timeStep + 1.0);
    }

    float getNewWavePropagationData(float2 uv, float4 duv)
    {
        float4 cellData = currentTexture(uv);
        float4 cellLeftData = currentTexture(uv - duv.xw);
        float4 cellUpData = currentTexture(uv + duv.wy);
        float4 cellRightData = currentTexture(uv + duv.xw);
        float4 cellDownData = currentTexture(uv - duv.wy);

        float waveMotion = phaseVelocitySquared * (
            cellUpData.r +
            cellDownData.r +
            cellLeftData.r +
            cellRightData.r
            - 4 * cellData.r);
        
        float newWaveHeight = saturate(2 * cellData.r - cellData.g) + waveMotion;
        newWaveHeight = lerp(0.5, newWaveHeight, attenuation);

        return newWaveHeight;
    }

    float4 frag(v2f_customrendertexture i) : SV_Target
    {
        /*
        Naming convention:
        - Data: r = last frame state, g = state before last frame
        - Signal: 1 if it applies, 0 if not
        */

        // Pixel coordinates:
        float2 uv = i.globalTexcoord;
        pixelWidthU = 1.0 / _CustomRenderTextureWidth;
        pixelWidthV = 1.0 / _CustomRenderTextureHeight;
        float4 duv = float4(pixelWidthU, pixelWidthV, 0 ,0);

        float4 cellData = currentTexture(uv);

        //New wave height
        float newWaveHeight = getNewWavePropagationData(uv, duv);
        float4 returnValue = float4(newWaveHeight, cellData.r, 0, 0);

        // Store edge values for boundary check
        float leftEdgeSignal = step(uv.x, pixelWidthU);
        float topEdgeSignal = step(uv.y, pixelWidthV);
        float rightEdgeSignal = step(1.0 - pixelWidthU, uv.x);
        float bottomEdgeSignal = step(1.0 - pixelWidthV, uv.y);

        // Compute isBoundaryPixel by combining edge checks
        float isBoundaryPixelSignal = saturate(leftEdgeSignal + topEdgeSignal + rightEdgeSignal + bottomEdgeSignal);
        float isNotBoundaryPixelSignal = 1 - isBoundaryPixelSignal;

        // Edge absorbtion
        float newCellLeftData = getNewWavePropagationData(uv - duv.xw, duv);
        float absorbtionValue = absorbtionValueNew(cellData.x, newCellLeftData, cellData.x, 1);
        returnValue.x = lerp(returnValue.x, absorbtionValue, rightEdgeSignal);
        
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
