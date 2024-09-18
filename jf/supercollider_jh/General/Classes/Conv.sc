Conv {
	var <ir;
	var <fftSize;
	var <numChannels;
	*new{
		|path, fft_size=4096|
		^super.new.init(path, fft_size);
	}
	init {
		|path, fft_size|
		this.prInit(path, fft_size);
		^this;
	}
	prInit{
		|path, fft_size|
		var s = Server.default;
		var sync = { |f| var r = f.(); s.sync; r };
		var channel_count = {
			var audio_temp = sync.({Buffer.read(s, path)});
			var c = audio_temp.numChannels;
			audio_temp.free;
			c
		}.();
		var ir_files = sync.({
			channel_count.collect{|n| Buffer.readChannel(s, path, channels:[n]) }
		});
		var size = sync.({
			PartConv.calcBufSize(fft_size, ir_files[0])
		});
		var ir_bufs = sync.({ channel_count.collect{|n| Buffer.alloc(s, size, 1)} });

		ir = sync.({
			ir_bufs.collect{|buf, n| buf.preparePartConv(ir_files[n], fft_size)}
		});

		ir_files.do{|f| f.free };

		fftSize = fft_size;
		numChannels = channel_count;
		^this;
	}
	err {
		|signal|
		"Conv:".error;
		format("\tInput signal (%) with % channels, ", signal, if(signal.size() == 0 , 1, signal.size())).error;
		"\tmust have the same number of channels as the impulse responses, ".error;
		format("\twhich is %.", numChannels).error;
	}

	ar {
		|signal|
		if(numChannels < signal.size(), {
			this.err(signal);
			^Silent.ar(signal.size)
		}, {
			^[signal, ir].flop.collect({|d|
				PartConv.ar(d[0], fftSize, d[1])
			})
		})
	}
}