JHSynthStore {
	classvar store;
	*add {|oscid, synth|
		store = store ?? {()};
		store[oscid] = synth;
	}
	*find{|name|
		^store[name.asSymbol] ?? {format("JHSynthStore: could not find % in store %", name, store).error};
	}
	*numNodes {
		store = store ?? {()};
		^store.size()
	}
}

JHSynth {
	classvar <defaultbusInAr, <defaultbusOutAr, <defaultbusInKr, <defaultbusOutKr;
	var <jhSynthDef, <oscid, <node, <busMap;

	*initClass {
		ServerBoot.add({JHSynth.initBuffs})
	}
	*initBuffs {
		fork {
			defaultbusInAr = Bus.audio(Server.default, 10);
			defaultbusOutAr = Bus.audio(Server.default, 10);
			defaultbusInKr = Bus.control(Server.default, 10);
			defaultbusOutKr = Bus.control(Server.default, 10);
		}
	}
	*find {|t| ^JHSynthStore.find(t) }
	*unwrapArrayAsGet{|e| ^JHSynth.find(e[0]).getController(e[1]) }

	*new {
		|jhSynthDef, oscid, target, addAction|
		^super.newCopyArgs(
			if(jhSynthDef.isKindOf(Symbol),
				{JHSynthDefStore.find(jhSynthDef)},
				{jhSynthDef}
			),
			oscid
		).init(target, addAction)
	}
	free {
		node.free;
		busMap.do{ |b| b.bus.free };
	}

	init {
		|target, addAction|
		Server.default.sync;

		node = Synth(jhSynthDef.defName,
			target: target ?? {JHActiveGroup.get()},
			addAction: addAction ? 'addToTail'
		);

		Server.default.sync;

		busMap = jhSynthDef.connectables.mkBusMap();

		Server.default.sync;

		// set all connectables that own a bus, to said bus
		busMap.do{ |b|
			if(b.control.dir == \in,
				{node.map(b.control.controlName, b.bus)},
				{node.set(b.control.controlName, b.bus)})
		};

		Server.default.sync;

		// set all inputs and outputs, that don't own a bus to a default bus
		jhSynthDef.connectables.getNonOwningOutputs().do{ |c|
			node.set(c.controlName,
				if(c.rate == \audio, defaultbusOutAr, defaultbusOutKr))
		};
		jhSynthDef.connectables.getNonOwningInputs().do{ |c|
			node.map(c.controlName,
				if(c.rate == \audio, defaultbusInAr, defaultbusInKr))
		};

		// make OSC busses and connect
		jhSynthDef.connectables.oscIn.do{ |c|
			node.map(
				c.controlName,
				JHOSCStore.mkSinkInternal(
					(oscid.asString +/+ c.name.asString).asSymbol,
					c.numChannels, c.default
				).bus
			);
		};
		jhSynthDef.connectables.oscOut.do{ |c|
			node.set(
				c.controlName,
				JHOSCStore.mkSrcInternal(
					(oscid.asString +/+ c.name.asString).asSymbol,
					c.numChannels, c.default
				).bus
			);
		};


		// register setttings
		jhSynthDef.connectables.settings.do{|c|
			JHSynthControls.add(uuid: oscid,
				name: c.name, key: c.controlName,
				instance: this.node, default: c.default,
				spec: c.spec)
		};

		JHSynthStore.add(oscid, this);

		Server.default.sync;

		^this;
	}


	getController{ |name|
		if (busMap.includesKey(name),
			{^(\jhsynth: this, \busMap: busMap[name])},
			{^(\jhsynth: this, \controller: jhSynthDef.getConnectable(name))});
	}
	getIn  { |name| ^this.getController(name) }
	getOut { |name|	^this.getController(name) }
	asTarget { ^node.asTarget }

	connect {
		|parent, child|
		if(parent.isKindOf(Function),
			{^this.connect(parent.(this), child)});
		if(child.isKindOf(Function),
			{^this.connect(parent, child.(this))});

		if(parent.isKindOf(Array),
			{^this.connect(JHSynth.unwrapArrayAsGet(parent), child)});
		if(child.isKindOf(Array),
			{^this.connect(parent, JHSynth.unwrapArrayAsGet(child))});

		if(parent.includesKey(\busMap),
			{child.jhsynth.node.map(
				child[\controller].controlName, parent[\busMap].bus)},
			{parent.jhsynth.node.set(
				parent[\controller].controlName, child[\busMap].bus)});
		^this
	}
}