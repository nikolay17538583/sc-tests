JHConnectable {
	var <>name, <>controlName, <>ctl, <>numChannels, <>rate, <>type, <>dir, <>ownsBus, <>spec, <>default;
	*new {
		|name, numChannels, rate, type, dir, ownsBus, spec, default|
		var def = default !?
		{ if([default].flat.size == numChannels, default, [default].flat[0]!numChannels) } ??
		{ if(dir == \out, {0}, {0!numChannels}) };
		^super.newCopyArgs(
			name,
			JHControlNameSanitiser(name),
			if(rate == \audio,
				{NamedControl.ar(JHControlNameSanitiser(name), def)},
				{NamedControl.kr(JHControlNameSanitiser(name), def)}),
			numChannels,
			rate,
			type,
			dir,
			ownsBus,
			spec,
			def
		)
	}

}

JHConnectableStore {
	var <>sinkWrs, <>sinkRds, <>srcWrs, <>srcRds;
	var <>oscIn, <>oscOut;
	var <>settings;
	var <>debugcons;
	*new { ^super.newCopyArgs((), (), (), (), (), (), (), ())  }

	mkBusMap {
		^this.getAll()
		.select({|e| e.ownsBus })
		.collect({
			|e|
			var b = Bus.perform(e.rate, Server.default, e.numChannels);
			Server.default.sync;
			if(e.rate == \control,  {e.default !? { b.setn([e.default].flat) } });
			(\control: e, \bus: b)
		})
	}
	getAll { ^sinkWrs ++ sinkRds ++ srcWrs ++ srcRds ++ oscIn ++ oscOut ++ settings ++ debugcons }
	get { |n| ^this.getAll()[n] }
	getNonOwningOutputs {
		^this.getAll().select({|e| e.ownsBus.not && (e.dir == \out) }) }
	getNonOwningInputs {
		^this.getAll().select({|e| e.ownsBus.not && (e.dir == \in) }) }
	getOSC { ^oscIn ++ oscOut }
}

JHConnectableBuilder {
	classvar <>currentConnectables;
	*reset {
		currentConnectables = JHConnectableStore()
	}
	*prAddCol {
		|col, name, thing|
		currentConnectables.perform(col)[name] = thing;
		^thing;
	}
	*addSrcRd {|name, numChannels, rate, spec, default|
		^JHConnectableBuilder.prAddCol(\srcRds, name,
			JHConnectable(name, numChannels, rate, \src, \in, false, spec, default))
	}
	*addSrcWr {|name, numChannels, rate, spec, default|
		^JHConnectableBuilder.prAddCol(\srcWrs, name,
			JHConnectable(name, numChannels, rate, \src, \out, true, spec, default))
	}
	*addSinkRd {|name, numChannels, rate, spec, default|
		^JHConnectableBuilder.prAddCol(\sinkRds, name,
			JHConnectable(name, numChannels, rate, \sink, \in, true, spec, default))
	}
	*addSinkWr {|name, numChannels, rate, spec, default|
		^JHConnectableBuilder.prAddCol(\sinkWrs, name,
			JHConnectable(name, numChannels, rate, \sink, \out, false, spec, default))
	}
	*addOSCIn {|name, numChannels, spec, default|
		^JHConnectableBuilder.prAddCol(\oscIn, name,
			JHConnectable(name, numChannels, \control, \osc, \in, false, spec, default))
	}
	*addOSCOut {|name, numChannels, spec, default|
		^JHConnectableBuilder.prAddCol(\oscOut, name,
			JHConnectable(name, numChannels, \control, \osc, \out, false, spec, default))
	}
	*addSetting {|name, numChannels, spec, default|
		^JHConnectableBuilder.prAddCol(\settings, name,
			JHConnectable(name, numChannels, \control, \setting, \in, false, spec, default))
	}
	*addDebug {|name, numChannels, spec, default|
		^JHConnectableBuilder.prAddCol(\debugcons, name,
			JHConnectable(name, numChannels, \control, \debug, \out, true, spec, default))
	}
}