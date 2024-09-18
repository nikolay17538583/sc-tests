JHOSCMap {
	var <duration;
	var <map;
	var <fadeInTime;
	var <fadeInCurve;

	*new {
		|duration, fadeIn, map|
		var args = map.def.argNames;
		if(args.includes(\src).not,
			{"JHOSCMap: map does not have the argument \"src\"".error; ^nil});
		if(args.includes(\isActive).not,
			{"JHOSCMap: map does not have the argument \"isActive\"".error; ^nil});
		if(args.size != 2,
			{"JHOSCMap: map must have exactly 2 arguments, \\src and \\isActive".error; ^nil});

		if((duration.size != 2) || (duration.includesKey(\min).not) || (duration.includesKey(\max).not),
			{"JHOSCMap: duration must have two keys, min and max".error; ^nil});

		^super.new.init(duration, fadeIn, map)
	}

	init { |d, fadein, f|
		var lerp = (\time:0, \curve:0) ++ ( fadein ? () );
		duration = d;
		map = f;
		fadeInTime = lerp.time;
		fadeInCurve = lerp.curve;
		^this;
	}
}

JHOSCMapStore {
	classvar <maps;
	*append {
		|duration, fadeIn, map|
		maps = maps ?? {[]};
		maps = maps ++ JHOSCMap(duration, fadeIn, map);
		^this
	}
	*reset {
		maps = [];
	}
}

JHOSCSrcSafe {
	var underlying;
	*new {|col| ^super.newCopyArgs(col) }
	*errorState { ^'error' }
	at {|key|
		^underlying.atFail(key, {
			format("Could not find key in collection - defaulting to 0 - key: %, collection: %",key, underlying.keys).error;
			JHOSCSrcSafe.errorState()
		});
	}
}

JHOSCMapperSynth {
	classvar jhSynth;
	*free {
		try {jhSynth.free}{};
	}
	*trialMap {
		|func|
		Server.default.waitForBoot {
			var thisMapStore = [func].flat.collect({|f| JHOSCMap((\min:9999,\max:9999), map: f)});
			try {jhSynth.free}{};
			Server.default.sync;
			jhSynth = JHSynthDef.mkSynth(oscid: 'jhoscmappersynth', func: {
				var oscmaps = {
					/* [...(\addr: ugen)] */
					var defaultMap = JHOSCStore.getSinks.collect({|port| In.kr(port.bus, port.numChannels) });
					var srcs = JHOSCStore.getSrcs.collect({|port| In.kr(port.bus, port.numChannels) });
					var safeSrcs = JHOSCSrcSafe(srcs);
					var maps = thisMapStore.collect({
						|thisMap, i|
						var newMap = thisMap.map.(src: safeSrcs, isActive: 1)
						.reject{ |m, k|
							var r = (m == JHOSCSrcSafe.errorState());
							if(r, {format("Invalid src id for key \"%\" at map index % --- key was rejected", k, i).error});
							r
						};
						defaultMap ++ newMap;
					});
					var allAddressesValid = maps.collect({
						|mapEvent, index|
						mapEvent.collect({
							|func, addr|
							if(JHOSCStore.getSinks.includesKey(addr).not, {
								format("Could not find osc address \"%\" in map index %\n", addr, index).error;
								false;
							}, { true })
						}).every{|i| i}
					}).every{|i| i};
					if(allAddressesValid, maps, nil);
				}.();

				var outs = JHOSCStore.getSinks.collect({
					|port, addr|
					var t =  oscmaps.collect{ |m| m[addr] };
					Out.kr(port.bus, LinSelectX.kr(0, t))
				});
			});
		}
		^jhSynth
	}


	*mkSynth {
		try {jhSynth.free}{};
		Server.default.sync;
		jhSynth = JHSynthDef.mkSynth(oscid: 'jhoscmappersynth', func: {
			// tick could be anything, but here it counts in seconds.
			// this is the value used in the maps min and max times.
			// i.e., if ticks happen once a second, then the min and max are mesured in seconds
			var tick = Impulse.kr(1);
			var activeTick = Demand.kr(tick, 0, Dseries(0, 1, inf));

			var mapNumber = {
				var b = [0, 0].as(LocalBuf);
				var previousMapNumber = Demand.kr(tick, 0, Dbufrd(b, 0));
				var startingTick = Demand.kr(tick, 0, Dbufrd(b, 1));

				var mapMinDurs = JHOSCMapStore.maps.collect{|m| DC.kr(m.duration[\min]) };
				var mapMaxDurs = JHOSCMapStore.maps.collect{|m| DC.kr(m.duration[\max]) };

				var tickInThisMap = Demand.kr(tick, 0, activeTick - startingTick);

				var reachedMin = Demand.kr(tick, 0, tickInThisMap >= Select.kr(previousMapNumber, mapMinDurs));
				var reachedMax = Demand.kr(tick, 0, tickInThisMap >= Select.kr(previousMapNumber, mapMaxDurs));
				var mayAdvance = ((reachedMin * SinkRd.kr('mayAdvanceEarly', 1)) + reachedMax).clip(0, 1);


				var nextMapNumber = Demand.kr(mayAdvance, 0, Dseries(1, 1)).clip(0, JHOSCMapStore.maps.size);

				Demand.kr(Changed.kr(nextMapNumber), 0, Dbufwr(nextMapNumber, b, 0));
				Demand.kr(Changed.kr(nextMapNumber), 0, Dbufwr(activeTick + 1, b, 1));

				nextMapNumber
			}.();

			var mapNumberSmooth = {
				var fadeInTime = Select.kr(mapNumber, JHOSCMapStore.maps.collect{|m| DC.kr(m.fadeInTime)} );
				var fadeInCurve = Select.kr(mapNumber, JHOSCMapStore.maps.collect{|m| DC.kr(m.fadeInCurve)} );
				var lag = VarLag.kr(in: mapNumber, time: fadeInTime, curvature: fadeInCurve, start: 0);
				OnePole.kr(lag, 0.94) // smooths any spikes in f''
			}.();

			var oscmaps = {
				/* [...(\addr: ugen)] */
				var defaultMap = JHOSCStore.getSinks.collect({|port| In.kr(port.bus, port.numChannels) });
				var srcs = JHOSCStore.getSrcs.collect({|port| In.kr(port.bus, port.numChannels) });
				var safeSrcs = JHOSCSrcSafe(srcs);
				var maps = JHOSCMapStore.maps.collect({
					|thisMap, i|
					var newMap = thisMap.map.(src: safeSrcs, isActive: (i - mapNumber).abs < DC.kr(0.1))
					.reject{ |m, k|
						var r = (m == JHOSCSrcSafe.errorState());
						if(r, {format("Invalid src id for key \"%\" at map index % --- key was rejected", k, i).error});
						r
					};
					defaultMap ++ newMap;
				});
				var allAddressesValid = maps.collect({
					|mapEvent, index|
					mapEvent.collect({
						|func, addr|
						if(JHOSCStore.getSinks.includesKey(addr).not, {
							format("Could not find osc address \"%\" in map index %\n", addr, index).error;
							false;
						}, { true })
					}).every{|i| i }
				}).every{|i| i };
				if(allAddressesValid, maps, nil);
			}.();

			var outs = JHOSCStore.getSinks.collect({
				|port, addr|
				var t =  oscmaps.collect{ |m| m[addr] };
				Out.kr(port.bus, LinSelectX.kr(mapNumberSmooth, t))
			});

			DebugOut.kr('map/number', 1, mapNumberSmooth);
			DebugOut.kr('active/tick', 1, activeTick);
		});
		^jhSynth
	}

}


