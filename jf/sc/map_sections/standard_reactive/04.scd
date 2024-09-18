var ampSpec = JHImAmplitude(128);

var derivSpecX = JHImDerivative(2.pow(11));
var derivSpecY = JHImDerivative(2.pow(11));

var headspec = JHImDerivative(2.pow(11));

s.sync;

JHOSCMapStore.append((\min: 60, \max: 60), (\time: 30, \curve: 0), {
	|src, isActive|

	var horizWobble = LFDNoise3.kr(src['output/mixer/analysis/amplitude'].linexp(0, 1, 0.01, 4));

	var togetherness = Env([0, 1], 60).kr(0, isActive);

	var imitator = { |imSpec, in| in
		|> JHImitator.kr(imSpec, in)
		|> DelayC.kr(_, 5, togetherness.linlin(0, 1, 5, 0))
		|> _.blend(in, 1 - togetherness)
	};

	var x_im = src['in/mic/analysis/centroid'] |> imitator.(derivSpecX, _);
	var y_im = src['in/mic/analysis/skewness'] |> imitator.(derivSpecY, _);
	var myAmp = src['in/mic/analysis/amplitude'] * 2 |> (_.clip(0, 1)) |> imitator.(ampSpec, _);

	var amp = myAmp.blend(src['waterGrain/output/analysis/amplitude'], _)
	<| Demand.kr(src['syncron/trigger'], 0, _)
	<| Dseq([0, 1], inf).lag(0.1);


	var holdline = EnvGen.kr(Env.linen(0.0, 0, 12), src['syncron/trigger']);


	var lerper = JHBiLinear([0.2, 0.3], [0.34, 0.3], [0.34, 0.90], [0.9, 0.7]);
	var location = lerper.(x_im, y_im);

	var waterAmp = src['waterGrain/output/analysis/amplitude'].lag2ud(0.1, 0.5);

	var headlr = JHImitator.kr(headspec, src['/webcam/pos/forehead'][0]);


	var activeState = (
		'/Jellyfish/position': [0.2, 0.15, headlr].blend([0.8, 0.8, 0.5], holdline.sqrt),
		'/Jellyfish/width': DC.kr(0),
		'/Jellyfish/rotation': [0.5, 0.5.blend(4, holdline).wrap(0, 1), 0.5],
	);


	var waitState = (
		'/Jellyfish/position': [0.8, 0.15, headlr] + ([x_im, y_im, x_im] *  [0.02, 0.12, 0.012]),
		'/Jellyfish/width' : src['syncron/state'].clip(1/3, 2/3).linexp(1/3, 2/3, 0.13, 0.7) + (waterAmp * 0.14),
		'/Jellyfish/rotation': [0.75, 0.5, 0.5],
	);

	var anxRotWob = [y_im, x_im, y_im];
	var anxState = (
		'/Jellyfish/position': [0.8, 0.1, headlr] + [0, x_im, 0],
		'/Jellyfish/width' : src['syncron/state'].clip(3/3, 1).linexp(2/3, 1, 0.3, 0.8)
		+ LFNoise2.kr(2.8).range(0, 0.2),
		'/Jellyfish/rotation': [0.75, 0.5, 0.5] + anxRotWob,
	);

	var nodder = JHNodder(src['/webcam/nod/state'][0], src['syncron/state'],
		activeState, waitState, anxState
	);


	var fadeIn = EnvGen.kr(Env([0, 1], 25, 1), isActive);


	var broadNod = src['/webcam/movement'].linlin(0,1, -1, 1).pow(2).abs.sum * src['in/mic/onset'] ;

	(
		'/Jellyfish/position': nodder.get('/Jellyfish/position') + [0, 0, horizWobble * 0.2],
		'/Jellyfish/width': nodder.get('/Jellyfish/width'),
		'/Jellyfish/rotation': nodder.get('/Jellyfish/rotation')
	)
	++
	(
		'live/echoes/wet/amp': 0.dbamp,
		'live/echoes/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'live/echoes/pan/pos': 0.8 - (horizWobble * 0.3),
		'live/echoes/pan/focus': 0.85,
		'live/echoes/gain/boost': 0.3
	)
	++
	(
		'syncron/holdTime': 0.2,
		'syncron/waitTime': 1,
		'syncron/anxTime': 1,

		'syncron/visualCue': src['/webcam/nod/state'][1] + (nodder.inAnix() * broadNod),

		'/Jellyfish/tint': 1,
		'/Jellyfish/brightness': 0.5 + amp.clip(0, 0.2).linlin(0, 0.2, 0, 0.5),

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.35,

		'waterGrain/output/dry/amp': 1,
		'waterGrain/output/gain/boost': 0.5,

		'waterGrain/input/location': location,
		'waterGrain/output/update/rate': 0.5,
		'waterGrain/output/overlap': 0.5,
		'waterGrain/output/radius': 0,
		'waterGrain/output/wet/amp': -5.dbamp,
		'waterGrain/output/lpf' : 1,

		'waterGrain/output/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'waterGrain/output/pan/pos': 0.3 + (horizWobble * 0.3),
		'waterGrain/output/pan/focus': 0.85,

		'/global/force': [0.5, waterAmp.linlin(0, 1, 0.5, 0), 0.5],

		'/Camera/lookAt/lerp': 0.1,
		'/Camera/fov': 0.25

	)

});
