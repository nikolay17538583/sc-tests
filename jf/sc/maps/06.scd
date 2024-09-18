JHOSCMapStore.append((\min: 120, \max: 120), (\time: 30, \curve: 2), {
	|src, isActive|

	var closer = Env([1, 0], 120, 4).kr(gate: isActive);

	var nod = src['/webcam/nod/state'][1];
	var nod_chance = 1 - closer;
	var nod_fitler = Demand.kr(nod, 0, Dwrand([1, 0], [nod_chance, 1 - nod_chance], inf));
	var pre_t = Dust.kr(0.25) + (nod * nod_fitler);
	var t = DelayN.kr(pre_t, 0.5, 0.5);

	var rot = Demand.kr(t, 0, Dwhite(
		[0.35, 0.4, 0.4],
		[0.6, 0.62, 0.65]
	));

	var width = Demand.kr(t, 0, LFNoise2.kr(0.3).range(0.6, 1));
	var shape = Demand.kr(t, 0, LFNoise2.kr(0.15).range(0.2, 0.7) * closer);

	var pre_env = Env([0, 0.5, 0.0, 0], [0.25, 0.125, 0.125], 2, 1).kr(gate: Trig.kr(pre_t, 0.5));
	var env = Env.perc(0.1, 2).kr(gate: t);

	var wamp = LeakDC.kr(src['slowWater/snd/analysis/amplitude']) * env.lag2ud(0, 1);

	var pre_wob = SinOsc.kr(
		pre_env.linlin(0, 0.5, 0, 1.5)!3,
		LFNoise2.kr(0.01!3),
	).range(-0.005, 0.005);
	var headlr = src['/webcam/pos/forehead'][0];


	(
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.135,
	)
	++
	(
		'/Jellyfish/shape': shape + wamp,
		'/global/force': [
			0.50,
			env.lag2ud(0, 1).linlin(0, 1, 0, 1),
			rot[0].linlin(0.41, 0.56, 0, 1).blend(0.5, env.lag2ud(0, 1))
		],
		'/Jellyfish/rotation': rot + pre_wob + [0, headlr.linlin(0,1, 0.4, 0.6), 0],
		'/Jellyfish/width': width,
		'/Jellyfish/brightness': (pre_env + env.lag2ud(0, 5)).clip,

		'/Jellyfish/texture/velocity': env.lag2ud(0.1, 0.7) + pre_env.linlin(0, 0.2, 0, 0.8) |> (_.linlin(0,1, 0.5, 1)),
		'/Jellyfish/thickness': pre_env + env.lag2ud(0.1, 2).linlin(0, 1, 0.2, 1) |> (_.clip),

		'/Sun/caustic/change': src['output/mixer/analysis/amplitude'].linlin(0.2, 0.5, 0, 0.4).lag2ud(0, 5),
		'/Sun/brightness': (1 - env).linlin(0, 1, 0, 0.6),

		'/Jellyfish/position': [closer.linlin(0, 1, 0.6, 0.2), 0.55, 0.47],
	)
	++
	(
		'slowWater/ctl/location': [rot[0], rot[1]] + [0, 0.2] |> (_.lag2(0.5)),
		'slowWater/snd/dry/amp': env.lag2ud(0.01, 0.75),
		'slowWater/snd/wet/amp': 0.4,
		'slowWater/snd/pan/blur': 0.25,
		'slowWater/snd/pan/focus': 0.35,
		'slowWater/snd/pan/pos': rot[0].linlin(0.41, 0.56, 0, 1),

		'waterGrain/output/dry/amp': -12.dbamp,
		'waterGrain/output/wet/amp': -15.dbamp,
		'waterGrain/input/location': rot[0..1],
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/overlap': 0.5,
		'waterGrain/output/radius': 1,
	)
	++
	(
		'/Camera/force/default': 0.0,
		'/Distort/size': 0.0,
		'/Jellyfish/position/large': 0.0,
		'/Dust/noise': 0.0,
		'/Jellyfish/noise/timescale': 0.2,
		'/Jellyfish/noise/strength': 0.0,
		'/Jellyfish/noise/scale': [0.0, 0.0],
		'/Distort/force': [0.5, 0.5, 0.5],
		'/Camera/fov': 0.18,
		'/Jellyfish/tension': 1.0,
		'/Jellyfish/decay': 0.95,
		'/Distort/displacement': 0.0,
		'/Camera/lookAt/lerp': 0.0
	)
})
