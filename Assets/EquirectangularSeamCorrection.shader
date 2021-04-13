// Equirectangular Seam Correction test suite shader
// Ben Golus 2021

Shader "Equirectangular Seam Correction"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Default, Coarse, Fine)] _Accuracy ("fwidth Accuracy", Float) = 0
        [KeywordEnum(None, Tarini, Explicit LOD, Explicit Gradients, Coarse Emulation, Whole Quad Derivatives)] _SeamCorrection ("Seam Correction", Float) = 0
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

            #pragma multi_compile_local _ _ACCURACY_COARSE _ACCURACY_FINE
            #pragma multi_compile_local _ _SEAMCORRECTION_TARINI _SEAMCORRECTION_EXPLICIT_LOD _SEAMCORRECTION_EXPLICIT_GRADIENTS _SEAMCORRECTION_COARSE_EMULATION _SEAMCORRECTION_WHOLE_QUAD_DERIVATIVES

            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 vertex : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.vertex = v.vertex.xyz;
                return o;
            }

            // allow derivative accuracy to be selected
        #if defined(_ACCURACY_COARSE)
            #define fwidthCustom(a) (abs(ddx_coarse(a)) + abs(ddy_coarse(a)))
            #define ddxCustom(a) ddx_coarse(a)
            #define ddyCustom(a) ddy_coarse(a)
        #elif defined(_ACCURACY_FINE)
            #define fwidthCustom(a) (abs(ddx_fine(a)) + abs(ddy_fine(a)))
            #define ddxCustom(a) ddx_fine(a)
            #define ddyCustom(a) ddy_fine(a)
        #else // default derivative functions
            #define fwidthCustom(a) fwidth(a)
            #define ddxCustom(a) ddx(a)
            #define ddyCustom(a) ddy(a)
        #endif

            float CalcMipLevel(float2 texture_coord)
            {
                float2 dx = ddxCustom(texture_coord);
                float2 dy = ddyCustom(texture_coord);
                float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
                
                return max(0.0, 0.5 * log2(delta_max_sqr));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // equirectangular UVs

                // normal from interpolated object space position
                float3 normal = normalize(i.vertex);

                // atan returns a value between -pi and pi
                // so we divide by pi * 2 to get -0.5 to 0.5
                float phi = atan2(normal.z, normal.x) / (UNITY_PI * 2.0);

                // 0.0 to 1.0 range
                float phi_frac = frac(phi);

                // acos returns 0.0 at the top, pi at the bottom
                // so we flip the y to align with Unity's OpenGL style
                // texture UVs so 0.0 is at the bottom
                float theta = acos(-normal.y) / UNITY_PI;

            #if defined(_SEAMCORRECTION_TARINI)
                // construct the uvs, selecting the phi to use based on the derivatives
                // this is based on this article
                // http://vcg.isti.cnr.it/~tarini/no-seams/
                float2 uv = float2(
                    fwidthCustom(phi) - 0.0001 < fwidthCustom(phi_frac) ? phi : phi_frac,
                    theta
                    );

                // sample the texture normally
                fixed4 col = tex2D(_MainTex, uv);

            #elif defined(_SEAMCORRECTION_EXPLICIT_LOD)
                // construct the primary uv
                float2 uvA = float2(phi, theta);

                // construct the secondary uv using phi_frac
                float2 uvB = float2(phi_frac, theta);

                // get the min mip level of either uv sets
                // _TextureName_TexelSize.zw is the texture resolution
                float mipLevel = min(
                    CalcMipLevel(uvA * _MainTex_TexelSize.zw),
                    CalcMipLevel(uvB * _MainTex_TexelSize.zw)
                );

                // sample texture with explicit mip level
                // the z component is 0.0 because it does nothing
                fixed4 col = tex2Dlod(_MainTex, float4(uvA, 0.0, mipLevel));

            #elif defined(_SEAMCORRECTION_EXPLICIT_GRADIENTS)
                // construct uv without doing anything special
                float2 uv = float2(phi, theta);

                // get derivatives for phi and phi_frac
                float phi_dx = ddxCustom(phi);
                float phi_dy = ddyCustom(phi);

                float phi_frac_dx = ddxCustom(phi_frac);
                float phi_frac_dy = ddyCustom(phi_frac);

                // select the smallest absolute derivatives between phi and phi_frac
                float2 dx = float2(
                    abs(phi_dx) - 0.0001 < abs(phi_frac_dx) ? phi_dx : phi_frac_dx,
                    ddxCustom(theta)
                );

                float2 dy = float2(
                    abs(phi_dy) - 0.0001 < abs(phi_frac_dy) ? phi_dy : phi_frac_dy,
                    ddyCustom(theta)
                );

                // sample the texture using our own derivatives
                fixed4 col = tex2Dgrad(_MainTex, uv, dx, dy);

            #elif defined(_SEAMCORRECTION_COARSE_EMULATION) || defined(_SEAMCORRECTION_WHOLE_QUAD_DERIVATIVES)
                // get position within quad
                int2 pixelQuadPos = uint2(i.pos.xy) % 2;
                float2 pixelQuadDir = float2(pixelQuadPos) * 2.0 - 1.0;

                // get derivatives for phi and phi_frac
                float phi_dx = ddxCustom(phi);
                float phi_dy = ddyCustom(phi);

                float phi_frac_dx = ddxCustom(phi_frac);
                float phi_frac_dy = ddyCustom(phi_frac);

                // get derivatives the "other" pixel column / row in the quad
                float phi_dxy = ddxCustom(phi - phi_dy * pixelQuadDir.y);
                float phi_dyx = ddyCustom(phi - phi_dx * pixelQuadDir.x);

                float phi_frac_dxy = ddxCustom(phi_frac - phi_frac_dy * pixelQuadDir.y);
                float phi_frac_dyx = ddyCustom(phi_frac - phi_frac_dx * pixelQuadDir.x);

            #if defined(_SEAMCORRECTION_COARSE_EMULATION)
                // check which column / row in the quad this is and use alternate
                // derivatives if it's not the column / row coarse would use
                if (pixelQuadPos.x == 1)
                {
                    phi_dy = phi_dyx;
                    phi_frac_dy = phi_frac_dyx;
                }
                if (pixelQuadPos.y == 1)
                {
                    phi_dx = phi_dxy;
                    phi_frac_dx = phi_frac_dxy;
                }
            #elif defined(_SEAMCORRECTION_WHOLE_QUAD_DERIVATIVES)
                // get the worst derivatives for the entire quad
                phi_dx = max(abs(phi_dx), abs(phi_dxy));
                phi_dy = max(abs(phi_dy), abs(phi_dyx));
                phi_frac_dx = max(abs(phi_frac_dx), abs(phi_frac_dxy));
                phi_frac_dy = max(abs(phi_frac_dy), abs(phi_frac_dyx));
            #endif

                // fwidth equivalents
                float phi_fw = abs(phi_dx) + abs(phi_dy);
                float phi_frac_fw = abs(phi_frac_dx) + abs(phi_frac_dy);

                // construct uvs like Tarini's method
                float2 uv = float2(phi_fw - 0.0001 < phi_frac_fw ? phi : phi_frac, theta);

                // sample the texture normally
                fixed4 col = tex2D(_MainTex, uv);

            #else // no correction
                float2 uv = float2(phi, theta);
                fixed4 col = tex2D(_MainTex, uv);

            #endif

                return col;
            }
            ENDCG
        }
    }
}
