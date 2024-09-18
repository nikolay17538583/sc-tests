
(
Server.killAll;

s.waitForBoot{
~slicer = JHFluidSlicerAnalysis.new(
	bufMaker: {(
		\result: Buffer.alloc(s, 2),
		\spectralShape: Buffer.new(s), \centroid: Buffer(s), \centroidStats: Buffer(s), \centroidMean: Buffer(s),
		\loudness: Buffer(s), \loudnessDB: Buffer(s), \loudnessDBStats: Buffer(s), \loudnessDBMean: Buffer(s)
	)},
	funcPerSlice: {
		|bufs, audio, sliceStart, sliceEnd|

		FluidBufSpectralShape.processBlocking(source: audio, startFrame: sliceStart, numFrames: sliceEnd - sliceStart, features: bufs[\spectralShape]);
		FluidBufSelect.processBlocking(source: bufs[\spectralShape], destination: bufs[\centroid], channels: [0]);
		FluidBufStats.processBlocking(source: bufs[\centroid], stats: bufs[\centroidStats]);
		FluidBufSelect.processBlocking(source: bufs[\centroidStats], destination: bufs[\centroidMean], indices: [(bufs[\centroidStats].numFrames / 2).floor], channels: [0]); //mean

		FluidBufLoudness.processBlocking(source: audio, startFrame: sliceStart, numFrames: sliceEnd - sliceStart, features: bufs[\loudness]);
		FluidBufSelect.processBlocking(source: bufs[\loudness], destination: bufs[\loudnessDB], channels: [1]);
		FluidBufStats.processBlocking(source: bufs[\loudnessDB], stats: bufs[\loudnessDBStats]);
		FluidBufSelect.processBlocking(source: bufs[\loudnessDBStats], destination: bufs[\loudnessDBMean], indices: [(bufs[\loudnessDBStats].numFrames / 2).floor], channels: [0]);

		FluidBufCompose.processBlocking(source: bufs[\centroidMean], destination: bufs[\result], numFrames: 1, destStartFrame: 0);
		FluidBufCompose.processBlocking(source: bufs[\loudnessDBMean], destination: bufs[\result], numFrames: 1, destStartFrame: 1);
	}
);


~a = JHFluidSlice.new(audioPath: "~/some/path", cacheDirectory: "~/Desktop",
	jhfluidSlicerAnalysis: ~slicer, forceReload: false
);

}

)

