var waterSlices = JHFluidSlice(
	numThreads: 6,
	audioPath: ~pwd +/+ "audio/waterDrops.wav",
	cacheDirectory: ~pwd +/+ "audio/cache/waterDrops",
	jhfluidSlicerAnalysis: JHFluidSlicerAnalysis(
		bufferMaker: {(
			\mfccRaw: Buffer(s),
			\mfccMean: Buffer(s),
			\mfccFlat: Buffer(s),
			/*
			\result: Buffer.alloc(s, 2),
			\spectralShape: Buffer.new(s),
			\centroid: Buffer(s),
			\centroidStats: Buffer(s),
			\centroidMean: Buffer(s),
			\loudness: Buffer(s),
			\loudnessDB: Buffer(s),
			\loudnessDBStats: Buffer(s),
			\loudnessDBMean: Buffer(s)
			*/
		)},
		funcPerSlice: {
			|bufs, audio, sliceStart, sliceEnd|

			FluidBufMFCC.processBlocking(source: audio, startFrame: sliceStart, numFrames: sliceEnd - sliceStart, features: bufs[\mfccRaw], numCoeffs: 21);
			FluidBufStats.processBlocking(source: bufs[\mfccRaw], stats: bufs[\mfccMean], select:[\mean]);
			FluidBufFlatten.processBlocking(source: bufs[\mfccMean], destination: bufs[\mfccFlat]);
			bufs[\mfccFlat]
			/*
			FluidBufSpectralShape.processBlocking(source: audio, startFrame: sliceStart,
			numFrames: sliceEnd - sliceStart, features: bufs[\spectralShape]);

			FluidBufSelect.processBlocking(source: bufs[\spectralShape], destination: bufs[\centroid], channels: [0]);


			FluidBufStats.processBlocking(source: bufs[\centroid], stats: bufs[\centroidStats]);
			Server.default.sync;
			FluidBufSelect.processBlocking(source: bufs[\centroidStats],
			destination: bufs[\centroidMean],
			indices: [0], channels: [0]); //mean

			FluidBufLoudness.processBlocking(source: audio, startFrame: sliceStart, numFrames: sliceEnd - sliceStart,
			features: bufs[\loudness]);
			FluidBufSelect.processBlocking(source: bufs[\loudness], destination: bufs[\loudnessDB],
			channels: [1]);
			FluidBufStats.processBlocking(source: bufs[\loudnessDB], stats: bufs[\loudnessDBStats]);
			Server.default.sync;
			FluidBufSelect.processBlocking(source: bufs[\loudnessDBStats],
			destination: bufs[\loudnessDBMean],
			indices: [0], channels: [0]);

			FluidBufCompose.processBlocking(source: bufs[\centroidMean],
			destination: bufs[\result], numFrames: 1, destStartFrame: 0);
			FluidBufCompose.processBlocking(source: bufs[\loudnessDBMean],
			destination: bufs[\result], numFrames: 1, destStartFrame: 1);
			Server.default.sync;
			bufs[\result];
			*/
		}
	)
);

var waterKDTreeNeighbours = 4;
var waterInputBuf = Buffer.alloc(s, 2);
var waterKDTree = {
	var r = FluidDataSet(s);
	var maped = FluidUMAP(s, minDist: 0.3);

	var t = FluidKDTree(Server.default, waterKDTreeNeighbours);
	Server.default.sync;
	"Starting mapped".postln;
	maped.fitTransform(waterSlices.dataSet, r);
	Server.default.sync;
	"Fitting KDTREE".postln;
	t.fit(r);
	Server.default.sync;
	t;
}.();

~waterkdtree = waterKDTree;

{
	var in = JHSynthDef.mkSynth(oscid: 'waterGrain/input', func: {
		var loc = OSCIn.kr('location', 2, [0, 0]);
		FluidKrToBuf.kr(loc, waterInputBuf);
		SendReply.kr(Impulse.kr(250), '/waterGrain/relay/result', loc);
	});

	var out = JHSynthDef.mkSynth(oscid: 'waterGrain/output', func: {
		var num = 5;
		var upd_rate = OSCIn.kr('update/rate', 1, 0).linexp(0, 1, 1, 100);
		var new_grain_t = Dust.ar( upd_rate!(waterKDTreeNeighbours*num)).abs > 0.00001;

		var new_index = {
			var choice = ({(0..(waterKDTreeNeighbours - 1))}!num).flat;
			var selector = choice * OSCIn.kr('radius', 1, 1).clip(0,1);
			var raw = Select.ar(selector, \index.ar(0!waterKDTreeNeighbours));
			Latch.ar(raw, new_grain_t);
		}.();

		var startFrame = BufRd.ar(1, waterSlices.slicesBuffer, new_index, interpolation: 1);
		var endFrame = BufRd.ar(1, waterSlices.slicesBuffer, new_index + 1, interpolation: 1);

		var number_of_frames = endFrame - startFrame;
		var duration = number_of_frames * (BufDur.ir(waterSlices.audioBuffer) / BufFrames.ir(waterSlices.audioBuffer));
		var overlap = OSCIn.kr('overlap', 1, 0).lincurve(0, 1, 0.8, 15, -2);

		var imp = {
			var reg = Impulse.ar(duration.reciprocal * overlap, num.collect{|n| n / num});
			var ir = Dust.ar(duration.reciprocal * overlap, num.collect{|n| n / num});
			var f = OSCIn.kr('regularity', 1, 1).clip(0,1);
			var se = Demand.ar(reg + ir, 0, Dwrand([0, 1], [f, 1 - f], inf));
			(reg * se) + (ir * (1 - se));
		}.();

		//var gains = Decay.ar(new_grain_t, 100/upd_rate);
		var signal = GrainBuf.ar(1,
			imp,
			duration * OSCIn.kr('dur/scale', 1, 0.5).bilin(0.5, 0, 1, 1, 0, 4),
			waterSlices.audioBuffer,
			OSCIn.kr('rate', 1, 0.5).bilin(0.5, 0, 1, 1, 0.25, 4),
			startFrame / BufFrames.ir(waterSlices.audioBuffer),
		);
		//* gains * (1/(waterKDTreeNeighbours*num));


		var ambi = FoaEncode.ar(signal, FoaEncoderMatrix.newPanto(signal.size));
		var squish = FoaDirectO.ar(ambi, OSCIn.kr('ambi/squish', 1, 0) * pi/2);
		var pan = FoaPress.ar(squish,
			angle: OSCIn.kr('ambi/degree', 1, 0.5).linlin(0,1,-pi/2, pi/2),
			theta: OSCIn.kr('ambi/theta', 1, 0.5).linlin(0, 1, -pi, pi)
		);

		SinkWr.ar('out/ambi', 4, pan * OSCIn.kr('dry/amp', 1, 0));
		SinkWr.ar('out/ambi/wet', 4, pan * OSCIn.kr('wet/amp', 1, 0));
	})
	.connect(_.getOut('out/ambi'), ['output/mixer', 'in/ambi'])
	.connect(_.getOut('out/ambi/wet'), ['effect/reverb', 'in/ambi']);


	OSCdef('waterGrainRelayOSCDef', {
		|msg|
		waterKDTree.kNearest(waterInputBuf, waterKDTreeNeighbours, { |i|
			out.node.set(\index, i.collect{|n| n.asInteger })
		});
	}, '/waterGrain/relay/result', s.addr);




}
