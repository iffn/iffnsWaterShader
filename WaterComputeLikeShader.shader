Shader "iffnsShaders/WaterShader/WaterComputeLikeShader"
{
    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
        a("a", Range(0.0001, 1)) = 0.9
        b("b", Range(0.0001, 1)) = 0.9
        //OtherPublicParameterDefinitions
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    float a = 0.9;
    float b = 0.9;
    sampler2D _depthTexture;

    float corner(float x, float a, float b) {return min((1-a)/(b-1)*(x-b)+1, 1);}
    
    float4 frag(v2f_customrendertexture i) : SV_Target
    {
        /*
        Naming convention:
        - Data: r = last frame state, g = state before last frame
        - Signal: 1 if it applies, 0 if not
        */

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

        // Store edge values for boundary check
        float leftEdgeSignal = step(uv.x, pixelWidthU);
        float topEdgeSignal = step(uv.y, pixelWidthV);
        float rightEdgeSignal = step(1.0 - pixelWidthU, uv.x);
        float bottomEdgeSignal = step(1.0 - pixelWidthV, uv.y);

        // Compute isBoundaryPixel by combining edge checks
        float isBoundaryPixelSignal = saturate(leftEdgeSignal + topEdgeSignal + rightEdgeSignal + bottomEdgeSignal);
        float isNotBoundaryPixelSignal = 1 - isBoundaryPixelSignal;

        // Zero gradient boundary conditions
        cellLeftData.r = lerp(cellLeftData.r, cellData.r, leftEdgeSignal);
        cellRightData.r = lerp(cellRightData.r, cellData.r, rightEdgeSignal);
        cellUpData.r = lerp(cellUpData.r, cellData.r, topEdgeSignal);
        cellDownData.r = lerp(cellDownData.r, cellData.r, bottomEdgeSignal);

        // Attenuation with edge reflection prevention
        float attenuationMultiplier = corner(uv.x, a, b) * attenuation;

        // Calculate waves
        // Based on: https://github.com/hecomi/UnityWaterSurface/blob/master/Assets/WaterSimulation.shader
        float waveMotion = phaseVelocitySquared * (
            cellUpData.r +
            cellDownData.r +
            cellLeftData.r +
            cellRightData.r
            - 4 * cellData.r);

        float newWaveHeight = saturate(2 * cellData.r - cellData.g) + waveMotion;
        newWaveHeight = lerp(0.5, newWaveHeight, attenuationMultiplier);
        float4 returnValue = float4(newWaveHeight, cellData.r, 0, 0);
        
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
