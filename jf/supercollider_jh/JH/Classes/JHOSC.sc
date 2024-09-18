JHOSCPort {
	var <>address, <>numChannels, <>bus, <>default;

	*new {|address, numChannels, default|
		^super.new.init(address, numChannels, default)
	}
	init {
		|address, numChannels, default|
		this.prInit(address, numChannels, default);
		^this;
	}
	prInit {
		|a, n, d|
		address = a;
		numChannels = n ? 1;
		default = [(d ? 0)].flat;
		default = if(default.size == numChannels, default, default[0]!numChannels);
		bus = Bus.control(Server.default, numChannels);
		Server.default.sync;
		bus.setn( default );
		^this;
	}
	free {
		bus.free;
	}
}

//

JHOSCSinkBase : JHOSCPort {}
JHOSCSrcBase : JHOSCPort {}

//


JHOSCSinkInternal : JHOSCSinkBase {}
JHOSCSrcInternal : JHOSCSrcBase {}

JHOSCSinkExternal : JHOSCSinkBase {
	var <relayAddress, <osc;
	*new {|address, numChannels, default, netAddr|
		^super.new.init(address, numChannels, default, netAddr)
	}
	init {
		|ad, n, d, net|
		super.init(ad, n, d);
		relayAddress = (ad.asString ++ '/relay').asSymbol;
		osc = OSCFunc({ |msg|
			var o = msg[3..];
			net.sendMsg(address, *o)
		}, relayAddress);
		^this;
	}
	kr {
		|trig, vals|
		^SendReply.kr(trig, relayAddress, vals)
	}
	free {
		super.free();
		osc.remove;
	}
}

JHOSCSrcExternal : JHOSCSrcBase {
	var <osc;
	*new {|address, numChannels, default, netAddr|
		^super.new.initsrc(ad: address, n: numChannels, d: default, net: netAddr)
	}
	initsrc {
		|ad, n, d, net|
		super.init(ad, n, d);
		osc = OSCFunc.newMatching({ |msg...o|
			bus.setn(msg[1..])
		}, address);
		^this;
	}
	free {
		super.free();
		osc.remove;
	}
}


JHOSCStore {
	classvar <sinkInternal, <sinkExternal, <srcInternal, <srcExternal;
	classvar relaySynth;
	*reset {
		sinkInternal = ();
		sinkExternal = ();
		srcInternal = ();
		srcExternal = ();
		try{relaySynth.free}{};
		relaySynth = nil;
	}
	*initClass {
		CmdPeriod.add({ JHOSCStore.reset() });
		ServerQuit.add({ JHOSCStore.reset() });
		//JHSynthControls.reset()
	}

	*addrAlreadyExists{|add|
		sinkInternal = sinkInternal ? ();
		sinkExternal = sinkExternal ? ();
		srcInternal = srcInternal ? ();
		srcExternal = srcExternal ? ();

		^sinkInternal.includesKey(add)  || sinkExternal.includesKey(add)
		|| srcInternal.includesKey(add) || srcExternal.includesKey(add);
	}
	*get{
		|add|
		if(sinkInternal.includesKey(add), {^sinkInternal[add]});
		if(sinkExternal.includesKey(add), {^sinkExternal[add]});
		if(srcInternal.includesKey(add), {^srcInternal[add]});
		if(srcExternal.includesKey(add), {^srcExternal[add]});
		^nil;
	}

	*getSinks { ^sinkInternal ++ sinkExternal }
	*getSrcs { ^srcInternal ++ srcExternal }
	*getAll { ^sinkInternal ++ sinkExternal ++ srcInternal ++ srcExternal }


	*createRelaySynth {
		|group, triggerRate|
		this.prCreateRelaySynth(group, triggerRate);
		^this;
	}
	*prCreateRelaySynth {
		|group, triggerRate|
		var g = group ?? {JHActiveGroup.get()};
		Server.default.sync;
		relaySynth = SynthDef(\OSCRelaySynth, {
			var trig = Impulse.kr(triggerRate ? 60);
			var ins = sinkExternal.collect({|e|
				(
					\addr: e.address,
					\val: NamedControl.kr(JHControlNameSanitiser(e.relayAddress), e.default)
				);
			});
			var send_replies = ins.collect{ |e|
				sinkExternal[e.addr].kr(trig, e.val);
			};
		}).play(target: g);

		Server.default.sync;

		sinkExternal.do{|e|
			relaySynth.map(JHControlNameSanitiser(e.relayAddress), e.bus);
		};
	}

	*triggerRate {
		|r|
		relaySynth.set(\triggerRate, r);
	}


	*mkSinkInternal {
		|address, numChannels, default|
		if(this.addrAlreadyExists(address), {"Address already exists".error; ^this});

		sinkInternal[address] = JHOSCSinkInternal(address, numChannels, default);
		^sinkInternal[address]
	}

	*mkSrcInternal {
		|address, numChannels, default|
		if(this.addrAlreadyExists(address), {"Address already exists".error; ^this});

		srcInternal[address] = JHOSCSrcInternal(address, numChannels, default);
		^srcInternal[address]
	}


	*mkSinkExternal {
		|address, numChannels, default, netAddr|
		if(this.addrAlreadyExists(address), {"Address already exists".error; ^this});

		sinkExternal[address] = JHOSCSinkExternal(address, numChannels, default, netAddr);
		^sinkExternal[address]
	}

	*mkSrcExternal {
		|address, numChannels, default, netAddr|
		if(this.addrAlreadyExists(address), {"Address already exists".error; ^this});

		srcExternal[address] = JHOSCSrcExternal(address, numChannels, default, netAddr);
		^srcExternal[address]
	}

}






















