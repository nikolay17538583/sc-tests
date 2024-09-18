JHOSCMapStore.append((\min: 60, \max: 60), (\time: 3, \curve: 2), {
	|src, isActive|
	var bassAmp = src['bass/wobble/analysis/amplitude'];
	var amp = src['in/mic/analysis/amplitude'].linlin(0, 0.3, 0, 1).lag2(0.01, 0.5);
	var wobs = {
		var orien = bassAmp * bassAmp * 10 |> (_!3) |> LFDNoise3.kr(_) |> (_.range(0,1));
		var spinTheta = Phasor.kr(0, amp / ControlRate.ir(), 0, 1);
		var spinVec = spinTheta * SelectX.kr(LFNoise2.kr(0.05).range(0,2), [ [1,0,0], [0,1,0], [0,0,1] ]);
		(orien + spinVec).wrap(0, 1)
	}.();

	var bam = (0.0 + (amp * 2)).clip(0, 1);

	JHImport(~pwd +/+ "map_util/waterGrain_nil.scd").()
	++
	(
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.01,
	)
	++
	(
		'/Camera/fov': 0.3,
		'/Camera/force/default': 1,
		'/global/force': [0.0, 0.5, 0.5]
	)
	++
	(
		'/Distort/blur': bam.linlin(0.1, 1, 1, 0.5),
		'/Distort/displacement': bam.linlin(0.1, 1, 0.8, 0.58),
		'/Distort/force': [0, 0.5, 0.5],
		'/Distort/size': 0.5
	)
	++
	(
		'/Jellyfish/brightness': bam.clip(0.15, 1),
		'/Jellyfish/decay': 0.95,
		'/Jellyfish/noise/strength': 0,
		'/Jellyfish/pid': [1, 1, 1],
		'/Jellyfish/position': [0.5, 0.5, 0.5],
		'/Jellyfish/position/large': 0,
		'/Jellyfish/rotation': wobs,
		'/Jellyfish/shape': 0,
		'/Jellyfish/tension': 0.95,
		'/Jellyfish/tint': 0.5 + (bassAmp > 0.3).clip(0, 0.5),
		'/Jellyfish/width': (0.1 + bassAmp.lincurve(0, 0.5, 0, 1, -2) + amp.linlin(0, 0.5, 0, 1)).clip(0, 1)
	)
	++
	(
		'bass/wobble/dry/amp': 1,
		'bass/wobble/freq': LFNoise2.kr(0.1).range(0, 1),
		'bass/wobble/bpf': LFNoise2.kr(0.1).range(0, 1),
		'bass/wobble/comb/decay': LFNoise2.kr(0.1).range(0, 0.3),
		'bass/wobble/stick/freq': LFNoise2.kr(0.05).range(0.0, 0.3),
		'bass/wobble/pan/pos': bassAmp.linlin(0, 0.4, 0, 1).lag(0.125),
		'bass/wobble/pan/dis': 0.4

	)
});

