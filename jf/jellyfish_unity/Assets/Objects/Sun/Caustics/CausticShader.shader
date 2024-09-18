Shader "Unlit/CausticShader" {
	Properties {
		_TimePos("TimePos", Float) = 0
	}

	SubShader {
	   Lighting Off
	   Blend One Zero

	    Pass  {
		     CGPROGRAM

		    #include "UnityCustomRenderTexture.cginc"
		    #pragma vertex CustomRenderTextureVertexShader
		    #pragma fragment frag
		    #pragma target 3.0
			float _TimePos;


            float2 random2(float2 p){
				return frac(sin(float2(dot(p,float2(117.12,341.7)),dot(p,float2(269.5,123.3))))*43458.5453);
			}
            float4 frag(v2f_customrendertexture IN) : COLOR {
				float2 uv = IN.localTexcoord.xy;
				uv *= 6.0; //Scaling amount (larger number more cells can be seen)
				float2 iuv = floor(uv); //gets integer values no floating point
				float2 fuv = frac(uv); // gets only the fractional part
				float minDist = 1.0;  // minimun distance
				for (int y = -1; y <= 1; y++) {
					for (int x = -1; x <= 1; x++) {
						// Position of neighbour on the grid
						float2 neighbour = float2(float(x), float(y));
						// Random position from current + neighbour place in the grid
						float2 pointv = random2(iuv + neighbour);
						// Move the point with time
						pointv = 0.5 + 0.5*sin(_TimePos + 6.2236*pointv);//each point moves in a certain way
																		// Vector between the pixel and the point
						float2 diff = neighbour + pointv - fuv;
						// Distance to the point
						float dist = length(diff);
						// Keep the closer distance
						minDist = min(minDist, dist);
					}
				}
                minDist = minDist * minDist * minDist * minDist * minDist * minDist * minDist;
				return float4(minDist,minDist,minDist,1);
			}


		   ENDCG
		}
	}
}
