
JHGroup().withGroup {
	JHSynthDef.mkSynth(oscid: 'in/mic', func: {
		var in = SoundIn.ar([0, 1])
		* Env([0,0,1], 2, 1).ar(0, 1)
		* Setting.kr('Gains', 0, \db, 2).dbamp.sanitize;

		var inputSignal = in
		|> OnePole.ar(_, Setting.kr('One Pole', 0.99, \onepole, 2).clip(0, 0.99999999))
		|> BLowPass.ar(_, Setting.kr('LPF', 15000, \freq, 2))
		|> BHiPass4.ar(_, Setting.kr('HPF', 35, \freq, 2))
		|> (_.flat) |> Mix.ar(_); // make mono

		OSCOut.kr('onset', 1, Coyote.kr(inputSignal));
		SrcWr.ar('out/mono', 1, inputSignal);
		JHSynthMixin(\AnalysisMixin, in[0].blend(in[1], Setting.kr('Analysis Blend', 0.5, \unipolar)) );
	});

	// play, wait, anxious wait, trigger / reset
	JHSynthDef.mkSynth(oscid: 'syncron', func: {

		var l = LocalIn.kr(2, 0);
		var previous_section = l[0];
		var previous_value = l[1];
		var raw_time_pr = Sweep.kr(Changed.kr(previous_section));

		var wait_time = OSCIn.kr('waitTime', 1, 0.5).linlin(0, 1, 4, 30);
		var anx_time = OSCIn.kr('anxTime', 1, 0.5).linlin(0, 1, 1, 10);
		var hold_time = OSCIn.kr('holdTime', 1, 0.1).linlin(0, 1, 2, 20);
		var t_pulse = 0.1;

		var cue = OSCIn.kr('visualCue', 1, 0) > 0.5;
		var should_advance = Select.kr(previous_section, [
			(raw_time_pr > hold_time),
			(raw_time_pr > wait_time) + (cue *2),
			(raw_time_pr > anx_time) + cue,
			(raw_time_pr > t_pulse)
		]);

		var current_section = (previous_section + should_advance);
		var current_section_time = Select.kr(current_section,
			[hold_time, wait_time, anx_time, t_pulse]);

		var time_in_section = Sweep.kr(Changed.kr(current_section));

		var lerp = (time_in_section / current_section_time).clip(0, 1);
		var index = current_section + lerp;
		var value = index / 3;
		var got_a_trigger = Trig.kr((current_section > 2.9) - 0.2, 0.2);

		//Demand.kr(got_a_trigger, 0, Dpoll(1, 'Got a proper trigger'));
		LocalOut.kr([current_section % 3, value]);

		OSCOut.kr('trigger', 1, got_a_trigger);
		OSCOut.kr('state', 1, value);
	});

}
