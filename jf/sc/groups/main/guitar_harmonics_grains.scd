var numNeighbours = 4;
var kdTree = FluidKDTree(s, numNeighbours);
var inputBuffer = Buffer.alloc(s, 2);

var t = kdTree.fit(~guitarHarmonicsDataSet.return(\grid));

var d = Server.default.sync;

var in = JHSynthDef.mkSynth(oscid: 'guitarHarmGrain/input', func: {
	var loc = OSCIn.kr('location', 2, [0, 0]);
	FluidKrToBuf.kr(loc, inputBuffer);
	SendReply.kr(Impulse.kr(250), '/guitarHarmGrain/relay/result', loc);
});

var out = JHSynthDef.mkSynth(oscid: 'guitarHarmGrain/output', func: {
	var num = 5;
	var upd_rate = OSCIn.kr('update/rate', 1, 0).linexp(0, 1, 1, 100);
	var new_grain_t = Dust.ar( upd_rate!(numNeighbours*num)).abs > 0.00001;

	var new_index = {
		var choice = ({(0..(numNeighbours - 1))}!num).flat;
		var selector = choice * OSCIn.kr('radius', 1, 1).clip(0,1);
		var raw = Select.ar(selector, \index.ar(0!numNeighbours));
		Latch.ar(raw, new_grain_t);
	}.();

	var startFrame = BufRd.ar(1, ~guitarHarmonicsDataSet.return(\sliceBuffer), new_index, interpolation: 1);
	var endFrame = BufRd.ar(1, ~guitarHarmonicsDataSet.return(\sliceBuffer), new_index + 1, interpolation: 1);

	var number_of_frames = endFrame - startFrame;
	var duration = number_of_frames * (
		BufDur.ir(~guitarHarmonicsDataSet.return(\audioBuffer))
		/
		BufFrames.ir(~guitarHarmonicsDataSet.return(\audioBuffer))
	);
	var overlap = OSCIn.kr('overlap', 1, 0.5).bilin(0.5, 0, 1, 1, 0.1, 10);

	var imp = {
		var reg = Impulse.ar(duration.reciprocal * overlap, num.collect{|n| n / num});
		var ir = Dust.ar(duration.reciprocal * overlap, num.collect{|n| n / num});
		var f = OSCIn.kr('regularity', 1, 1).clip(0,1);
		var se = Demand.ar(reg + ir, 0, Dwrand([0, 1], [f, 1 - f], inf));
		(reg * se) + (ir * (1 - se));
	}.();

	var signal = GrainBuf.ar(1,
		imp,
		duration * OSCIn.kr('dur/scale', 1, 0.5).bilin(0.5, 0, 1, 1, 0, 4),
		~guitarHarmonicsDataSet.return(\audioBuffer),
		OSCIn.kr('rate', 1, 0.5).bilin(0.5, 0, 1, 1, 0.25, 4),
		startFrame / BufFrames.ir(~guitarHarmonicsDataSet.return(\audioBuffer)),
	);


	var line = LineSpreader.ar(~outChans, signal)
	|> LineBlur.ar(_, OSCIn.kr('pan/blur', 1, 0))
	|> Line2Point.ar(_, OSCIn.kr('pan/pos', 1, 0.5).linlin(0, 1, -1, 1), OSCIn.kr('pan/pos/focus', 1, 0));

	JHSynthMixin(\AnalysisAmp, Mix.ar(line.flat));

	SinkWr.ar('out', ~outChans, line * OSCIn.kr('dry/amp', 1, 0));
	SinkWr.ar('out/wet', ~outChans, line * OSCIn.kr('wet/amp', 1, 0));
});


OSCdef('guitarHarmonicsGrainRelayOSCDef', {
	|msg|
	kdTree.kNearest(inputBuffer, numNeighbours, { |i|
		out.node.set(\index, i.collect{|n| n.asInteger })
	});
}, '/guitarHarmGrain/relay/result', s.addr);


out;
