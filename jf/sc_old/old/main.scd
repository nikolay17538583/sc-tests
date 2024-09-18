// useful helpers

JHSynthControlsGUI.show(); // show performance-specific/mix settings
JHSynthControls.saveTo(~pwd +/+ "control_presets/default.json"); // save mix settings - change name as needed

JHOSCGUI.show(); // debug all osc information

s.meter;

s.plotTree;
s.freqscope


















// launch peice
(

s.freeAll;
s.quit;
Server.killAll;

s.options.memSize = 2.pow(20); // about 1 gb - overkill
s.options.memoryLocking = true;
s.options.numOutputBusChannels = 14; // 2 stereo, 1 spacer, 8 surround sound, 1 spacer, 2 subs

~pwd = "/home/jordan/Work/projects/jellyfish/sc"; // project working directory

~to_unity = ~to_unity ? NetAddr("localhost", 51121);


// ALL OSC INFORMATION SHOULD BE NORMALISED BETWEEN 0 AND 1

s.waitForBoot {
	~groups = [\inputs, \sources, \mid_effects, \late_effects, \outputs, \osc_relay]
	.collect({|a| var o = ()[a] = Group(s, \addToTail); s.sync; o }).reduce{|l,r| l++r};

	~nullBus = ~nullBus ? Bus.audio(s, 8);
	~null = ~nullBus.index;

	~micBus = ~micBus ? Bus.audio(s, 1);
	s.sync;



	// loads

	//PathName(~pwd +/+ "synthDefs").files.do{ |f| f.fullPath.load };

	//(~pwb +/+ "external_osc.scd").load;


	JHSynthDef(\MicrophoneIn, outputSrc: (\micOut: 1), function: {
		var mic = PipeUGen.ar(
			Mix.ar(SoundIn.ar(0)),
			{|m| BLowPass4.ar(m, \ctlMicrophoneLPF.kr(15000, spec:\freq.asSpec)) },
			{|m| BHiPass4.ar(m, \ctlMicrphoneHPF.kr(20, spec:\freq.asSpec)) },
		);
		Out.ar(\micOut.kr(~null), mic);
	})


	JHSynthDef(\MainOutput, function: {
		var in = PipeUGen.ar(\in.ar(0!4),
			{|i| Limiter.ar(i, -1.dbamp, 0.0001) },
			{|i| FoaRotate.ar(i, \ctlRoomRotate.kr(0, spec: \phase.asSpec)) },
			{|i| FoaDirectX.ar(i, \ctlRoomXSpread.kr(0, spec: \phase.asSpec)) }
		);
		var subcut = \ctlSubCut.kr(350, spec: \freq.asSpec).clip(20, inf);
		var subgain = \ctlSubGain.kr(-5, spec:\db.asSpec).dbamp.clip(0, 1);
		var sub = BLowPass4.ar(in, subcut) * subgain;
		Out.ar(0,  FoaDecode.ar(in, FoaDecoderMatrix.newStereo));   // [0,1]
		Out.ar(3,  FoaDecode.ar(in, FoaDecoderMatrix.newPanto(8))); // [3,4,5,6, 7,8,9,10]
		Out.ar(12, FoaDecode.ar(in, FoaDecoderMatrix.newStereo(pi, 0.75)));   // [11, 12]
	})
	.mkSynth((uuid: 'Main Output', target: ~groups.outputs))
	.describeControl(\ctlRoomRotate, "rotate speaker setup")
	.describeControl(\ctlRoomXSpread, "reduce vertical spatial dimension");



	~ir_york = Conv(~pwd +/+ "audio/ir/york_minster_ambi.wav");
	JHSynthDef(\yorkReverb, (\out: 4, \amplitude: 1), {
		var n = ~ir_york.ar(\in.ar(0!4)) * \ctlReverbAmp.kr(-20, spec: \db.asSpec).dbamp;
		var panned = JHAmbiPanWithOSCSinks.mixIn(n);
		Out.kr(\amplitude.kr(~null), Mix.kr(Amplitude.kr(panned).flatten));
		Out.ar(\out.kr(~null), panned);
	})
	.mkSynth((uuid: 'York Reverb', target: ~groups.late_effects))
	.registerOSCSrc(\amplitude, JHOSCStore.mkSrcInternal('/yorkReverb/amp'))
	.registerWithMixIn(JHAmbiPanWithOSCSinks, '/yorkReverb/')
	.connect(\out, JHSynthStore.get('Main Output'), \in);



	JHSynthDef(\MicrophoneIn,
		outputSpec: (\amplitude: 1, \skewness: 1, \centroid: 1, \micOutConst: ~micBus.numChannels),
		function: {
			var mic = PipeUGen.ar(
				Mix.ar(SoundIn.ar(0)),
				{|m| BLowPass4.ar(m, \ctlMicrophoneLPF.kr(15000, spec:\freq.asSpec)) },
				{|m| BHiPass4.ar(m, \ctlMicrphoneHPF.kr(20, spec:\freq.asSpec)) },
			);

			var fft = FFT(LocalBuf(2048), mic);
			var specShape = FluidSpectralShape.kr(mic,
				select: [\centroid, \skewness],
				minFreq: 20,
				windowSize: 2048
			);

			var centroid_range = \ctlMicInCentroidRange.kr([200, 15000], spec: \freq.asSpec);
			var centroid = specShape[0].explin(centroid_range[0], centroid_range[1], 0, 1);

			var skewness_range = \ctlMicInSkewnessRange.kr([0.2, 16]);
			var skewness = specShape[1].linlin(skewness_range[0], skewness_range[1], 0, 1);

			Out.kr(\centroid.kr(~null), centroid);
			Out.kr(\skewness.kr(~null), skewness);
			Out.kr(\amplitude.kr(~null), Amplitude.kr(mic).lincurve(0,1, 0, 1, -4));

			Out.ar(\micOutConst.kr(~micBus), mic);
	})
	.mkSynth((uuid: 'Microphone In', target: ~groups.inputs))
	.registerOSCSrc(\amplitude, JHOSCStore.mkSrcInternal('/mic/amplitude'))
	.registerOSCSrc(\skewness, JHOSCStore.mkSrcInternal('/mic/skewness'))
	.registerOSCSrc(\centroid, JHOSCStore.mkSrcInternal('/mic/centroid'));






	JHSynthDef(\MicRaw, (\wetOut: 4, \dryOut: 4), {
		var ambi = FoaEncode.ar(\in.ar(0), FoaEncoderMatrix.newDirection);
		var r = FoaRotate.ar(ambi, Phasor.ar(0, 0.2/s.sampleRate, 0, 2*pi));
		var panned = JHAmbiPanWithOSCSinks.mixIn(ambi);
		Out.ar(\wetOut.kr(~null), panned * K2A.ar(\wet.kr(0)));
		Out.ar(\dryOut.kr(~null), panned * K2A.ar(\dry.kr(0)));
	})
	.mkSynth((uuid: 'Microphone Raw', target: ~groups.sources))
	.routeInTo(\in,
	.connect(\wetOut, JHSynthStore.get('York Reverb'), \in)
	.connect(\dryOut, JHSynthStore.get('Main Output'), \in)
	.registerOSCSink(\wet, JHOSCStore.mkSinkInternal('/mic/raw/wet'))
	.registerOSCSink(\dry, JHOSCStore.mkSinkInternal('/mic/raw/dry'))
	.registerWithMixIn(JHAmbiPanWithOSCSinks, '/mic/raw');




	~ticker = JHSynthDef(\Ticker, (\tick:1), function: {
		Out.kr(\tick.kr(~null), MouseX.kr() > 0.5)
	}).mkSynth((uuid: 'Ticker', target: ~groups.sources));




	JHSynthDef(\oscSinkExample, function: {
		\freq.kr(0).linexp(0, 1, 20, 20000);
	}).mkSynth((uuid: 'OSC Sink Example'))
	.registerOSCSink(\freq, JHOSCStore.mkSinkInternal('/sinktest/freq'));

	JHSynthDef(\oscSrcExample, (\wiggle: 1), function: {
		Out.kr(\wiggle.kr(~null), LFDNoise3.kr(2).range(0, 1));
	}).mkSynth((uuid: 'OSC Src Example'))
	.registerOSCSrc(\wiggle, JHOSCStore.mkSrcInternal('/srctest/wiggle'));







	JHOSCStore.createRelaySynth(~groups.osc_relay, triggerRate: 120);


	JHOSCMapStore.append(duration: (\min: 2, \max: 3), map:{
		|src, isActive|
		( '/sinktest/freq' : src['/srctest/wiggle'] )
	});
	JHOSCMapStore.append(duration: (\min: 10, \max: 99), fadeIn: (\time: 3, \curve: 0), map:{
		|src, isActive|
		( '/sinktest/freq' : 0.2 )
	});


	~osc_mapper = JHOSCMapperSynth.mkSynth((uuid: 'OSC Mapper', target: ~groups.osc_relay));

	connect(~ticker, \tick, ~osc_mapper, \inTickTrigger);

	JHSynthControls.loadFrom(~pwd +/+ "control_presets/default.json");
};

)





(_ + 2)


>>= _.listenTo(\in, d.get(\mic))



f = _.asdfw
f.(1)

ParamView




Quarks.gui

_+1




Function










