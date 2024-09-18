var ampSpec = JHImAmplitude(128);

var derivSpecX = JHImDerivative(2.pow(11));
var derivSpecY = JHImDerivative(2.pow(11));

var headspec = JHImDerivative(2.pow(11));

s.sync;

JHOSCMapStore.append((\min: 180, \max: 180), (\time: 30, \curve: 1), {
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
	<| Demand.kr(Dust.kr(0.1), 0, _)
	<| Dseq([0, 1], inf).lag(0.1);


	var lerper = JHBiLinear([0.2, 0.3], [0.34, 0.3], [0.34, 0.90], [0.9, 0.7]);
	var loc_plus_head = [x_im, y_im] + (src['/webcam/pos/forehead'] * LFNoise2.kr(0.1).clip(0, 1));
	var location = lerper.(*loc_plus_head);

	var waterAmp = src['waterGrain/output/analysis/amplitude'].lag2ud(0.1, 1.5);

	var loc_delta = Slope.kr(location);
	var loc_spd = loc_delta.pow(2).sum.clip(0,1).lag2ud(0.01, 0.1);
	var rot = LFDNoise3.kr(loc_spd.pow(2)!3);
	var rot_speed = Slope.kr(rot).pow(2).abs.sum;

	(
		'/Jellyfish/position': [0.15] ++ [x_im, y_im].linlin(0,1, 0.2, 0.8),
		'/Jellyfish/width': waterAmp.lag2ud(0.3, 1.2),
		'/Jellyfish/rotation': rot,
		'waterGrain/output/dry/amp': (loc_spd + rot_speed).clip(0, 1),
		'waterGrain/output/wet/amp': -15.dbamp * loc_spd,
		'/Jellyfish/thickness': src['output/mixer/analysis/amplitude']
		.clip(0,1).lag2ud(0.3, 1.2),
	)
	++
	(
		'live/echoes/wet/amp': src['/Reflection/luminance'],
		'live/echoes/dry/amp': src['/Reflection/luminance'],

		'live/echoes/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'live/echoes/pan/pos': 0.8 - (horizWobble * 0.3),
		'live/echoes/pan/focus': 0.85,
		'live/echoes/gain/boost': 0.2
	)
	++
	(
		'syncron/holdTime': 0.2,
		'syncron/waitTime': 1,
		'syncron/anxTime': 1,

		'syncron/visualCue': src['/webcam/nod/state'][1],

		'/Jellyfish/brightness': src['waterGrain/output/analysis/amplitude']
		.lag2ud(0.3, 0.8).pow(3),

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.35,

		'waterGrain/output/gain/boost': 0.5,

		'waterGrain/input/location': location,
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/overlap': 1,
		'waterGrain/output/radius': 0,
		'waterGrain/output/lpf' : src['/Reflection/luminance'],

		'waterGrain/output/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'waterGrain/output/pan/pos': 0.3 + (horizWobble * 0.3),
		'waterGrain/output/pan/focus': 0.85,

		'/global/force': [0.5, waterAmp.linlin(0, 1, 0.5, 0), 0.5],

		'/Camera/lookAt/lerp': 0.1,
		'/Camera/fov': 0.25

	)

});
