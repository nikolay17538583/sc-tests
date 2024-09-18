{
	JHCachePipe(cacheDir: ~pwd +/+ "audio/cache/guitarScrape")

	.addInputFile(id: \audio, type: Buffer, path: ~pwd +/+ "audio/guitarScrape.wav")

	.addStep(id: \slices, type: Buffer, remake: {
		|env|
		var b = Buffer(s);
		FluidBufNoveltySlice.processBlocking(
			s,
			source: env[\audio], indices: b,
			threshold: 0, algorithm: 4
		);
		b
	})

	.addStep(id: \mkBuffersFunc, type: Function, remake: {
		|env|
		{ (\mfccRaw: Buffer(s), \mfccMean: Buffer(s), \mfccFlat: Buffer(s)) }
	})

	.addStep(id: \calcSlice, type: Function, remake: {
		|env|
		{
			|bufs, sliceStart, sliceEnd|
			FluidBufMFCC.processBlocking(
				source: env[\audio],
				startFrame: sliceStart, numFrames: sliceEnd - sliceStart,
				features: bufs[\mfccRaw], numCoeffs: 21);
			FluidBufStats.processBlocking(
				source: bufs[\mfccRaw], stats: bufs[\mfccMean], select:[\mean]);
			FluidBufFlatten.processBlocking(
				source: bufs[\mfccMean], destination: bufs[\mfccFlat]);
			bufs[\mfccFlat]
		}
	})

	.addStep(id: \normFunc, type: Function, remake: {
		{
			|in|
			var st = (
				\normaliser: FluidNormalize(Server.default),
				\standardiser: FluidStandardize(Server.default),
				\normaliser2: FluidNormalize(Server.default),
				\normed: FluidDataSet(Server.default),
				\std: FluidDataSet(Server.default)
			);
			var out = FluidDataSet(s);
			st[\normaliser].fitTransform(in, st[\normed]);
			Server.default.sync;
			st[\standardiser].fitTransform(st[\normed], st[\std]);
			Server.default.sync;
			st[\normaliser2].fitTransform(st[\std], out);
			Server.default.sync;
			st.do{|b| b.free };
			out
		}
	})

	.addStep(id: \rawDataSet, type: FluidDataSet, remake: {
		|env|
		var finalDataSet = FluidDataSet(s);
		var numThreads = 6;
		env[\slices].loadToFloatArray(action: {
			|slices_array|
			var average_sz = floor(slices_array.size / numThreads);
			var remained = slices_array.size - (average_sz*numThreads);
			var group_sizes = average_sz!(numThreads) + (0!(numThreads - 1) ++ [remained]);

			var indexes = group_sizes.inject([0], {|o, n| o ++ (o[o.size - 1] + n)});
			var index_pairs = [indexes[0..(numThreads - 1)], indexes[1..numThreads]].flop;

			var funcs = index_pairs.collect{ |p, i| {
				var r = ((p[0])..(p[1]));
				r.doAdjacentPairs{
					|start, end, index|

					if(index % 128 == 0, {
						postf("...slicing from % to % on thread %\n",
							slices_array[start], slices_array[end], i)
					});

					if(slices_array[start].isNil.not && slices_array[end].isNil.not, {
						var bufs = env[\mkBuffersFunc].();
						Server.default.sync;

						finalDataSet.addPoint(start,
							env[\calcSlice].(bufs, slices_array[start], slices_array[end]));

						Server.default.sync;

						bufs.do{|b| b.free }
					});
				};
				postf("thread % finished\n", i);
			} };
			funcs.fork();
		});
		Server.default.sync;
		env[\normFunc].(finalDataSet);
	})

	.addStep(id: \mappedDataSet, type: FluidDataSet, remake: {
		|env|
		var mapper = FluidUMAP(s, minDist: 0.2, iterations: 200, learnRate: 0.2, numNeighbours: 10);
		var raw = FluidDataSet(s);
		mapper.fitTransform(env[\rawDataSet], raw);
		Server.default.sync;
		env[\normFunc].(raw);
	})

	.addStep(id: \grid, type: FluidDataSet, remake: {
		|env|
		var grid = FluidDataSet(s);
		var out = FluidDataSet(s);
		FluidGrid(s, 2).fitTransform(env[\mappedDataSet], grid, {"done".warn});
		Server.default.sync;
		FluidNormalize(s).fitTransform(grid, out);
		out;
	})

	.addStep(id: \clusterDataSet, type: FluidDataSet, remake: {
		|env|
		var out = FluidDataSet(s);
		var l = FluidLabelSet(s);
		var kmeans = FluidKMeans(s, 8).fitPredict(env[\mappedDataSet], l);
		kmeans.getMeans(out);
		Server.default.sync;
		out;
	})
	.addStep(id: \getClusters, type: Function, remake: {
		|env|
		var d;
		env[\clusterDataSet].dump{|f| d = f["data"].collect({|v| v}).asArray};
		{ d }
	})




	.addStep(id: \plotFunc, type: Function, remake: {
		|env|
		var slices = env[\slices];
		var audio = env[\audio];
		{|key| fork {
			var tree = FluidKDTree(s);
			tree.fit(env[key]);
			s.sync;

			env[key].dump({
				|dict|
				var xybuf = Buffer.alloc(s, 2);

				defer {
					FluidPlotter(dict: dict, mouseMoveAction: {
						|view, x, y|
						[x,y].postln;
						xybuf.setn(0, [x,y]);
						tree.kNearest(xybuf, 1, {
							|id|
							var index = id.asInteger;
							defer { view.highlight_(id) };

							{
								var start = Index.kr(slices, index);
								var end = Index.kr(slices, index + 1);
								var sig = PlayBuf.ar(1, audio, BufRateScale.ir(audio), 1, start);
								var dur_sec = min((end-start) / SampleRate.ir,1);
								var env = EnvGen.kr(Env([0,1,1,0],[0.01,dur_sec-0.02,0.01].abs), doneAction:2);
								var p = Pan2.ar(sig, 2.0.rand - 1);
								p * env;
							}.play;

						});
					});
				}; //defer
			})
		} }
	})



	.addOutput(newId: \dataSet, originalId: \mappedDataSet)
	.addOutput(newId: \sliceBuffer, originalId: \slices)
	.addOutput(newId: \audioBuffer, originalId: \audio)
	.addOutput(newId: \plotFunc, originalId: \plotFunc)
	.addOutput(newId: \grid, originalId: \grid)
	.addOutput(newId: \clusterDataSet, originalId: \clusterDataSet)
	.addOutput(newId: \getClusters, originalId: \getClusters)

	.eval();

}
