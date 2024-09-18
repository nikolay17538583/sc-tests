/*{
	JHGroup().withGroup {
		JHSynthDef.mkSynth('output/mixer', func: {
			var fadeIn = DelayN.ar(Line.ar(0, 1, 2), 3, 3);

			var in = SinkRd.ar('in', ~outChans) * fadeIn
			|> Limiter.ar(_, -1.dbamp, 0.0001);

			JHSynthMixin(\AnalysisMixin, Mix.ar(in));

			Out.ar(0, in);
		})
	}
}*/