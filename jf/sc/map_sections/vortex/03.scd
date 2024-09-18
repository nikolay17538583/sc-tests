JHOSCMapStore.append((\min: 30, \max: 30), (\time: 20, \curve: 2), {
	|src, isActive|
	var gtr_amp = src['in/mic/analysis/amplitude'];
	var movement = (   src['in/mic/analysis/skew/std'].blend(1, gtr_amp < 0.02)   ).lag2ud(0.2, 0.75);
	var bassAmp = src['bass/wobble/analysis/amplitude'] + src['waterGrain/output/analysis/amplitude'];
	var amp = (gtr_amp + (src['waterGrain/output/analysis/amplitude']))
	.linlin(0, 0.7, 0, 1).lag2(0.01, 0.5)
	|> DelayL.kr(_, 2, LFDNoise3.kr(0.08 * movement).range(0,2).pow(3));

	var wobs = {
		var orien = bassAmp * bassAmp * 12 * movement |> (_!3) |> LFDNoise3.kr(_) |> (_.range(0,1));
		var spinTheta = Phasor.kr(0, (0.05 + amp) / ControlRate.ir(), 0, 1);
		var spinVec = spinTheta * SelectX.kr(LFNoise2.kr(0.08).range(0,2), [ [1,0,0], [0,1,0], [0,0,1] ]);
		(orien + spinVec).wrap(0, 1)
	}.();

	var bam = amp * 1.5;
	var loc_min = [0.5, 0];
	var loc_max = [1, 0.45];
	var fadeIn = EnvGen.kr(Env([0, 0, 1, 1], 25, 1.5, releaseNode: 2), isActive);
	var extreme = bam > 0.4;

	var width_amp = (0.1 + bassAmp.lincurve(0, 0.5, 0, 1, -2) + bam.linlin(0, 0.5, 0, 1))
	.clip(0, 1).lag2(0.1, 0.3);
	var width_skew = 1 - movement;

	(
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.01
	)
	++
	(
		'/Camera/fov': 0.35 - (extreme * 0.07),
		'/Camera/force/default': 1,
		'/global/force': [0.0, 0.5, 0.5]
	)
	++
	(
		'/Distort/blur': bam.linlin(0.1, 1, 1, movement),
		'/Distort/displacement': bam.linlin(0.1, 1, 0.9, 0.7),
		'/Distort/force': [0, 0.5, 0.5],
		'/Distort/size': 0.4 + (extreme * 0.15)
	)
	++
	(
		'/Jellyfish/brightness': bam.clip(0.4, 1),
		'/Jellyfish/decay': 0.90.blend(0, extreme),
		'/Jellyfish/noise/strength': 0.0,
		'/Jellyfish/pid': [0.5, 0.14, 1],
		'/Jellyfish/position': [0.5, 0.5, 0.5],
		'/Jellyfish/position/large': 0,
		'/Jellyfish/rotation': wobs,
		'/Jellyfish/shape': extreme,
		'/Jellyfish/tension': 0.95,
		'/Jellyfish/tint': 0.5 + extreme.clip(0, 0.5),
		'/Jellyfish/width': width_amp.blend(width_skew, extreme)
	)
	++
	(
		'bass/wobble/dry/amp': (-10 + bam.linlin(0, 1, 0, 10)).dbamp,
		'bass/wobble/freq': LFNoise2.kr(0.1).range(0, 0.3),
		'bass/wobble/bpf': LFNoise2.kr(0.3).range(0, 0.7),
		'bass/wobble/comb/decay': LFNoise2.kr(0.1).range(0.4, 0.8),
		'bass/wobble/stick/freq': LFNoise0.kr(LFNoise0.kr(0.01).range(0.01, 0.4)).range(0.2, 0.6).blend(1, extreme)
	)
	++
	(
		'waterGrain/output/wet/amp': extreme * fadeIn.linlin(0, 1, -120, -25).dbamp,
		'waterGrain/output/dry/amp': fadeIn.linlin(0, 1, -99, -25.blend(-15, extreme)).dbamp,
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/radius': 1,
		'waterGrain/output/regularity': 1,
		'waterGrain/input/location': LFDNoise3.kr(amp.lincurve(0, 1, 0.01.blend(1, extreme), 1, 1.5)!2).range(loc_min, loc_max),

		'waterGrain/output/dur/scale': 0.2.blend(0.6, extreme),
		'waterGrain/output/overlap': 0.15.blend(0.5, extreme),

		'waterGrain/output/pan/pos': bassAmp.linlin(0, 0.4, 0, 1).lag(0.125),
		'waterGrain/output/pan/focus': bassAmp.linlin(0, 1, 0.7, 0)
	)
});
