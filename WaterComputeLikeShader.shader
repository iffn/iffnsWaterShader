Shader "iffnsShaders/WaterShader/WaterComputeLikeShader"
{
    Properties
    {
        phaseVelocitySquared("Phase velocity squared", Range(0.0001, 100)) = 0.02
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
        attenuation("Attenuation", Range(0.0001, 1)) = 0.999
        pmlThickness("pmlThickness", Range(0.0001, 10)) = 5
        sigmaMax("sigmaMax", Range(0.0001, 10)) = 5
        _depthTexture("DepthTexture", 2D) = "white"
        //OtherPublicParameterDefinitions
    }

    CGINCLUDE

    #include "UnityCustomRenderTexture.cginc"
    
    #define currentTexture(U)  tex2D(_SelfTexture2D, float2(U))

    float phaseVelocitySquared = 0.02;
    float attenuation = 0.999;
    sampler2D _depthTexture;
    float pmlThickness = 5; // Thickness of the PML region
    float sigmaMax = 5; // Maximum damping coefficient

    float computeSigma(float2 uv, float width, float height, float pmlThickness, float sigmaMax) {
        float sigma = 0.0;

        // Calculate distance to left/right boundaries
        float distLeft = uv.x * width;
        float distRight = (1.0 - uv.x) * width;

        // Calculate distance to top/bottom boundaries
        float distBottom = uv.y * height;
        float distTop = (1.0 - uv.y) * height;

        // Calculate sigma based on distance to nearest boundary
        if (distLeft < pmlThickness) {
            sigma = sigmaMax * (pmlThickness - distLeft) / pmlThickness;
        } else if (distRight < pmlThickness) {
            sigma = sigmaMax * (pmlThickness - distRight) / pmlThickness;
        }

        if (distBottom < pmlThickness) {
            sigma = max(sigma, sigmaMax * (pmlThickness - distBottom) / pmlThickness);
        } else if (distTop < pmlThickness) {
            sigma = max(sigma, sigmaMax * (pmlThickness - distTop) / pmlThickness);
        }

        return sigma;
    }

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

        // Calculate waves
        // Based on: https://github.com/hecomi/UnityWaterSurface/blob/master/Assets/WaterSimulation.shader
        float waveMotion = phaseVelocitySquared * (
            cellUpData.r +
            cellDownData.r +
            cellLeftData.r +
            cellRightData.r
            - 4 * cellData.r);
        
        float newWaveHeight = saturate(2 * cellData.r - cellData.g) + waveMotion;
        newWaveHeight = lerp(0.5, newWaveHeight, attenuation);
        
        // Prevent edge reflections
        float sigma = computeSigma(uv, _CustomRenderTextureWidth, _CustomRenderTextureHeight, pmlThickness, sigmaMax);
        //float dampingFactor = exp(-sigma * _Time.deltaTime);
        float dampingFactor = exp(-sigma * unity_DeltaTime.x);
        newWaveHeight *= dampingFactor;

        //newWaveHeight = (1 - isBoundaryPixelSignal) * newWaveHeight;// + isBoundaryPixel * 0.5;
        
        //float4 returnValue = float4(newWaveHeight, cellData.r, 0, 0);
        float4 returnValue = float4(newWaveHeight, cellData.r, 0, 0);

        // Depth camera
        /*
        float2 uvDepth = float2(-uv.x + 1, uv.y);
        float depthValueRaw = tex2D(_depthTexture, uvDepth);
        returnValue = saturate(sign(depthValueRaw) + returnValue);
        */
        
        float edgeWave = 1;
        returnValue.xy = (1-rightEdgeSignal) * returnValue.xy + rightEdgeSignal * (0.5, 0.5);
        returnValue.xy = (1-leftEdgeSignal) * returnValue.xy + leftEdgeSignal * edgeWave.xx;

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
