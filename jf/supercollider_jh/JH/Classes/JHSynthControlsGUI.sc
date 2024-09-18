JHSynthControlsGUI {
	*getView {
		var ctls = JHSynthControls.ctls ?? {()};

		var makeFaders = {
			var faders = VLayout();

			var uniqueColours = {
				var set = ctls.collect({|c| c.uuid }).asSet.asArray;
				var out = ();
				set.do{|u| out[u] = Color.rand };
				out;
			}.();


			var n = ctls.do {
				|c|
				var cur_vals = [c.getValue()].flat;

				var num = cur_vals.size;

				var min_ = cur_vals.collect({|v| if(v.abs > 0, v/20, -2) }).minItem;
				var max_ = cur_vals.collect({|v| if(v.abs > 0, v*20, 2) }).maxItem;
				var val_spec = c.spec ? ControlSpec(min(min_, max_), max(max_, min_));

				var faderParts = VLayout();
				var sliders_store = [];
				var reset_sliders = {
					|oldSpec|
					sliders_store.do{
						|s|
						s.valueAction = val_spec.unmap(oldSpec.map(s.value))
					};
				};
				num.do{|i|
					var slider_number = NumberBox();

					var slider = Slider()
					.orientation_(\horizontal)
					.maxHeight_( 80 / min(num,3) )
					.value_( val_spec.unmap(cur_vals[i]) )
					.action_({
						|n|
						var v = val_spec.map(n.value);
						c.setI(v, i);
						slider_number.value = v;
					});
					var num_layed = VLayout(
						[
							StaticText()
							.string_("Current" + if(i > 1, i.asString, "")),
							align: \bottom
						],
						[
							slider_number
							.value_(val_spec.map(slider.value)),
							align: \top
						]
					);
					sliders_store = sliders_store ++ slider;
					faderParts.add(HLayout(num_layed, slider));
				};


				faders.add(
					View()
					.background_(uniqueColours[c.uuid])
					.layout_(
						HLayout(
							VLayout(
								[
									StaticText().
									string_(c.uuid)
									.font_(Font("Josefin Sans Medium", 24)),
									s:1,
									align:\top
								],
								[
									StaticText()
									.string_(c.name)
									.font_(Font("Josefin Sans Light", 24)),
									s:99,
									align:\top
								],
								[
									StaticText()
									.string_( c.description ? "" )
									.font_(Font("Josefin Sans Light", 18)),
									s:1,
									align:\botton
								]
							),
							VLayout(
								[HLayout(
									[StaticText().string_("max"), align: \right],
									[
										NumberBox()
										.value_(val_spec.clipHi)
										.action_({|n|
											if(n.value > val_spec.map(sliders_store.collect({|s|s.value}).maxItem), {
												var old_spec = val_spec.copy;
												val_spec.maxval = n.value;
												reset_sliders.(old_spec);
											}, { n.value = val_spec.map(sliders_store.collect({|s|s.value}).maxItem) } );
										}), align: \left
									]
								), align:\top],
								[HLayout(
									[StaticText().string_("min"), align: \right],
									[
										NumberBox()
										.value_(val_spec.clipLo)
										.action_({|n|
											if(n.value < val_spec.map(sliders_store.collect({|s|s.value}).minItem), {
												var old_spec = val_spec.copy;
												val_spec.minval = n.value;
												reset_sliders.(old_spec);
											}, {n.value = val_spec.map(sliders_store.collect({|s|s.value}).minItem) });
										}),
										align: \left

									]
								), align:\bottom]

							),
							[faderParts, s:6, a:\left]
						)
					)
				)
			};
			faders;
		};


		var faders = makeFaders.();

		var window = View();

		var title = StaticText(window, Rect(0, 0, window.bounds.width, 100))
		.align_(\center)
		.string_("Controls")
		.font_(Font("Josefin Sans SemiBold", 64));


		var scroll = ScrollView(window);

		var saveLoadView = View(window, Rect(0, title.bounds.bottom, window.bounds.width, 180))
		.layout_(HLayout(
			ToolBar(
				MenuAction("Load Settings", {
					FileDialog(
						{|arr| Server.default.waitForBoot {
							JHSynthControls.loadFrom(arr[0]);
							scroll.canvas_(View().layout_(VLayout( [ makeFaders.(), s:1] )));
						}},
						{}, acceptMode: 0, path: ~pwd)
				}),
				MenuAction("Save Settings", {
					FileDialog(
						{|arr| Server.default.waitForBoot { JHSynthControls.saveTo(arr[0]) } },
						{}, acceptMode: 1, path: ~pwd)
				})
			)
		));

		scroll.bounds = Rect(0, saveLoadView.bounds.bottom,
			window.bounds.width, window.bounds.height - (title.bounds.height + saveLoadView.bounds.height));
		scroll.canvas_(View().layout_(VLayout( [ makeFaders.(), s:1] )));

		window.onResize_({
			title.bounds = Rect(0, 0, window.bounds.width, 100);
			saveLoadView.bounds = Rect(0, title.bounds.bottom, window.bounds.width, 180);
			scroll.bounds = Rect(0, saveLoadView.bounds.bottom,
				window.bounds.width, window.bounds.height - (title.bounds.height + saveLoadView.bounds.height));
		});
		^window;
	}
	*show {
		var window = Window("JH Synth Controls GUI", bounds: Rect(0,0,2000, 1200));
		window.layout_(StackLayout(this.getView()));
		window.front;
		^window;
	}
}
















