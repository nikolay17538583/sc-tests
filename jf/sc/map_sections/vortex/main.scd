JHOSCMapStore.append((\min: 10, \max:20), (\time: 3, \curve: 2), {
	|src, isActive|

	var bassAmp = src['bass/wobble/analysis/amplitude'];
	var wobs = bassAmp * bassAmp * 12 |> (_!3) |> LFDNoise3.kr(_) |> (_.range(0,1));
Quaternion

	JHImport(~pwd +/+ "maps_util/waterGrain_nil.scd").()
	++
	(
		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.15,
	)
	++
	(
		'/Camera/fov': 0.35,
		'/Camera/force/default': 1,
		'/global/force': [0.0, 0.5, 0.5]
	)
	++
	(
		'/Distort/blur': 0.62,
		'/Distort/displacement': 0.58,
		'/Distort/force': [0.32, 0.5, 0.5],
		'/Distort/size': 0.36
	)
	++
	(
		'/Jellyfish/brightness': 0.3 + (bassAmp * 0.6), // mod
		'/Jellyfish/decay': 0.95,
		'/Jellyfish/noise/strength': 0,
		'/Jellyfish/pid': [1,1,1],
		'/Jellyfish/position': [0.5, 0.5, 0.5],
		'/Jellyfish/position/large': 0,
		'/Jellyfish/rotation': wobs,
		'/Jellyfish/shape': 0,
		'/Jellyfish/tension': 0.95,
		'/Jellyfish/tint': 0.5 + (bassAmp > 0.3).clip(0, 0.5), //mod
		'/Jellyfish/width': 0.2 + bassAmp.linlin(0, 0.5, 0, 1) //mod
	)
	++
	(
		'bass/wobble/dry/amp': 0.8,
		'bass/wobble/freq': LFNoise2.kr(0.4),
		'bass/wobble/bpf': LFNoise2.kr(0.4),
		'bass/wobble/comb/decay': LFNoise2.kr(0.4),
		'bass/wobble/stick/freq': LFNoise2.kr(0.4)
	)
});

