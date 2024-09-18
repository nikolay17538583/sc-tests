JHOSCMapStore.append((\min: 90, \max: 90), (\time: 10, \curve: 0.5), {
	|src, isActive|
	var gtr_amp = src['in/mic/analysis/amplitude'];
	var movement = (   src['in/mic/analysis/skew/std'].blend(1, gtr_amp < 0.02)   ).lag2ud(0.2, 0.75);
	var bassAmp = src['bass/wobble/analysis/amplitude'] + src['waterGrain/output/analysis/amplitude'];
	var amp = (gtr_amp + (src['waterGrain/output/analysis/amplitude']))
	.linlin(0, 0.7, 0, 1).lag2(0.01, 0.5)
	|> DelayL.kr(_, 2, LFDNoise3.kr(0.28 * movement * src['in/mic/analysis/centroid']).range(0,2).pow(3));

	var wobs = {
		var orien = bassAmp * bassAmp * 12 * movement |> (_!3) |> LFDNoise3.kr(_) |> (_.range(0,1));
		var spinTheta = Phasor.kr(0, (0.05 + (amp*2).lagud(0, 0.75)) / ControlRate.ir(), 0, 1);
		var spinVec = spinTheta * SelectX.kr(LFNoise2.kr(0.18).range(0,2), [ [1,0,0], [0,1,0], [0,0,1] ]);
		(orien + spinVec).wrap(0, 1)
	}.();

	var bam = amp * 1.5;
	var loc_min = [0.5, 0];
	var loc_max = [1, 0.45];
	var fadeIn = EnvGen.kr(Env([0, 0, 1, 1], 25, 1.5, releaseNode: 2), isActive);
	var extreme = bam > 0.7;

	var width_amp = (0.1 + bassAmp.lincurve(0, 0.5, 0, 1, -2) + bam.linlin(0, 0.5, 0, 1))
	.clip(0, 1).lag2(0.1, 0.3);
	var width_skew = 1 - movement;



	{   //water grain
		var amp = src['in/mic/analysis/amplitude'].lag2ud(0.01, 0.1);
		var x_in = src['in/mic/analysis/centroid'].linlin(0, 0.5, 0, 1);
		var y_in = src['in/mic/analysis/skewness'].linlin(0, 0.4, 0, 1);
		var lerper = JHBiLinear(
			[ 0.63267485317672, 0.43904808159301 ],
			[ 0.24719701014415, 0.70568237008256 ],
			[ 0.56967431927389, 0.82078678970374 ],
			[ 0.77042178323545, 0.6600291403594 ]
		);
		(
			'waterGrain/output/dry/amp': (amp * 5).clip(0, 1),
			'waterGrain/output/wet/amp': (amp * 0.05),
			'waterGrain/output/update/rate': 1,
			'waterGrain/output/radius': 0,
			'waterGrain/output/regularity': 1,

			'waterGrain/output/dur/scale': 0.5,
			'waterGrain/output/overlap':1,
			'waterGrain/input/location': lerper.(x_in, y_in),
		)
	}.()
	++
	(
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.015
	)
	++
	(
		'/Camera/fov': 0.225,
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
		'/Jellyfish/brightness': bam.clip(0.2, 1),
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
		'bass/wobble/dry/amp': (-20 + bam.linlin(0, 1, 0, 15)).dbamp,
		'bass/wobble/freq': LFNoise2.kr(0.1).range(0, 0.3),
		'bass/wobble/bpf': LFNoise2.kr(0.1).range(0, 0.5),
		'bass/wobble/comb/decay': LFNoise2.kr(0.1).range(0.5, 0.8),
		'bass/wobble/stick/freq': LFNoise0.kr(LFNoise0.kr(0.01).range(0.01, 0.4)).range(0.2, 0.6).blend(1, extreme)
	)
	++
	(
		'live/echoes/wet/amp': src['waterGrain/output/analysis/amplitude'].clip(0.15, 0.45).lag2ud(0.1, 1.5),
		//'live/echoes/ambi/press': 0.5
	)
});
