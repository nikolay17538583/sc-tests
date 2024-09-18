var rumble_points = [
	[ 0.8259587020649, 0.52045606975184 ],
	[ 0.94247787610619, 0.45338698859826 ],
	[ 0.88790560471976, 0.60898725687458 ],
	[ 1, 0.53856472166331 ]
];
var highs = [
	[ 0.6216814159292, 0.74245472837022 ],
	[ 0.60176991150442, 0.68879946344735 ],
	[ 0.3834808259587, 0.90878604963112 ]
];

JHOSCMapStore.append((\min: 100, \max: 100), (\time: 20, \curve: 0), {
	|src, isActive|

	var lerper = JHBiLinear.new(*rumble_points);
	var location = lerper.(*LFNoise2.kr(0.1!2).range(0, 1));

	var head_velocity = Slope.kr(src['/webcam/pos/forehead']);

	var head_kwh = Integrator.kr(head_velocity.pow(2).abs.sum * 0.1).fold(0, 1);

	var pre_spark = head_kwh.linlin(0,1, 0.01, 1) |> Dust.kr(_) + src['/webcam/nod/state'][1] |> _.clip(0, 1);
	var spark = DelayN.kr(pre_spark, 0.25, 0.25);
	var sparkMode = Trig1.kr(
		in: spark,
		dur: LFNoise0.kr(0.1).exprange(0.02, 1.26)
	);

	var sparkLocation = Demand.kr(spark, 0, Drand(highs, inf) + Dwhite(-0.1, 0.1));
	var sparkRate = Demand.kr(spark, 0, Dwhite(0.5, 1));
	var sparkBrightness = Demand.kr(spark, 0, Dwhite(0.8, 1));
	var sparkRotJump = Demand.kr(spark, 0, Dwhite((-1)!3, 1!3));
	var sparkRot = [0, 0, 0].blend(sparkMode, spark) |> Integrator.kr(_) ;


	var slowSpin = src['/Reflection/luminance'] * 0.01 |> Integrator.kr(_);
	var rot = LFNoise2.kr(0.1!3) + sparkRot |> Fold.kr(_, 0, 1);

	(
		'waterGrain/input/location': location.blend(sparkLocation, sparkMode),
		'waterGrain/output/update/rate': 1,
		'waterGrain/output/overlap': 1,
		'waterGrain/output/radius': 1.blend(0, sparkMode),
		'waterGrain/output/rate': 0.25.blend(sparkRate, sparkMode),
		'waterGrain/output/dry/amp': -15.dbamp.blend(1.0, sparkMode),
		'waterGrain/output/wet/amp': -15.dbamp.blend(1.0, sparkMode),
		'waterGrain/output/gain/boost': 0.5.blend(1.0, sparkMode),
		'waterGrain/output/lpf' : 0.4.blend(1, sparkMode)
	)
	++
	(
		'/Jellyfish/thickness': 1.0.blend(0.0, sparkMode+ (pre_spark * 0.2)),
		'/Jellyfish/brightness': 0.05.blend(sparkBrightness*8, sparkMode + (pre_spark * 0.2)),
		'/Jellyfish/texture/velocity': head_velocity.abs.lag2(1).linlin(0, 1, 0.5, 1),
		'/Jellyfish/rotation': rot,
		'/Jellyfish/position': [0.13, 0.5, 0.5],
		'/Jellyfish/width': src['waterGrain/output/analysis/amplitude'].lag2ud(0.2, 0.8),

		'/global/force': [1, 0.5, 0.5],
		'/Camera/lookAt/lerp': 0.1,
		'/Camera/fov': 0.24
	)
	++
	(
		'/Distort/displacement': 0.blend(0.4, sparkMode),
		'/Distort/blur': 0,
		'/Distort/force': [1, 0.5, 0.5],
		'/Distort/size': 0.blend(0.6, sparkMode)
	)
	++
	(
		'/Jellyfish/noise/strength': 0.0,
		'/Sun/brightness': 0.blend(1, sparkMode),
		'/Camera/force/default': 0,

		'guitar/playback/dry/amp': 1,
		'guitar/playback/wet/amp': 0.135,
	)

});



