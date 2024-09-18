JHOSCMapStore.append((\min: 30, \max: 30), (\time: 30, \curve: 0.5), {
	|src, isActive|

	var fade_out = Env.linen( 30, 1, 1).kr(0, isActive).linlin(0, 1, 1, 0);

	var activeState = (
		'bass/amp': 0,
		'phase': LFNoise2.kr(10.reciprocal).range(3, 12) // dur
		|> Env.linen(0, 0, _)
		|> EnvGen.kr(_, src['syncron/trigger'])
	);
	var waitState = (
		'bass/amp': 0.2,
		'phase': 0,
	);
	var anxState = (
		'bass/amp': 1,
		'phase': 0,
	);

	var nodder = JHNodder(src['/webcam/nod/state'][0], src['syncron/state'],
		activeState, waitState, anxState
	);

	var current_phase = nodder.get('phase').lag2(0.2);
	var current_hard = current_phase * 2 |> _.fold(0, 1);
	var current_smooth = SinOsc.kr(0, current_phase * 2 * pi).range(0, 1).pow(2);
	var current_dir = Demand.kr(current_phase, -1, Dseq([-1, 1], inf));

	var global_amp = src['output/mixer/analysis/amplitude'].lag2ud(0.02, 0.1);
	var low_amp = src['slowWater/snd/analysis/amplitude/low'].lag2ud(0.05, 0.1);


	(
		'/Jellyfish/texture/velocity': [
			current_smooth * current_dir,
			current_hard * current_dir * 0.3
		].linlin(-1, 1, 0, 1),

		'/Jellyfish/texture/unique': 0.1,
		'/Jellyfish/texture/rotate': 0,
		'slowWater/snd/overlap': current_smooth,

		'bass/wobble/dry/amp': nodder.get('bass/amp').lag2ud(4, 0.2) * fade_out,
		'bass/wobble/freq': 1,
		'bass/wobble/comb/decay': nodder.get('bass/amp').lag2ud(2, 0.2),
		'bass/wobble/stick/freq': 1,
		'bass/wobble/bpf': 1 - low_amp
	)
	++
	(
		'slowWater/ctl/location': LFNoise2.kr(0.2!2).unipolar,
		'slowWater/snd/pan/pos': 0.25,
		'slowWater/snd/pan/focus': current_smooth,
		'slowWater/snd/dry/amp': current_smooth.linlin(0.8, 1, -60, -10).dbamp.lag(0.05) * fade_out,
		'slowWater/snd/wet/amp': current_smooth.linlin(0, 1, -25, -5).dbamp * fade_out,

		'waterGrain/output/dry/amp': 0,
		'waterGrain/output/wet/amp': 0,
	)
	++
	(
		'syncron/holdTime': 1,
		'syncron/waitTime': 0.0,
		'syncron/anxTime': 1,
		'syncron/visualCue': src['/webcam/nod/state'][1],

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.135,
	)
	++
	(
		'/Jellyfish/rotation':[0.5, 0.52, 0.22],
		'/Jellyfish/thickness': global_amp.linlin(0, 0.4, 0.4, 1),
		'/Jellyfish/brightness': global_amp * current_smooth * 0.6 * fade_out,
		'/Distort/size': low_amp * current_smooth,
		'/Distort/displacement': 0.51,
		'/Distort/blur': 0.4,
		'/Distort/force': [ 0.5, 0.51, 0.5 ],
	)
	++
	(
		'/Camera/force/default': 0.0,
		'/Jellyfish/position/large': 0.0,
		'/Sun/caustic/change': 0.0,
		'/Dust/noise': 0.0,
		'/Jellyfish/noise/timescale': 0.4,
		'/Jellyfish/noise/strength': 0.0,
		'/Jellyfish/width': 0.07,
		'/Jellyfish/noise/scale': [0.34, 0.47],
		'/Jellyfish/position': [ 0.33, 0.50, 0.36 ],
		'/global/force': [ 0.5, 0.5, 0.54 ],
		'/Sun/brightness': 0.0,
		'/Camera/fov': 0.072,
		'/Jellyfish/tension': 1.0,
		'/Jellyfish/decay': 0.95,
		'/Jellyfish/shape': 1,
		'/Camera/lookAt/lerp': 0.0,
	)
})


