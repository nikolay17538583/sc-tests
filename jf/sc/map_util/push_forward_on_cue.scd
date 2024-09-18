{
	|state|
	var stages = state * 3;
	var dir = IEnvGen.kr(Env([1.0, 0.0, -1.0, 1.0], [0.1, 1.9, 1]), stages.poll(label:\stages)).poll(label:\dir);

	var waitOrAnx = (stages - 1).abs.linlin(0, 0.2, 0, 1);
	var anx = (stages - 2).abs.linlin(0, 0.2, 0, 1);
	var waiting = waitOrAnx - anx;
	var waitWob = LFNoise2.kr(1.0 * waitOrAnx).range(0, 1);
	var anxWob = LFNoise2.kr(6.2 * waitOrAnx).range(0, 1);

	var anxWobH = {
		var slope = Slope.kr(anxWob);
		(slope * slope * slope) * 1.blend(-1, slope < 0);
	}.();

	(
		\main: dir,
		\movA: waitWob.blend(anxWob, anx),
		\movB: anxWobH
	)
}