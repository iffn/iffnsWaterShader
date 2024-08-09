Shader "iffnsShaders/WaterShader/WaterComputeLikeShader"
{
    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
        absorptionTime("Absorption time", Range(0.0001, 150)) = 1
        depthMultiplier("Depth multiplier", Range(0.0001, 1)) = 0.2
        frameCount("Frame count", float) = 0
        depthCameraPosition("Depth camera position", float) = -50
        depthCameraFarClip("Depth camera far clip", float) = 60
        waveHeightMultiplier("Wave height multiplier", float) = 2
        testMultiplier("Test multiplier", float) = 2   
        _depthTexture("DepthTexture", 2D) = "white"
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    static const float TAU = 6.28318530717958647692;

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    float absorptionTime;
    float depthMultiplier;
    float depthCameraPosition;
    float depthCameraFarClip;
    float frameCount;
    float waveHeightMultiplier;
    float testMultiplier;
    sampler2D _depthTexture;

    float pixelWidthU;
    float pixelWidthV;
    
    //Absorbtion caluclation based on: newAbsorbed in Buffer A from https://www.shadertoy.com/view/ctS3Dh
    float absorbtionValueNew(float valuePrev, float neighborNew, float neighborPrev, float timeStep)
    {
        return neighborPrev + (neighborNew - valuePrev) * (timeStep - 1.0) / (timeStep + 1.0);
    }

    float heightValueFromDepthRaw(float depthValueRaw)
    {
        return lerp(depthCameraPosition + depthCameraFarClip, depthCameraPosition, depthValueRaw);
    }

    float waveHeightFromData(float waveData)
    {
        return (waveData - 0.5) * waveHeightMultiplier;
    }

    float getSineWave(float frameCount, float2 uv, float framesBetweenPeaks, float wavesOnSurfaceFromRight, float wavesOnSurfaceFromBottom)
    {
        return sin(frameCount * TAU / framesBetweenPeaks + uv.x * TAU * wavesOnSurfaceFromRight + uv.y * TAU * wavesOnSurfaceFromBottom) * 0.25 + 0.25; //x+ = from right, y+ = from bottom
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
        float4 cellLeftData = currentTexture(uv - duv.xw);
        float4 cellUpData = currentTexture(uv + duv.wy);
        float4 cellRightData = currentTexture(uv + duv.xw);
        float4 cellDownData = currentTexture(uv - duv.wy);

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
        float2 proximityCellPosition = lerp(uv, uv - duv.xw, rightEdgeSignal);
        proximityCellPosition = lerp(proximityCellPosition, uv + duv.wy, topEdgeSignal);
        proximityCellPosition = lerp(proximityCellPosition, uv + duv.xw, leftEdgeSignal);
        proximityCellPosition = lerp(proximityCellPosition, uv - duv.wy, bottomEdgeSignal);

        float newCellProximityData = getNewWavePropagationData(proximityCellPosition, duv);
        float absorbtionValue = absorbtionValueNew(cellData.x, newCellProximityData, currentTexture(proximityCellPosition).x, absorptionTime);
        returnValue.x = lerp(returnValue.x, absorbtionValue, isBoundaryPixelSignal);

        //Edge waves, x+ = from right, y+ = from bottom
        float framesBetweenPeaks = 100;
        float wavesOnSurfaceFromRight = 10;
        float wavesOnSurfaceFromBottom = 0;
        float edgeWave = getSineWave(frameCount, uv, framesBetweenPeaks, wavesOnSurfaceFromRight, wavesOnSurfaceFromBottom);

        framesBetweenPeaks = 150;
        wavesOnSurfaceFromRight = 5;
        wavesOnSurfaceFromBottom = 10;
        edgeWave += getSineWave(frameCount, uv, framesBetweenPeaks, wavesOnSurfaceFromRight, wavesOnSurfaceFromBottom);

        float edgeSignal = saturate(rightEdgeSignal + bottomEdgeSignal);
        edgeWave = lerp(returnValue.x, edgeWave, edgeSignal);
        returnValue.x = edgeWave;
        //return edgeWave.xxxx;
        
        //Depth camera
        float2 uvDepth = float2(-uv.x + 1, uv.y);
        float depthValueRaw = tex2D(_depthTexture, uvDepth);
        float depthValue = heightValueFromDepthRaw(depthValueRaw);
        float depthValuePrev = heightValueFromDepthRaw(cellData.z);
        float heightDifference = depthValuePrev - depthValue;
        float waveHeight = waveHeightFromData(cellData.x);
        float underWaterSignal = step(0, waveHeight - depthValue);
        float addition = heightDifference * depthMultiplier;
        addition = lerp(0, addition, underWaterSignal);

        //returnValue.x += addition;
        returnValue.z = depthValueRaw.x;

        //Apply data
        returnValue.x = saturate(returnValue.x);
        
        //return float4(0, addition, depthValueRaw.x, 0);

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