JHCacheStage {
	var id, funcCachePath, type, func, funcCache, cacheDir;
	*new{
		|id, type, func, cacheDir|
		var getfuncdef = {|f| f.def.sourceCode.replace($ , "").replace($\n, "").replace($\t, "") };
		^super.newCopyArgs(
			id,
			id.asString ++ "cache",
			type,
			func,
			getfuncdef.(func),
			cacheDir
		)
	}

	writeIntoEnvDidRemake {
		|buildEnv, shouldRemake|
		if(shouldRemake.not && File.exists(cacheDir +/+ funcCachePath), {
			if((File.readAllString(cacheDir +/+ funcCachePath) == funcCache), {
				postf("loading %\n", id);
				buildEnv[id] = this.prLoad(buildEnv);
				^false
		})});
		postf("writing %\n", id);
		buildEnv[id] = this.prWrite(func.(buildEnv));
		^true;
	}

	prLoad {
		|buildEnv|
		^switch(type,
			{Buffer}, {Buffer.read(Server.default, cacheDir +/+ id.asString ++ ".wav")},
			{FluidDataSet}, {FluidDataSet(Server.default).read(cacheDir +/+ id.asString ++ ".json")},
			{Function}, {func.(buildEnv)}
		)
	}
	prWrite {
		|thing|
		File.use(cacheDir +/+ funcCachePath, "w", {|f| f.write(funcCache.asString)});
		switch(type,
			{Buffer}, {thing.write(cacheDir +/+ id.asString ++ ".wav", sampleFormat: "float")},
			{FluidDataSet}, {thing.write(cacheDir +/+ id.asString ++ ".json")}
		);
		^thing
	}
}

JHCacheFile {
	var id, fileCachePath, type, filePath, cacheDir, thisFileCache;
	*new {
		|id, type, filePath, cacheDir|
		^super.newCopyArgs(
			id,
			id.asString ++ "cache",
			type,
			filePath,
			cacheDir
		).prInit();
	}
	*prFileCacher {
		|p|
		//dumb ... check date file was made instead?
		^if(File.exists(p), { File.readAllString(p) }, "" )
	}

	prInit {
		thisFileCache = JHCacheFile.prFileCacher(filePath);
		^this;
	}

	writeIntoEnvDidRemake {
		|buildEnv, shouldRemake|
		if(shouldRemake.not && File.exists(cacheDir +/+ fileCachePath), {
			if((File.readAllString(cacheDir +/+ fileCachePath) == thisFileCache), {
				postf("loading %\n", id);
				buildEnv[id] = this.prLoad();
				^false
		})});
		postf("writing %\n", id);
		buildEnv[id] = this.prWrite();
		^true;
	}
	prLoad {
		^switch(type,
			{Buffer}, {Buffer.read(Server.default, filePath)},
			{FluidDataSet}, {FluidDataSet(Server.default).read(filePath)}
		)
	}
	prWrite {
		File.use(cacheDir +/+ fileCachePath, "w", {|f| f.write(thisFileCache)});
		^this.prLoad();
	}
}

JHCachePipe {
	var cacheDir, buildSteps, buildEnv, outputs;
	*new {
		|cacheDir|
		File.mkdir(cacheDir);
		^super.newCopyArgs(cacheDir, [], (), []);
	}

	addInputFile {
		|id, type, path|
		buildSteps = buildSteps ++ JHCacheFile(id, type, path, cacheDir);
		^this;
	}

	addStep {
		|id, type, remake|
		buildSteps = buildSteps ++ JHCacheStage(id, type, remake, cacheDir);
		^this;
	}

	addOutput {
		|newId, originalId|
		outputs = outputs ++ [(\idInBuildEnv: originalId, \newId: newId)];
		^this;
	}
	eval {
		this.prEval();
		^this;
	}

	prEval {
		buildSteps.inject(false, {|p, next|
			Server.default.sync;
			next.writeIntoEnvDidRemake(buildEnv, p)
		})
	}

	prHasBeenRunBefore { ^(buildEnv.size != 0) }

	return {
		|output|
		var found = outputs.detect({|o| o[\newId] == output });
		^found !? { buildEnv[found[\idInBuildEnv]] } ?? {format("output % not specified", output).error};
	}
}






