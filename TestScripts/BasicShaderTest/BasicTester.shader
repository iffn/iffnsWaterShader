Shader "Unlit/BasicTester"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float left(float x){ return max(cos(x), sign(x)); }
            float right(float x) { return max(cos(x), sign(-x)); }
            float leftRight(float x) { return min(left(x*5-1.5),sign(-x+0.5)*0.5+0.5) + min(right(x*5-3.5),sign(x-0.5)*0.5+0.5);}
            
            float corner(float x, float a, float b) {return min((1-a)/(b-1)*(x-b)+1, 1);}

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float pixelWidthU = 0.02;
                float pixelWidthV = 0.02;

                // Store edge values for boundary check
                float leftEdgeSignal = step(uv.x, pixelWidthU);
                float topEdgeSignal = step(uv.y, pixelWidthV);
                float rightEdgeSignal = step(1.0 - pixelWidthU, uv.x);
                float bottomEdgeSignal = step(1.0 - pixelWidthV, uv.y);

                // Compute isBoundaryPixel by combining edge checks
                float isBoundaryPixelSignal = saturate(leftEdgeSignal + topEdgeSignal + rightEdgeSignal + bottomEdgeSignal);
                float isNotBoundaryPixelSignal = 1 - isBoundaryPixelSignal;

                // Pixels from left
                float pixelsFromLeft = uv.x / pixelWidthU;

                //sharp
                /*
                float horizontalEdgeMultiplier = -max(abs(uv.x-0.5)-0.3, 0) * 2;
                float verticalEdgeMultiplier = -max(abs(uv.y-0.5)-0.3, 0) * 2;
                float edgeMultipler = horizontalEdgeMultiplier + verticalEdgeMultiplier + 1;
                */

                //cos edges:
                float horizontalEdgeMultiplier = leftRight(uv.x);
                float verticalEdgeMultiplier = leftRight(uv.y);
                float edgeMultipler = saturate((horizontalEdgeMultiplier + verticalEdgeMultiplier) - 1);

                //return min(left(uv.x*5-1.5),sign(-uv.x+0.5)*0.5+0.5);
                //return corner(uv.x, 0.2, 0.5);

                //Edge waves
                float edgeWave = sin(_Time.y + uv.x + uv.y) * 0.5 + 0.5;
                return edgeWave.xxxx;

            }
            ENDCG
        }
    }
}
