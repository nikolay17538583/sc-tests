JHSynthMixinDef(\AnalysisMixin, {
	|input|
	var in = Mix.ar([input].flat); // check mono!
	var amp = Amplitude.kr(in, 0.05, 0.1);
	var specShape = FluidSpectralShape.kr(in,
		select: [\centroid, \skewness],
		minFreq: 100,
		windowSize: 2048
	);

	var noiseFloor = Setting.kr('Noise Floor', -40, \db).dbamp.sanitize;
	var get_amp = { |i| Amplitude.kr(i, 0.2, 0.3)  |> (_.lincurve(noiseFloor, 1, 0, 1, -6)) };
	var latcher = Latch.kr(_, amp > noiseFloor);

	var centroidRange = Setting.kr('Centroid Range', [200, 15000], \freq, numChannels:2);

	var centroid = specShape[0].lincurve(centroidRange[0], centroidRange[1], 0, 1, 3)
	|> latcher.(_)
	|> Median.kr(10, _);

	var skewnessRange = Setting.kr('Skewness Range', [0.2, 16], numChannels:2);
	var skewness = specShape[1].lincurve(skewnessRange[0], skewnessRange[1], 0, 1, -1) |> latcher.(_);

	var skew_std = (FluidStats.kr(skewness, 20)[1] * 3).clip(0, 1);

	OSCOut.kr('/analysis/centroid', 1, centroid);
	OSCOut.kr('/analysis/skewness', 1, skewness |> Median.kr(10, _));
	OSCOut.kr('/analysis/skew/std', 1, skew_std.clip(0, 1));

	in |> get_amp |> OSCOut.kr('/analysis/amplitude', 1, _);
	in |> LPF.ar(_, 300) |> get_amp |> OSCOut.kr('/analysis/amplitude/low', 1, _);

	input
});

JHSynthMixinDef(\AnalysisAmp, {|input|
	var noiseFloor = Setting.kr('Noise Floor', -35, \db).dbamp.sanitize;
	var get_amp = { |i| Amplitude.kr(i, 0.2, 0.3)  |> (_.lincurve(noiseFloor, 1, 0, 1, -6)) };
	var in = Mix.ar([input].flat);

	in |> get_amp |> OSCOut.kr('/analysis/amplitude', 1, _);
	in |> LPF.ar(_, 300) |> get_amp |> OSCOut.kr('/analysis/amplitude/low', 1, _);

	input
});

