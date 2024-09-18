{
	|outChans|
	var buffer = Buffer.alloc(s, s.sampleRate * 60, 1);
	var distort = Buffer.alloc(s, 1024, 1, { |buf| buf.chebyMsg([1,0,0.81,0.41,0,0.2])});
	s.sync;

	JHSynthDef.mkSynth(oscid: 'live/echoes', func: {
		var mainPhase = Phasor.ar(0, BufRateScale.kr(buffer), 0, BufFrames.kr(buffer));
		var mainPtr = mainPhase / BufFrames.kr(buffer);

		var num = 6; // number of echos
		var write = SrcRd.ar('in/mono', 1) |> BufWr.ar(_, buffer, mainPhase);

		var delay = (\max: 1, \min: 0.01);
		var readPtr = LFNoise2.kr(0.15!num).range(delay[\min], delay[\max]) |> (mainPtr - _) |> (_.wrap(0, 1));

		var pans = LFNoise2.kr(0.3!num);
		var bpfs = LFNoise2.kr(0.1!num).linexp(-1, 1, 250, 2500);

		var echoes = Warp1.ar(1, buffer, readPtr) // read from buffer at readPtr
		|> BPF.ar(_, bpfs, 0.1, 2) * OSCIn.kr('gain/boost', 1, 0).linexp(0, 1, 1, 8)
		|> Shaper.ar(distort, _);

		var e = Mix.ar(
			[echoes, pans].flop.collect{|e|
				LinePanner.ar(outChans, e[0], e[1])
			}
		)

		|> Line2Point.ar(_, OSCIn.kr('pan/pos', 1, 0.5).linlin(0, 1, -1, 1), OSCIn.kr('pan/focus', 1, 0))
		|> LineBlur.ar(_, OSCIn.kr('pan/blur', 1, 0));

		e * OSCIn.kr('dry/amp', 1, 0)
		|> SinkWr.ar('out', outChans, _);

		e * OSCIn.kr('wet/amp', 1, 0)
		|> SinkWr.ar('out/wet', outChans, _);
	})
}