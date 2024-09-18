{
	|outChans, ambiFile|
	var york_minster = Conv(ambiFile, 8192);
	s.sync;

	JHSynthDef.mkSynth('effect/reverb', func: {
		var in = SinkRd.ar('in', outChans) * DelayN.ar(Line.ar(0, 1, 2), 0.5, 0.5); // fade in

		var stereo = LineSample.ar(in, [-1, 1], 0.25)
		|> york_minster.ar(_) * Setting.kr('Reverb Gain', 1, \db).dbamp.sanitize
		|> LPF.ar(_, Setting.kr('LPF', 18000, \freq))
		|> HPF.ar(_, Setting.kr('HPF', 35, \freq))
		|> BLowShelf.ar( _,
			Setting.kr('Low Self Freq', 500, \freq),
			Setting.kr('Low Self RQ', 1, \rq),
			Setting.kr('Low Self Db', 0, \db)
		);
		var line = LineSpreader.ar(outChans, stereo) |> LineBlur.ar(_, 0.25);
		SinkWr.ar('out', outChans, line);
	})
}
