{
	|outChans|
	var encoder = FoaEncoderKernel.newDiffuse(4);
	s.sync;

	JHSynthDef.mkSynth(oscid: 'bass/wobble', func: {
		var freq = OSCIn.kr('freq', 1, 0).linlin(0, 1, 16, 45);
		var bpBase = OSCIn.kr('bpf', 1, 0).linexp(0, 1, 30, 300);
		var combDecay = OSCIn.kr('comb/decay', 1, 0).lincurve(0, 1, 0.01, 2.5, -0.5);
		var sticking = OSCIn.kr('stick/freq', 1, 0).linexp(0, 1, 0.1, 15)
		|> LFSaw.ar(_) |> (_.range(0, 1)) |> (_.pow(3));

		LFSaw.ar(freq)
		|> BPF.ar(_, bpBase * [1, 2, 3.5], 0.25)

		|> FreqShift.ar(_, [0, 15, 27.3], [0.0, 0.4, -0.2])
		|> LeakDC.ar(_)
		|> Mix.ar(_)

		|> (_ * sticking)

		|> CombN.ar(_, 0.3, [0.0, 0.04, 0.02, 0.21, 0.28, 0.15], combDecay)
		|> Mix.ar(_)

		|> (_ * 2 ) + 0.35
		|> (_.softclip)
		|> (_ / 2)  - 0.35

		|> BHiShelf.ar(_, 450, 1.0, 20) - 0.3 * 2
		|> CompanderD.ar(_, -20.dbamp, slopeAbove: 1/4)
		|> (_.softclip)
		|> BHiShelf.ar(_, 450, 1.0, -25) + 0.3

		|> BLowShelf.ar(_, 120, 1.0, 3)
		|> LeakDC.ar(_)

		|> BRF.ar(_, 130, 0.8)
		|> BRF.ar(_, 1300, 1)
		|> LPF.ar(_, MouseX.kr(500, 13000, -2))
		|> MidEQ.ar(_, LFNoise2.kr(1!3).range(830, 8831), 2, 6)
		|> (_.flat)	|> Mix.ar(_) * 3
		|> CompanderD.ar(_, -10.dbamp, slopeAbove: 1/2.5) * 2
		|> LeakDC.ar(_)
		* Setting.kr('FixedGain', 0, \db, 1).dbamp.sanitize *  OSCIn.kr('dry/amp', 1, 0)
		|> (_.tanh)
		|> FoaEncode.ar(_, encoder)
		|> FoaDecode.ar(_, FoaDecoderMatrix.newPanto(outChans))
		|> LinePushAway.ar(_,
			OSCIn.kr('pan/pos', 1, 0.5).linlin(0, 1, -1, 1),
			OSCIn.kr('pan/dis', 1, 0).clip(0, 1)
		)
		|> JHSynthMixin(\AnalysisAmp, _)
		|> SinkWr.ar('out', outChans, _)
	})


}
