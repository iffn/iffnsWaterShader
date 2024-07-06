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

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float d = 0.1;

                float x = 1 - sign(uv.x - d);

                float leftEdge = 1 - saturate(sign(uv.x - 0.01));
                float topEdge = 1 - saturate(sign(uv.y - 0.01));
                float rightEdge = 1 - saturate(sign(0.99 - uv.x));
                float bottomEdge = 1 - saturate(sign(0.99 - uv.y));

                return saturate(leftEdge + topEdge + rightEdge + bottomEdge);
                
                x = saturate(x);

                x = x * (sin(_Time.x * 20) * 0.5 + 0.5);
                

                fixed4 col = x;
                
                return col;
            }
            ENDCG
        }
    }
}
