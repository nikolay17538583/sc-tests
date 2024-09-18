JHSynthMixinDef {
	var <inputArray, <func;
	*new {|name, func|
		^super.newCopyArgs(func.def.argNames, func).register(name);
	}
	register {
		|name|
		JHSynthMixin.register(name, this);
	}
}

JHSynthMixin {
	classvar store;
	*register {
		|name, m|
		store = store ?? {()};
		store[name] = m;
	}
	*new{
		|name ... args|
		^SynthDef.wrap(store[name].func, prependArgs: args )
	}
}