#ifdef WATERHEIGHT
	float GetWaterHeightMap(vec2 waterPos, vec3 nViewPos, vec2 wind) {
		float waveNoise = 0;
		#if WATER_STYLE >= 4
		vec2 waterPos2 = (89.286 * waterPos - floor(previousCameraPosition.xz)) * VXHEIGHT;
		float mapPosLength = max(abs(waterPos2.x), abs(waterPos2.y));
		waterPos2 += SHADOWRES / 2;
		if (true || mapPosLength > SHADOWRES / 2 - 10 * VXHEIGHT) {
		#endif
			vec2 noiseA = 0.5 - texture2D(noisetex, waterPos - wind * 0.6).rg;
			vec2 noiseB = 0.5 - texture2D(noisetex, waterPos * 2.0 + wind).rg;
			waveNoise = noiseA.r - noiseA.r * noiseB.r + noiseB.r * 0.6 + (noiseA.g + noiseB.g) * 2.5;
		#if WATER_STYLE >= 4
			if (mapPosLength > SHADOWRES / 2) {
		#endif
				return waveNoise;
		#if WATER_STYLE >= 4
			}
		}
		float waveMap = texture2D(colortex11, waterPos2 / (textureSize(colortex11, 0))).y * 100 - 50;
		float mixFactor = clamp((mapPosLength - SHADOWRES / 2) * 0.1 / VXHEIGHT + 1.0, 0, 1);
		return waveMap * (1 - mixFactor) + mixFactor * waveNoise;
		#endif
	}
#endif
#ifdef HASH33
	vec3 hash33(vec3 p3) {
		p3 = fract(p3 * vec3(.1031, .1030, .0973));
		p3 += dot(p3, p3.yxz+33.33);
		return fract((p3.xxy + p3.yxx)*p3.zyx);
	}
#endif
