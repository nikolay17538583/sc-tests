
var derivSpecX = JHImDerivative(2.pow(15));
var derivSpecY = JHImDerivative(2.pow(15));
var ampSpec = JHImAmplitude(128);
s.sync;

JHOSCMapStore.append((\min: 150, \max: 150), (\time: 10, \curve: 0.5), {
	|src, isActive|
	var togetherness = LFNoise2.kr(0.03).range(0, 1).pow(2);
	var togethernessB = LFNoise2.kr(0.03).range(0, 1).pow(3);

	var delayIm = DelayL.kr(_, 1, LFNoise2.kr(0.025).range(0, 1));

	var newampA = JHImitator.kr(ampSpec, _) <| src['in/mic/analysis/amplitude'].linlin(0, 1, 0, 4).clip(0, 1);
	var newamp = (newampA*5).clip(0, 1).blend(src['in/mic/analysis/amplitude'], togethernessB) |> delayIm;

	var x_in = src['in/mic/analysis/centroid'].linlin(0, 0.5, 0, 1);
	var x_im = JHImitator.kr(derivSpecX, x_in).blend(x_in, togetherness) |> delayIm;
	var y_in = src['in/mic/analysis/skewness'].linlin(0, 0.4, 0, 1);
	var y_im = JHImitator.kr(derivSpecY, y_in).blend(y_in, togetherness) |> delayIm;

	var movement = x_im.blend(1, newamp < 0.02).lag2ud(0.2, 0.75);

	var wobs = (_.wrap(0, 1)) <| Integrator.kr(_) <| (_ * newamp) <| SelectX.kr(_, [[1,0,0], [0,1,0], [0,0,1]]) <| LFNoise2.kr(0.08).range(0, 2);

	var bam = (newamp * 2).clip(0,1);
	var extreme = bam > 0.8;

	var width_amp = 0.1 + newamp.lincurve(0, 0.5, 0, 1, -2) + bam.linlin(0, 0.5, 0, 1) |> { |i| i.clip(0, 1).lag2(0.1, 0.3) };

	var lerper = JHBiLinear(
		[ 0.63267485317672, 0.43904808159301 ],
		[ 0.24719701014415, 0.70568237008256 ],
		[ 0.56967431927389, 0.82078678970374 ],
		[ 0.77042178323545, 0.6600291403594 ]
	);


	var distance_delay = DelayL.kr(_, 0.3, 0.3 * (1 - extreme));

	(
		'waterGrain/output/dry/amp': newamp.clip(0, 1) |> distance_delay,
		'waterGrain/output/wet/amp': (newamp * 0.05) + extreme.clip(0, 0.15) |> distance_delay,
		'waterGrain/output/update/rate': 0.4,
		'waterGrain/output/radius': 0,
		'waterGrain/output/regularity': 1,

		'waterGrain/output/dur/scale': 0.5,
		'waterGrain/output/overlap': 1,
		'waterGrain/input/location': lerper.(x_im, y_im) |> distance_delay,
	)
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
		'/Jellyfish/brightness': bam.clip(0.0, 1),
		'/Jellyfish/decay': 0.92.blend(0, extreme),
		'/Jellyfish/noise/strength': 0.0,
		'/Jellyfish/pid': [1, 1, 1],
		'/Jellyfish/position': [0.5, 0.5, 0.5],
		'/Jellyfish/position/large': 0,
		'/Jellyfish/rotation': wobs,
		'/Jellyfish/shape': extreme,
		'/Jellyfish/tension': 0.95,
		'/Jellyfish/tint': 0.5 + extreme.clip(0, 0.5),
		'/Jellyfish/width': width_amp.blend(1, extreme)
	)
	++
	(
		'bass/wobble/dry/amp': (-20 + bam.linlin(0, 1, 0, 15)).dbamp,
		'bass/wobble/freq': LFNoise2.kr(0.1).range(0, 0.3),
		'bass/wobble/bpf': LFNoise2.kr(0.1).range(0, 0.5),
		'bass/wobble/comb/decay': LFNoise2.kr(0.1).range(0.5, 0.8),
		'bass/wobble/stick/freq':  (_.range(0.2, 0.6)) <| LFNoise0.kr(_) <| (_.range(0.01, 0.4)) <| LFNoise0.kr(0.01) |> (_.blend(1, extreme))
	)
	++
	(
		'live/echoes/wet/amp': src['waterGrain/output/analysis/amplitude']
		.clip(0.15, 0.45)
		.lag2ud(0.1, 1.5),
		//	'live/echoes/ambi/press': 0.5
	)
});



