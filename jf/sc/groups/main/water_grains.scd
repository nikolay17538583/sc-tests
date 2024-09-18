{
	|outChans, waterDataSet, numNeighbours|

	var kdTree = FluidKDTree(s, numNeighbours);
	var waterInputBuf = Buffer.alloc(s, 2);
	var t = kdTree.fit(waterDataSet.return(\grid));
	var t2 = Server.default.sync;


	var in = JHSynthDef.mkSynth(oscid: 'waterGrain/input', func: {
		var loc = OSCIn.kr('location', 2, [0, 0]);
		FluidKrToBuf.kr(loc, waterInputBuf);
		SendReply.kr(Impulse.kr(150), '/waterGrain/relay/result', loc);
	});

	var out = JHSynthDef.mkSynth(oscid: 'waterGrain/output', func: {
		var num = 4;
		var new_grain_t = OSCIn.kr('update/rate', 1, 0)
		|> (_.linexp(0, 1, 1, 100))
		|> (_ ! (numNeighbours * num))
		|> Dust.ar(_) > 0.00001;

		var new_index = ({(0..(numNeighbours - 1))}!num).flat * OSCIn.kr('radius', 1, 1).clip(0,1)
		|> Select.ar(_, \index.ar(0!numNeighbours))
		|> Latch.ar(_, new_grain_t);

		var startFrame = BufRd.ar(1, waterDataSet.return(\sliceBuffer), new_index, interpolation: 1);
		var endFrame = BufRd.ar(1, waterDataSet.return(\sliceBuffer), new_index + 1, interpolation: 1);

		var duration = (endFrame - startFrame) * (
			BufDur.ir(waterDataSet.return(\audioBuffer)) / BufFrames.ir(waterDataSet.return(\audioBuffer)));
		var overlap = OSCIn.kr('overlap', 1, 0.5).bilin(0.5, 0, 1, 1, 0.1, 10);

		var imp = {
			var phase = num.collect{|n| n / num};
			var reg = Impulse.ar(duration.reciprocal * overlap, );
			var ir = Dust.ar(duration.reciprocal * overlap, phase);
			var f = OSCIn.kr('regularity', 1, 1).clip(0, 1);
			var se = Demand.ar(reg + ir, 0, Dwrand([0, 1], [f, 1 - f], inf));
			(reg * se) + (ir * (1 - se));
		}.();


		var boost = OSCIn.kr('gain/boost', 1, 0).linexp(0, 1, 1, 10);
		var signal = GrainBuf.ar(1,
			trigger: imp,
			dur: duration * OSCIn.kr('dur/scale', 1, 0.5).bilin(0.5, 0, 1, 1, 0, 4),
			sndbuf: waterDataSet.return(\audioBuffer),
			rate: OSCIn.kr('rate', 1, 0.5).bilin(0.5, 0, 1, 1, 0.25, 4),
			pos: startFrame / BufFrames.ir(waterDataSet.return(\audioBuffer)),
		)
		|> LeakDC.ar(_)
		|> LPF.ar(_, OSCIn.kr('lpf', 1, 1).linexp(0, 1, 2000, 18000))
		|> {|s| (s * boost).tanh }
		* Setting.kr('FixedGain', 0, \db, 1).dbamp.sanitize;

		var line = LineSpreader.ar(outChans, signal)
		|> Line2Point.ar(_, OSCIn.kr('pan/pos', 1, 0.5).linlin(0, 1, -1, 1), OSCIn.kr('pan/focus', 1, 0))
		|> LineBlur.ar(_, OSCIn.kr('pan/blur', 1, 0))
		|> (_.tanh);

		JHSynthMixin(\AnalysisAmp, Mix.ar(line.flat));

		line * OSCIn.kr('dry/amp', 1, 0) |> SinkWr.ar('out', outChans, _);
		line * OSCIn.kr('wet/amp', 1, 0) |> SinkWr.ar('out/wet', outChans, _);
	});


	OSCdef('waterGrainRelayOSCDef', {
		|msg|
		kdTree.kNearest(waterInputBuf, numNeighbours, { |i|
			out.node.set(\index, i.collect{|n| n.asInteger })
		});
	}, '/waterGrain/relay/result', s.addr);


	out
}