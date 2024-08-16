Shader "iffnsShaders/WaterShader/InitializationShader"
{
    Properties
    {
        //Simulation settings
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02

        //Runtime variables
        frameCount("Frame count", float) = 0

        //Waves
        wave1FbpRBH("Wave 1 FBP-R-B-H", Vector) = (100,10,0,1)
        wave2FbpRBH("Wave 2 FBP-R-B-H", Vector) = (150,5,10,1)

        _depthTexture("DepthTexture", 2D) = "white"
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    static const float TAU = 6.28318530717958647692;

    float phaseVelocitySquared = 0.02;
    float frameCount;
    float4 wave1FbpRBH;
    float4 wave2FbpRBH;

    //OtherParameterDefinitions

    float getSineWave(float frameCount, float2 uv, float framesBetweenPeaks, float wavesOnSurfaceFromRight, float wavesOnSurfaceFromBottom)
    {
        return sin(frameCount * TAU / framesBetweenPeaks + uv.x * TAU * wavesOnSurfaceFromRight + uv.y * TAU * wavesOnSurfaceFromBottom) * 0.25 + 0.25; //x+ = from right, y+ = from bottom
    }

    float2 newAndOldWaveHeight(float frameCount, float2 uv, float4 waveFbpRBH)
    {
        float newHeight = waveFbpRBH.w * getSineWave(frameCount, uv, waveFbpRBH.x, waveFbpRBH.y, waveFbpRBH.z);
        float oldHeight = waveFbpRBH.w * getSineWave(frameCount - 1, uv, waveFbpRBH.x, waveFbpRBH.y, waveFbpRBH.z);
        return float2(newHeight, oldHeight);
    }

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

        float4 returnValue = float4(0, 0, 0, 0);

        float newWaveHeight = 0;
        float oldWaveHeight = 0;
        float2 wave;

        wave = newAndOldWaveHeight(frameCount, uv, wave1FbpRBH);
        newWaveHeight += wave.x;
        oldWaveHeight += wave.y;

        wave = newAndOldWaveHeight(frameCount, uv, wave2FbpRBH);
        newWaveHeight += wave.x;
        oldWaveHeight += wave.y;

        return float4(newWaveHeight, oldWaveHeight, 0, 0);

        //Center signal
        /*
        float horizontalCenter = -abs(uv.x-0.5)+0.1;
        float verticalCenter = -abs(uv.y-0.5)+0.1;
        float center = horizontalCenter + verticalCenter;
        center = max(center, 0) * 5;
        returnValue.xy += center;
        */
        
        //Left edge signal
        returnValue = lerp(returnValue, (1, 1, 0, 0), leftEdgeSignal);

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
