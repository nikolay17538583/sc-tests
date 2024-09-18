JHOSCMapStore.append((\min: 160, \max: 160), (\time: 3, \curve: 0), {
	|src, isActive|

	var amp = src['in/mic/analysis/amplitude'] * 2;

	var holdline = EnvGen.kr(Env.linen(0.0, 0, 15), src['syncron/trigger']);

	var snd_loc = JHBiLinear([0.07, 0.25], [0.3, 0.3], [0.27, 0.50], [0.34, 0.45]);
	var rand_loc = LFNoise2.kr(2).range(-0.05, 0.05);
	var activeState = (
		'/Jellyfish/position': [0.2, 0.15, 0.5].blend([0.5, 0.8, 0.5], holdline),
		'/Jellyfish/width': DC.kr(0.05),
		'/Jellyfish/rotation': [0.5, 0.5.blend(4, holdline).wrap(0, 1), 0.5],
		'/loc' : rand_loc + [0.6, 0.6].blend([0, 0], holdline) |> snd_loc.(*_),
		'/amp' : -2.dbamp,
		'/wet': holdline.linlin(0, 1, -25.dbamp, -10.dbamp),
		'/lpf': 1
	);

	var waitPosN = LFDNoise3.kr(2!3);
	var waitWdN = LFDNoise3.kr(1.8);
	var waitState = (
		'/Jellyfish/position': [0.5, 0.15, 0.5] + (waitPosN *  [0.02, 0.12, 0.012]),
		'/Jellyfish/width' : src['syncron/state'].clip(1/3, 2/3).linexp(1/3, 2/3, 0.13, 0.7) + (waitWdN.abs * 0.14),
		'/Jellyfish/rotation': [0.5, 0.5, 0.5],
		'/loc' : waitPosN[0..1].range(0.2, 0.6) |> snd_loc.(*_),
		'/amp' : src['syncron/state'].clip(1/3, 2/3).linexp(1/3, 2/3, -5, -1).dbamp,
		'/wet': -15.dbamp,
		'/lpf': 0.3
	);

	var anxRotWob = LFNoise2.kr(5!3);
	var anxState = (
		'/Jellyfish/position': [0.5, 0.15, 0.5] + [0, LFNoise2.kr(3, 0.1), LFNoise2.kr(2, 0.1)],
		'/Jellyfish/width' : src['syncron/state'].clip(3/3, 1).linexp(2/3, 1, 0.3, 0.8) + LFNoise2.kr(2.8).range(0, 0.2),
		'/Jellyfish/rotation': [0.5, 0.5, 0.5] + (anxRotWob * 0.25),
		'/loc' : rand_loc + anxRotWob[0..1].range(0.4, 1) |> snd_loc.(*_),
		'/amp' : 1,
		'/wet': -25.dbamp,
		'/lpf': 1
	);

	var nodder = JHNodder(src['/webcam/nod/state'][0], src['syncron/state'],
		activeState, waitState, anxState
	);

	var waterAmp = src['waterGrain/output/analysis/amplitude'];

	var pos = nodder.get('/Jellyfish/position');

	(
		'/Jellyfish/position': pos,
		'/Jellyfish/width': nodder.get('/Jellyfish/width'),
		'/Jellyfish/rotation': nodder.get('/Jellyfish/rotation')
	)
	++
	(
		'syncron/holdTime': 1,
		'syncron/waitTime': 0.4,
		'syncron/anxTime': 0.4,

		'syncron/visualCue': src['/webcam/nod/state'][1],

		'/Jellyfish/brightness': 0.3,

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.35,

		'waterGrain/output/dry/amp': 1, // nodder.get('/amp'),
		'waterGrain/output/gain/boost': 0.5,
		'waterGrain/input/location': nodder.get('/loc'),
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/overlap': 0.8,
		'waterGrain/output/radius': 1,
		'waterGrain/output/wet/amp': nodder.get('/wet'),
		'waterGrain/output/lpf' : 1, //nodder.get('/lpf').lag(0.5),
		'waterGrain/output/pan/blur': src['/Reflection/luminance'].clip(0, 1),
		'waterGrain/output/pan/pos': 0.15,
		'waterGrain/output/pan/focus': 0.5,

		'/global/force': [0.5, waterAmp.linlin(0, 1, 0.5, 1), 0.5],

		'/Camera/lookAt/lerp': 0.1,
		'/Camera/fov': 0.25
	)

});
