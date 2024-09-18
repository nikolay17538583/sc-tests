JHOSCGUI {
	*getView {
		var window = View();
		var update_funcs = [];
		var updater = Routine({
			loop { update_funcs.do{|f| f.() }; (1/35).wait; }
		});
		var title = StaticText(window, Rect(0, 0, window.bounds.width, 100))
		.align_(\center) .string_("OSC") .font_(Font("Josefin Sans SemiBold", 64));

		var stack = StackLayout();

		var switch = View(window, Rect(0, title.bounds.bottom, window.bounds.width, 100)).layout_(HLayout(
			ToolBar(
				MenuAction("Internal Sinks", { stack.index = 0 }),
				MenuAction("External Sinks", { stack.index = 1 }),
				MenuAction("Internal Sources", { stack.index = 2 }),
				MenuAction("External Sources", { stack.index = 3 })
			)
		));

		var mainArea = View(window, Rect(
			0, 200,
			window.bounds.width, window.bounds.height - (200)
		));

		var get_base_addr = {
			|addr|
			addr.asString.split($/)[1].asSymbol
		};
		var allUnique = JHOSCStore.getAll()
		.collect({ |port| get_base_addr.(port.address) }).asArray.asSet.asArray;
		var colours = allUnique.collect({|b| var o = ()[b] = Color.rand; o }).reduce({|l, r| l ++ r });

		var mk_gui = {
			|port|
			var sliders = port.numChannels.collect{
				|n|
				var slid = Slider()
				.orientation_(\horizontal)
				.maxHeight_( 100 / min(port.numChannels, 3) )
				.value_( port.bus.getnSynchronous(port.numChannels)[n] )
				.action_({ |slid| port.bus.setAt(n, slid.value) });

				update_funcs = update_funcs ++ {
					slid.value_(port.bus.getnSynchronous(port.numChannels)[n])
				};
				slid
			};
			var thisColour = colours[get_base_addr.(port.address)];
			View().background_( thisColour )
			.layout_(
				HLayout(
					[StaticText().string_(port.address).font_(Font("Josefin Sans Medium", 24)), s:1, align:\left],
					[VLayout( *sliders ), s:9]
				)
			)
		};

		var scrollViews = [
			[JHOSCStore.sinkInternal, "Internal Sinks"], [JHOSCStore.sinkExternal, "External Sinks"],
			[JHOSCStore.srcInternal, "Internal Sources"], [JHOSCStore.srcExternal, "External Sources"]
		].collect{
			|store|
			var viewOut = View(mainArea);
			var scroll = ScrollView(viewOut, bounds: viewOut.bounds)
			.canvas_( View().layout_(
				VLayout(
					[StaticText().string_(store[1]).font_(Font("Josefin Sans Medium", 24)), s:1, align:\top],
					[VLayout( *store[0].asArray.sort({|l, r| l.address < r.address })
						.collect({|p| mk_gui.(p) }).asArray ), s:99, align:\top]
				)
			));

			viewOut.onResize_({ scroll.bounds = viewOut.bounds });
			viewOut;
		};
		scrollViews.do{|v| stack.add(v)};
		mainArea.layout_(stack);

		window.onResize_({
			title.bounds = Rect(0, 0, window.bounds.width, 100);
			switch.bounds = Rect(0, 100, window.bounds.width, 100);
			mainArea.bounds = Rect(
				0, 200, window.bounds.width,
				window.bounds.height - (200)
			);
		});
		updater.play(AppClock);
		window.onClose_({ updater.stop });

		^window;
	}
	*show {
		var window = Window("JH OSC GUI", bounds: Rect(0, 0, 2000, 1200));
		window.layout_(StackLayout(this.getView()));
		window.front;
	}
}

