var ampSpec = JHImAmplitude(128);
var derivSpecX = JHImDerivative(2.pow(15));
var derivSpecY = JHImDerivative(2.pow(15));

s.sync;

JHOSCMapStore.append((\min: 140, \max: 140), (\time: 30, \curve: 2), {
	|src, isActive|

	var horizWobble = src['/webcam/pos/forehead'][0];
	var grow = Env([0,0,1], [100, 40]).kr(0, isActive);
	var togetherness = Env([0, 1], [30]).kr(0, isActive);
	var away = Env([0, 0, 1], [60, 20], \sin).kr(0, isActive);

	var imitator = { |imSpec, in| in
		|> JHImitator.kr(imSpec, in)
		|> DelayN.kr(_, 5, 5)
		|> _.blend(in, 1 - togetherness)
	};

	var x_im = src['in/mic/analysis/centroid'] |> imitator.(derivSpecX, _);
	var y_im = src['in/mic/analysis/skewness'] |> imitator.(derivSpecY, _) + horizWobble.linlin(0, 1, -0.15, 0.15);
	var myAmp = src['in/mic/analysis/amplitude'] * 2 |> (_.clip(0, 1)) |> imitator.(ampSpec, _);

	var amp = myAmp;

	var coordsStart = [
		[0.2, 0.3], [0.34, 0.3], [0.34, 0.60], [0.5, 0.7]
	];
	var coordsEnds = [
		[0.3, 0.6], [0.6, 0.4], [0.27, 0.9], [0.8, 0.72]
	];
	var lerper = JHBiLinear( *coordsStart.blend(coordsEnds, away));
	var location = lerper.(x_im, y_im);

	var waterAmp = src['waterGrain/output/analysis/amplitude'].lag2ud(0.1, 0.5);

	var outAmpVel = src['output/mixer/analysis/amplitude'].lag2ud(0.1, 0.5).linexp(0, 1, 0.001, 0.2);
	var verticalPos = LFDNoise3.kr(outAmpVel);

	var pos = [
		x_im.linlin(0, 1, 0.2, 0.5).blend(x_im, away),
		verticalPos.linlin(0, 1, 0.45, 0.55).blend(verticalPos.linlin(0, 1, 0.2, 0.4), away),
		y_im.linlin(0, 1, 0.2, 0.8).blend(y_im, away)
	];

	var vel = Slope.kr([x_im,y_im]);

	var outAmp = src['output/mixer/analysis/amplitude'].lag(1.75).linlin(0, away.linlin(0, 1, 0.4, 1), 0, 1);

	var force = [0.5, 0, 0.5].blend(LFNoise2.kr(0.2!3).range(0, 1) * [1, 0, 1], away.pow(3));
	(
		'live/echoes/wet/amp': 0.dbamp,
		'live/echoes/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'live/echoes/pan/pos': 0.8 - (horizWobble.linlin(0,1,-1,1) * 0.3),
		'live/echoes/pan/focus': 0.85.blend(0.9, away),
		'live/echoes/gain/boost': 0.3
	)
	++
	(
		'syncron/holdTime': 0.7,
		'syncron/waitTime': 0.2,
		'syncron/anxTime': 0.4,

		'syncron/visualCue': src['/webcam/nod/state'][1],

		'/Jellyfish/tint': 1,
		'/Jellyfish/brightness': (0.25 + outAmp.linlin(0, 1, 0, 0.75)).blend(outAmp.linlin(0, 0.4, 0, 1), away),

		'/Jellyfish/position': pos,
		'/Jellyfish/width': outAmp,
		'/Jellyfish/rotation': LFDNoise3.kr(outAmpVel!3),
		'/Jellyfish/shape': (0.blend(outAmp.lag(1), away.pow(2)) + grow).clip(0, 0.4),

		'/Distort/size': waterAmp.linlin(0.4, 1, 0, 0.5),
		'/Distort/blur': waterAmp.linlin(0.4, 1, 0, 0.5),
		'/Distort/displacement': waterAmp.linlin(0.4, 1, 0, 0.5),
		'/Distort/force': force,

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.35,

		'waterGrain/output/dry/amp': 1.blend(-12.dbamp, away.pow(2)),
		'waterGrain/output/gain/boost': 1,

		'waterGrain/input/location': location,
		'waterGrain/output/update/rate': 0.5,
		'waterGrain/output/overlap': src['/Reflection/luminance'].linlin(0, 0.5, 0.25, 1),
		'waterGrain/output/radius': togetherness,
		'waterGrain/output/wet/amp': -5.dbamp.blend(0.dbamp, away.pow(2)),
		'waterGrain/output/lpf' : 1,

		'waterGrain/output/pan/blur': (src['/Reflection/luminance'] * 4).clip(0, 1),
		'waterGrain/output/pan/pos': 0.3 + horizWobble.linlin(0,1,-0.3,0.3),
		'waterGrain/output/pan/focus': 0.85.blend(0.9, away),

		'/global/force': force,

		'/Camera/lookAt/lerp': 0.5.blend(0.1, away.pow(2)) ,
		'/Camera/fov': 0.25.blend(0.45, away.pow(2))
	)
});

