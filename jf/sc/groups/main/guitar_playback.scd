{
	|outChans|

	JHSynthDef.mkSynth(oscid: 'guitar/playback', func: {
		var line = SrcRd.ar('in/mono', 1)
		|> SoftKneeCompressor.ar(_, thresh: -15, ratio: 1/3.5, knee: 5, attack: 0.05, release: 0.1)
		* 10.dbamp
		* Setting.kr('Guitar Playback Amp', 0, \db).dbamp.sanitize
		|> ( _.tanh )
		|> LinePanner.ar(outChans, _, Setting.kr('Guitar Pan Position', 1, \bipolar.asSpec));

		line * OSCIn.kr('dry/amp', 1, 0) |> SinkWr.ar('out', outChans, _);
		line * OSCIn.kr('wet/amp', 1, 0) |> SinkWr.ar('out/wet', outChans, _);
	})

}