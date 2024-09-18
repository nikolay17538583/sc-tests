var ampSpec = JHImAmplitude(128);

s.sync;

JHOSCMapStore.append((\min: 120, \max: 120), (\time: 30, \curve: 0), {
	|src, isActive|

	var myAmpRaw = src['in/mic/analysis/amplitude'] * 2;
	var myAmpIm = JHImitator.kr(ampSpec, myAmpRaw);
	var myAmp = myAmpRaw.blend(myAmpIm, LFNoise2.kr(0.05).range(-1, 2).clip(0,1));

	var amp = myAmp + src['waterGrain/output/analysis/amplitude']
	|> Median.kr(6, _) |> (_.lag2(0.3));

	var holdline = EnvGen.kr(Env.linen(0.0, 0, 12), src['syncron/trigger']);

	var snd_loc = JHBiLinear([0.2, 0.3], [0.34, 0.3], [0.34, 0.60], [0.34, 0.65]);

	var rand_loc = LFDNoise3.kr( src['/Reflection/luminance'].linexp(0,1, 0.2, 6) ).range(-0.05, 0.05);

	var activeState = (
		'/Jellyfish/position': [0.2, 0.15, 0.5].blend([0.5, 0.8, 0.5], holdline.sqrt),
		'/Jellyfish/width': DC.kr(0),
		'/Jellyfish/rotation': [0.5, 0.5.blend(4, holdline).wrap(0, 1), 0.5],
		'/loc' : rand_loc + [0.6, 0.6].blend([0, 0], holdline) |> snd_loc.(*_),
		'/wet': -5.dbamp,
		'/lpf': 0.4
	);

	var waitPosN = LFDNoise3.kr(src['/Reflection/luminance'].linexp(0,1, 0.2, 6)!3);
	var waitWdN = LFDNoise3.kr(3.8);

	var waitState = (
		'/Jellyfish/position': [0.5, 0.15, 0.5] + (waitPosN *  [0.02, 0.12, 0.012]),
		'/Jellyfish/width' : src['syncron/state']
		.clip(1/3, 2/3)
		.linexp(1/3, 2/3, 0.13, 0.7) + (waitWdN.abs * 0.14),
		'/Jellyfish/rotation': [0.75, 0.5, 0.5],
		'/loc' : waitPosN[0..1].range(0.2, 0.6) |> snd_loc.(*_),
		'/wet': -5.dbamp,
		'/lpf': 0.6
	);

	var anxRotWob = LFNoise2.kr(9!3);
	var anxState = (
		'/Jellyfish/position': [0.5, 0.1, 0.5] + [0, LFNoise2.kr(3, 0.1), 0],
		'/Jellyfish/width' : src['syncron/state'].clip(3/3, 1).linexp(2/3, 1, 0.3, 0.8) + LFNoise2.kr(2.8).range(0, 0.2),
		'/Jellyfish/rotation': [0.75, 0.5, 0.5] + (anxRotWob * 0.25),
		'/loc' : rand_loc + anxRotWob[0..1].range(0.4, 1) |> snd_loc.(*_),
		'/wet': -5.dbamp,
		'/lpf': 0.7
	);

	var nodder = JHNodder(src['/webcam/nod/state'][0], src['syncron/state'],
		activeState, waitState, anxState
	);

	var waterAmp = src['waterGrain/output/analysis/amplitude'];

	var fadeIn = EnvGen.kr(Env([0, 1], 25, 1), isActive);


	(
		'/Jellyfish/position': nodder.get('/Jellyfish/position'),
		'/Jellyfish/width': nodder.get('/Jellyfish/width'),
		'/Jellyfish/rotation': nodder.get('/Jellyfish/rotation')
	)
	++
	(
		'live/echoes/wet/amp': fadeIn.linlin(0,1, -120, -10).dbamp,
		'live/echoes/pan/blur': fadeIn.linlin(0, 1, 1, 0.5)
	)
	++
	(
		'syncron/holdTime': 0.7,
		'syncron/waitTime': 0.2,
		'syncron/anxTime': 0.4,

		'syncron/visualCue': src['/webcam/nod/state'][1],

		'/Jellyfish/brightness': 0.25 + amp.clip(0, 0.2).linlin(0, 0.2, 0, 0.75),

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.35,

		'waterGrain/output/dry/amp': 1,
		'waterGrain/output/gain/boost': 0.5,

		'waterGrain/input/location': nodder.get('/loc'),
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/overlap': 0.8,
		'waterGrain/output/radius': 1,
		'waterGrain/output/wet/amp': nodder.get('/wet'),
		'waterGrain/output/lpf' : 1, // nodder.get('/lpf').lag(0.5),

		'waterGrain/output/pan/blur': (src['/Reflection/luminance'] * 2).clip(0, 1),
		'waterGrain/output/pan/pos': 0.15,
		'waterGrain/output/pan/focus': 0.25,

		'/global/force': [0.5, waterAmp.linlin(0, 1, 0.5, 1), 0.5],

		'/Camera/lookAt/lerp': 0.2,
		'/Camera/fov': 0.25

	)

});
