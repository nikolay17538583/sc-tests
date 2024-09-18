JHSynthDefStore {
	classvar store;

	*add {|name, def|
		store = store ?? {()};
		store[JHControlNameSanitiser(name.asSymbol)] = def;
	}
	*find{|name|
		^store[JHControlNameSanitiser(name.asSymbol)] ?? {format("JHSynthDefStore: could not find % in store\n", name).error};
	}
}

JHSynthDef {
	var <name, <defName, <func, <connectables;

	*new{|name, func|
		^super.newCopyArgs(name, JHControlNameSanitiser(name), func).init();
	}

	*mkSynth {
		|oscid, target, addAction, func|
		^JHSynthDef.new(oscid, func).mkSynth(oscid, target, addAction)
	}

	mkSynth {
		|oscid, target, addAction, func|
		^JHSynth(this, oscid, target, addAction);
	}

	getConnectable {|name|
		^connectables.get(name)
	}

	init {
		JHConnectableBuilder.reset();
		SynthDef(defName, func).add;
		Server.default.sync;
		connectables = JHConnectableBuilder.currentConnectables;
		JHConnectableBuilder.reset();

		JHSynthDefStore.add(name, this);

		^this;
	}
}