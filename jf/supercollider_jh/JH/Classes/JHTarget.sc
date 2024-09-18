JHSubTargetPart {
	var <dependents, <function;
	*new {|dependents, function| ^super.newCopyArgs(dependents, function) }
}

JHSubTargets {
	var <subTargets;
	*new { ^super.newCopyArgs(()) }

	add { |name, deps, func |
		subTargets = subTargets ?? {()};
		subTargets[name] = JHSubTargetPart(deps ?? {[]}, func);
		^this;
	}
	at {|n|
		^subTargets[n];
	}
}


JHLauncher {
	var targets, subTargets, activeTarget;
	*new {|subtargets| ^super.newCopyArgs((), subtargets) }

	addTarget { |name, dependentArray|
		targets = targets ?? {()};
		targets[name] = dependentArray ?? {[]};
		^this
	}

	launchTarget {
		|name|
		var asdf = "starting launch".warn;
		var launched = Set();
		var numIndent = 0;
		var launchDependantsFirst = {|k|
			numIndent = numIndent + 3;
			format((" "!numIndent).join + "begin loading: %", k).warn;
			if(subTargets.subTargets.includesKey(k).not,
				{format("Subtarget % does not exist in subtargets, typo?", k).error});
			launched = launched.add(k);
			subTargets[k].dependents.do({ |dk|
				if (launched.includes(dk).not, {launchDependantsFirst.(dk)});
			});
			format((" "!numIndent).join + "load: %", k).warn;
			Server.default.sync;
			subTargets[k].function.();
			Server.default.sync;
			numIndent = numIndent - 3;
		};

		Server.default.waitForBoot {
			Server.default.sync;
			targets[name].collect{ |targetDependentKey|
				Server.default.sync;
				launchDependantsFirst.(targetDependentKey)
			};
			Server.default.sync;
			format("Done loading target: %", name).warn;
		}
	}

	reset {
		"RESETTING SUPERCOLLIDER".warn;
		thisProcess.recompile;
	}


	mkGUI {
		var w = Window("Jellyfish Launcher", bounds: Rect(0, 0, 2000, 1200));

		var mainStackLayout = StackLayout();

		var targetsTitle = StaticText().align_(\center)
		.string_("Tagets").font_(Font("Josefin Sans SemiBold", 64));

		var elapsed_time = 0;
		var update_on_timer_refresh = FunctionList();
		var timer = Routine({
			loop {
				elapsed_time = elapsed_time + 1;
				update_on_timer_refresh.();
				1.wait;
			}
		});

		var ts = targets.collect({|d, n|
			MenuAction(
				(" "!4).join + n + (" "!4).join,
				{
					this.launchTarget(n);
					mainStackLayout.index = 1;
					timer.play();
				}
			).font_(Font("Josefin Sans SemiBold", 24))
		}).asArray;

		var targetsPage = View().layout_(VLayout(
			[targetsTitle, s:1, a:\top],
			[ToolBar( *ts ), s:99, a:\top]
		));

		var serverMonitorPage = {
			if(Server.default.hasBooted.not,
				{View().layout_(HLayout(StaticText().string_("..waiting for server to boot...").align_(\center)))},
				{View().layout_(VLayout(
					{
						var timer_text = StaticText()
						.string_("Time Elapsed: " + elapsed_time.asString)
						.font_(Font("Josefin Sans SemiBold", 24));
						update_on_timer_refresh.addFunc({
							{ timer_text.string_("Time Elapsed: " + elapsed_time.asString) }.defer
						});
						[timer_text, s: 1];

					}.(),
					{
						var sc = ScrollView();
						var canvas = View().minSize_(Size(400, 300 + JHSynthStore.numNodes * 50));
						Server.default.plotTreeView(parent: canvas);
						sc.canvas = canvas;
						[sc, s: 4];
					}.(),
					{
						var sc = ScrollView();
						var canvas = View().minSize_(Size(ServerMeterView.getWidth(
							Server.default.options.numInputBusChannels,
							Server.default.options.numOutputBusChannels
						), ServerMeterView.height));
						ServerMeterView(Server.default,
							parent: canvas,
							numIns: Server.default.options.numInputBusChannels,
							numOuts: Server.default.options.numOutputBusChannels);
						sc.canvas = canvas;
						[sc, s: 2];
					}.()


				))
			})
		};

		var loadableView = serverMonitorPage.();
		var monitorStack = StackLayout( loadableView );
		var activePage = \serverMonitor;
		var monitorPage = View().layout_(VLayout(
			[ToolBar(
				MenuAction("Server Monitor", {
					activePage = \serverMonitor;
					loadableView.remove();
					loadableView = serverMonitorPage.();
					monitorStack.add( loadableView );
					monitorStack.index = 0;
				}),
				MenuAction("OSC Browser", {
					activePage = \oscBrowser;
					loadableView.remove();
					loadableView = JHOSCGUI.getView();
					monitorStack.add( loadableView );
					monitorStack.index = 0;
				}),
				MenuAction("Synth Control Browser", {
					activePage = \SynthControlBrowser;
					loadableView.remove();
					loadableView = JHSynthControlsGUI.getView();
					monitorStack.add( loadableView );
					monitorStack.index = 0;
				})
			), s:1, a:\top],
			[monitorStack, s:99]
		));
		ServerBoot.add({
			if(activePage == \serverMonitor, {
				loadableView.remove();
				loadableView = serverMonitorPage.();
				monitorStack.add( loadableView );
				monitorStack.index = 0;
			});
		});

		mainStackLayout.add( targetsPage );

		mainStackLayout.add( monitorPage );

		mainStackLayout.index = if(Server.default.hasBooted, 1, 0);
		w.layout_( mainStackLayout );
		w.addToOnClose({
			timer.stop;
		});
		w.front;
	}
}





























