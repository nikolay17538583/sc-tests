JHFluidSlicerAnalysis {
	var <bufferMaker, <funcPerSlice;
	*new {
		|bufferMaker, funcPerSlice|
		var args = funcPerSlice.def.argNames;
		[\bufs, \audio, \sliceStart, \sliceEnd].collect({
			|n, i|
			if(args[i] != n,
				{format("JHFluidSlicerAction must have an argument \"%\""
					"at position \"%\" - and you cannot miss one!",
					n, i).error; ^nil});
		});
		^super.newCopyArgs(bufferMaker, funcPerSlice);
	}

	addToDataSet {
		|dataSet, audio, sliceStart, sliceEnd, sliceIndex|
		var buffers = {
			var b = this.bufferMaker.();
			Server.default.sync;
			b
		}.();
		var res = this.funcPerSlice.(buffers, audio, sliceStart, sliceEnd);
		Server.default.sync;
		dataSet.addPoint(sliceIndex.asString, res);
		Server.default.sync;
		buffers.do{|buf| buf.free };
	}
	toJSON {
		^format("{\"function\": [%],\n \"bufferMaker\": [%]\n }",
			funcPerSlice.def.code.reduce{|l, r| l.asString ++ "," + r.asString},
			bufferMaker.def.code.reduce{|l, r| l.asString ++ "," + r.asString}
		)
	}
}


JHFluidSlice {
	var audioPath, cacheDirectory, jhfluidSlicerAnalysis, force, numThreads;

	var <audioBuffer, <slicesBuffer, <dataSet;

	*new {
		|numThreads, audioPath, cacheDirectory, jhfluidSlicerAnalysis, forceReload=false|
		^super.new.init(numThreads, audioPath, cacheDirectory, forceReload, jhfluidSlicerAnalysis)
	}

	init {
		|nt, au, ca, forceReload, analysis|
		numThreads = nt;
		jhfluidSlicerAnalysis = analysis;
		audioPath = au.asAbsolutePath;
		cacheDirectory = ca.asAbsolutePath;
		force = forceReload;

		this.load();
		^this;
	}

	load {
		if(this.cacheIsUpToDate(),
			{if(force.not, {this.loadFromCache()}, {this.remakeCache()})},
			{this.remakeCache()});
	}

	cacheIsUpToDate {
		if(File.exists(cacheDirectory +/+ "cacheState.json"),
			{^ (this.toJSON().asString == File.readAllString(cacheDirectory +/+ "cacheState.json").asString) },
			{^false});
	}

	toJSON {
		^format("{\"analysis\": %, \"audioBuffer\": \"%\", \"cachDir\": \"%\"}",
			jhfluidSlicerAnalysis.toJSON,
			audioPath,
			cacheDirectory)
	}

	loadFromCache{
		dataSet = FluidDataSet(Server.default);
		dataSet.read(cacheDirectory +/+ "dataSet.json");
		slicesBuffer = Buffer.read(Server.default, cacheDirectory +/+ "slicesBuffer.wav");
		audioBuffer = Buffer.read(Server.default, audioPath);
	}



	remakeCache {
		var rawDataSet = FluidDataSet(Server.default);
		audioBuffer = Buffer.read(Server.default, audioPath);
		slicesBuffer = Buffer(Server.default);
		dataSet = FluidDataSet(Server.default);

		Server.default.sync;
		FluidBufNoveltySlice.process(
			Server.default, audioBuffer, indices: slicesBuffer, threshold: 0, minSliceLength: 5
		).wait;
		Server.default.sync;


		slicesBuffer.loadToFloatArray(action:{
			|slices_array|
			var average_sz = floor(slices_array.size / numThreads);
			var remained = slices_array.size - (average_sz*numThreads);
			var group_sizes = average_sz!(numThreads) + (0!(numThreads - 1) ++ [remained]);

			var indexes = group_sizes.inject([0], {|o, n| o ++ (o[o.size - 1] + n)});
			var index_pairs = [indexes[0..(numThreads - 1)], indexes[1..numThreads]].flop;

			var funcs = index_pairs.collect{ |p,i| {
				var r = ((p[0])..(p[1]));
				postf("starting slice from % to % on thread %\n", p[0], p[1], i);
				r.doAdjacentPairs{
					|start, end, index|
					if(index % 128 == 0, {
						postf("...slicing from % to % on thread %\n",
							slices_array[start], slices_array[end], i)
					});
					if(slices_array[start].isNil.not && slices_array[end].isNil.not,{
						jhfluidSlicerAnalysis.addToDataSet(
							rawDataSet, audioBuffer, slices_array[start], slices_array[end], start
						)
					});
				};
				postf("thread % finished\n", i);
			} };
			funcs.fork();
		});

		Server.default.sync;

		{
			var normaliser = FluidNormalize(Server.default);
			var standardiser = FluidStandardize(Server.default);
			var normaliser2 = FluidNormalize(Server.default);
			var normed = FluidDataSet(Server.default);
			var std = FluidDataSet(Server.default);
			normaliser.fitTransform(rawDataSet, normed);
			Server.default.sync;
			standardiser.fitTransform(normed, std);
			Server.default.sync;
			normaliser2.fitTransform(std, dataSet);
			Server.default.sync;
		}.();

		dataSet.write(cacheDirectory +/+ "dataSet.json");
		slicesBuffer.write(cacheDirectory +/+ "slicesBuffer.wav", sampleFormat: "float");
		File.use(cacheDirectory +/+ "cacheState.json", "w", { |f| f.write(this.toJSON) });

		^this;
	}


}



JHFluidForEachSlice {
	*new {
		|slices, perSliceFunc, numThreads|

		slices.loadToFloatArray(action: {
			|slices_array|
			var average_sz = floor(slices_array.size / numThreads);
			var remained = slices_array.size - (average_sz*numThreads);
			var group_sizes = average_sz!(numThreads) + (0!(numThreads - 1) ++ [remained]);

			var indexes = group_sizes.inject([0], {|o, n| o ++ (o[o.size - 1] + n)});
			var index_pairs = [indexes[0..(numThreads - 1)], indexes[1..numThreads]].flop;

			var funcs = index_pairs.collect{ |p, i| {
				var r = ((p[0])..(p[1]));
				postf("starting slice from % to % on thread %\n", p[0], p[1], i);
				r.doAdjacentPairs{
					|start, end, index|
					if(index % 128 == 0, {
						postf("...slicing from % to % on thread %\n",
							slices_array[start], slices_array[end], i)
					});
					if(slices_array[start].isNil.not && slices_array[end].isNil.not,{
						perSliceFunc.(
							slices_array[start], slices_array[end], start
						)
					});
				};
				postf("thread % finished\n", i);
			} };
			funcs.fork();
		});
	}
}












