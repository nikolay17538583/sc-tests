JHConnectableUGen {
	*rd {
		|type, name, numChannels, rate|
		^JHConnectableBuilder.perform(type, name, numChannels, rate).ctl
	}
	*wr {
		|type, name, numChannels, rate, signal|
		var con = JHConnectableBuilder.perform(type, name, numChannels, rate);
		var sig = Sanitize.perform(if(rate==\audio, \ar, \kr), signal);
		if([sig].flat.size != numChannels,
			{^format("%: channel mismatch, expected % got %", name, numChannels, [sig].flat.size).error});
		if(con.ownsBus,
			{ReplaceOut.perform(if(rate==\audio, \ar, \kr), con.ctl, sig)},
			{Out.perform(if(rate==\audio, \ar, \kr), con.ctl, sig)});
		signal;
	}
}

SinkWr {
	*ar { |name, numChannels, signal|
		^JHConnectableUGen.wr(\addSinkWr, name, numChannels, \audio, signal)
	}
	*kr { |name, numChannels, signal|
		^JHConnectableUGen.wr(\addSinkWr, name, numChannels, \control, signal)
	}
}

SrcWr {
	*ar { |name, numChannels, signal|
		^JHConnectableUGen.wr(\addSrcWr, name, numChannels, \audio, signal)
	}
	*kr { |name, numChannels, signal|
		^JHConnectableUGen.wr(\addSrcWr, name, numChannels, \control, signal)
	}
}

SinkRd {
	*ar { |name, numChannels|
		^JHConnectableUGen.rd(\addSinkRd, name, numChannels, \audio)
	}
	*kr { |name, numChannels|
		^JHConnectableUGen.rd(\addSinkRd, name, numChannels, \control)
	}
}

SrcRd {
	*ar { |name, numChannels|
		^JHConnectableUGen.rd(\addSrcRd, name, numChannels, \audio) }
	*kr { |name, numChannels|
		^JHConnectableUGen.rd(\addSrcRd, name, numChannels, \control)  }
}

Setting {
	*kr {
		|name, default, spec, numChannels=1|
		^JHConnectableBuilder.addSetting(name, numChannels, spec, default).ctl.lag(0.125);
	}
}

OSCIn {
	*kr {|addrPart, numChannels, default|
		^JHConnectableBuilder.addOSCIn(addrPart, numChannels, default: default).ctl
	}
}

OSCOut {
	*kr {|addrPart, numChannels, signal|
		var sig = Sanitize.kr(signal);
		var con = JHConnectableBuilder.addOSCOut(addrPart, numChannels);
		if([sig].flat.size != numChannels,
			{^format("%, channel mismatch, expected % got %", name, numChannels, [sig].flat.size).error});
		ReplaceOut.kr(con.ctl, sig);
		signal;
	}
}

DebugOut {
	classvar <>enable = false;
	*kr {|addrPart, numChannels, signal|
		^if(DebugOut.enable,{
			var sig = Sanitize.kr(signal);
			var con = JHConnectableBuilder.addDebug(addrPart, numChannels);
			if([sig].flat.size != numChannels,
				{^format("%, channel mismatch, expected % got %",
					name, numChannels, [sig].flat.size).error});
			ReplaceOut.kr(con.ctl, sig);
			signal
		});
	}
}