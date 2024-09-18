JHImitator {
	*ar { |spec, in| ^spec.(\ar, in)}
	*kr { |spec, in| ^spec.(\kr, in)}
}


JHImDerivative {
	var sz, buffer;

	*new { |bufferSize| ^super.newCopyArgs(bufferSize, Buffer.alloc(Server.default, bufferSize)) }

	value { |rate, in|
		var numFrames = sz;
		var rate_scale = BufRateScale.ir(buffer);
		var dif = {|i| i - Delay1.perform(rate, i) };
		var d_in = dif.(in);

		var wr_phase_rate = Phasor.perform(rate, 0, rate_scale, 0, numFrames);
		var wr = BufWr.perform(rate, d_in, buffer, wr_phase_rate);

		var rd_phase = {
			var wobble = LFNoise2.perform(rate, 0.01).range(0.92, 1.08);
			var lerp = (numFrames * [0, 1/3, 2/3]);
			var base = (wr_phase_rate * wobble);
			base + lerp |> _.wrap(0, numFrames)
		}.();

		var deltas = BufRd.perform(rate, 1, buffer, rd_phase);
		var delta_lerp = LFNoise2.perform(rate, 0.2).range(0, deltas.size);
		var delta = SelectX.perform(rate, delta_lerp, deltas);
		var est = Integrator.perform(rate, delta).fold(0, 1);
		^est.sanitize
	}
}


JHImAmplitude {
	var sz, env_buf, time_buf;

	*new { |numberOfSamples|
		^super.newCopyArgs(
			numberOfSamples,
			Buffer.alloc(Server.default, numberOfSamples),
			Buffer.alloc(Server.default, numberOfSamples)
		)
	}

	value { |rate, in|

		var dif = {|i| i - Delay1.perform(rate, i) };
		var d_in = dif.(in);

		var new_atk = Changed.perform(rate, d_in > 0);

		var amp_at_atk = Latch.perform(rate, in, new_atk);
		var time_between_atks = Phasor.perform(rate, new_atk, ControlRate.ir().reciprocal, 0, inf);

		var wr = { |data, buf|
			var dwr = Dbufwr(_, buf, Dseries(0, 1, sz)) <| Delay1.perform(rate, data);
			Demand.perform(rate, new_atk, 0, dwr)
		};
		var wr_amp = wr.(amp_at_atk, env_buf);
		var wr_time = wr.(time_between_atks, time_buf);

		var t = LocalIn.perform(rate, 1) + Impulse.perform(rate, 0);
		var rd = Demand.perform(rate, t, 0, Dbufrd([env_buf, time_buf], Dwhite(0, sz)));

		var n_amp = rd[0];
		var n_time = rd[1];

		var counter = Phasor.perform(rate, t, ControlRate.ir().reciprocal, 0, n_time);
		var trig = LocalOut.perform(rate, Slope.perform(rate, counter) < 0);

		var env = counter.linlin(0, n_time, 0, 2).fold(0, 1) * n_amp;
		^env.sanitize
	}
}


