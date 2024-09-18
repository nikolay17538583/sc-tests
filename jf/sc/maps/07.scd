JHOSCMapStore.append((\min: 120, \max: 120), (\time: 30, \curve: 0), {
	|src, isActive|

	var current_phase = {
		var space = LFNoise2.kr(30.reciprocal).range(3, 7);
		var dur = space * LFNoise2.kr(20.reciprocal).range(0.3, 0.9);
		var trig = Impulse.kr(space.reciprocal);
		Slew.kr(Trig.kr(trig, dur), dur.reciprocal, inf);
	}.();

	var current_hard = current_phase.linlin(0, 1, 0, 2).fold(0, 1);
	var current_smooth = SinOsc.kr(0, current_phase * 2 * pi).range(0, 1).pow(3);
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
	)
	++
	(
		'slowWater/ctl/location': LFNoise2.kr(0.2!2).unipolar,
		'slowWater/snd/pan/pos': 0.25,
		'slowWater/snd/pan/focus': current_smooth,
		'slowWater/snd/dry/amp': 0,// current_smooth.linlin(0, 1, -20, -5).dbamp,
		'slowWater/snd/wet/amp': current_smooth.linlin(0, 1, -25, -5).dbamp,

		'waterGrain/output/dry/amp': 0,
		'waterGrain/output/wet/amp': 0,
	)
	++
	(
		'syncron/holdTime': 1,
		'syncron/waitTime': 1,
		'syncron/anxTime': 1,
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.135,
	)
	++
	(
		'/Jellyfish/rotation':[low_amp.linlin(0, 1, 0.5, 0.35), 0.52, 0.22],
		'/Jellyfish/thickness': global_amp.linlin(0, 0.4, 0.4, 1),
		'/Jellyfish/brightness': global_amp * current_smooth * 0.3,
		'/Distort/size': low_amp * current_smooth,
		'/Distort/displacement': 0.51,
		'/Distort/blur': 0.2,
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


























