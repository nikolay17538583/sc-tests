{
	|outChans, waterDataSet|

	var numNeighbours = 1;
	var kdTree = FluidKDTree(s, numNeighbours);
	var inbuf = Buffer.alloc(s, 2);
	var t = kdTree.fit(waterDataSet.return(\grid));
	var t2 = Server.default.sync;


	var in = JHSynthDef.mkSynth(oscid:'slowWater/ctl', func: {
		var loc = OSCIn.kr('location', 2, [0.5, 0.5]);
		FluidKrToBuf.kr(loc, inbuf);
		SendReply.kr(Impulse.kr(10), '/slowWater/result', loc);
	});

	var out = JHSynthDef.mkSynth(oscid: 'slowWater/snd', func: {
		var audio = waterDataSet.return(\audioBuffer);
		var slices = waterDataSet.return(\sliceBuffer);
		var getFrame = BufRd.ar(1, slices, _, interpolation: 1);

		var numNewGrain = 8;
		var newGrainTimeMax = 30;
		var newGrainTime = 30;
		var newGrainFreq = newGrainTime.reciprocal;

		var newGrain = Impulse.ar(newGrainFreq!numNewGrain)
		|> DelayN.ar(_, newGrainTimeMax, numNewGrain.collect(_ / (numNewGrain)) * newGrainTime);

		var grainEnv = Env([0, 1, 0], newGrainTime / 2, 2, 2).kr(
			gate: Trig.ar(newGrain, newGrainTime * 0.99)
		);

		var index = Demand.ar(newGrain, 0, \index.ar(0)).round(1);

		var startFrame = getFrame.(index);
		var endFrame = getFrame.(index + 1);
		var duration = (endFrame - startFrame) * ( BufDur.ir(audio) / BufFrames.ir(audio) );
		var overlap = OSCIn.kr('overlap', 1, 0.5).linlin(0, 1, 5, 20);
		var imp = duration.reciprocal.clip(0.005, inf);

		var snd = GrainBuf.ar(1,
			trigger: Dust.ar(imp * overlap),
			dur: duration,
			sndbuf: audio,
			rate: [[2.5, 1, 0.5, 0.25]],
			pos: startFrame / BufFrames.ir(audio),
			mul: grainEnv
		).collect( _.sum );

		var line = LineSpreader.ar(outChans, snd.flat)
		|> Line2Point.ar(_,
			OSCIn.kr('pan/pos', 1, 0.5).linlin(0, 1, -1, 1),
			OSCIn.kr('pan/focus', 1, 0)
		)
		|> LineBlur.ar(_, OSCIn.kr('pan/blur', 1, 0));

		JHSynthMixin(\AnalysisAmp, Mix.ar(snd.flat));

		line * OSCIn.kr('dry/amp', 1, 0) |> SinkWr.ar('out', outChans, _);
		line * OSCIn.kr('wet/amp', 1, 0) |> SinkWr.ar('out/wet', outChans, _);
	});

	OSCdef('slowWaterRelay', {
		|msg|
		kdTree.kNearest(inbuf, numNeighbours, { |i|
			out.node.set(\index, i.asInteger);
		});
	}, '/slowWater/result', s.addr);

	out
}