JHSynthDef(\GranularDecay, outputSpec: (\out: 4), function: {
	var mono = FoaDecode.ar(\in.ar(0!4), FoaDecoderMatrix.newMono);
	var buf = LocalBuf(Server.default.sampleRate * 2);
	var rec = {
		var revdecay = \reverbDecay.kr(0.2).clip(0,1);
		RecordBuf.ar(mono, buf, recLevel: revdecay, preLevel: 1 - revdecay);
	}.();
	var grains = {
		var freq = \freq.kr(0).linexp(0, 1, 0.01, 20);
		var dur = \dur.kr(0).linlin(0, 1, 0.01, 2);
		var rate = \rate.kr(0).linexp(0, 1, 1/4, 4);
		var pos = \position.kr(0).clip(0,1);
		var spread = \positionSpread.kr(0);
		GrainBuf.ar(
			numChannels:1,
			trigger: Dust.ar(freq!4),
			dur: dur,
			sndbuf: buf,
			rate: rate,
			pos: WhiteNoise.ar().range(pos - spread, pos + spread).clip(0,1)
		);
	}.();
	var ambi = {
		var grainSpeed = \grainSpeed.kr(0).linexp(0 ,1, 0.001, 4);
		var multi_ambi = grains.collect{ |g|
			FoaPanB.ar(g, LFDNoise3.kr(grainSpeed).range(-2*pi, 2*pi))
		};
		Mix.ar(multi_ambi);
	}.();

	var panned = JHAmbiPanWithOSCSinks.mixIn(ambi);
	Out.ar(\out.kr(~null), panned);
});


