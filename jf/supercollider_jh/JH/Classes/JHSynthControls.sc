JHSynthControlSpec {
	var <uuid, <name, <key, <instance, <default, <spec, <>description, <value;
	*new {
		|uuid, name, key, instance, default, spec|
		^super.newCopyArgs(uuid, name, key, instance, [default].flat, if(spec.isKindOf(Symbol), {spec.asSpec}, {spec}))
	}

	set {
		|v|
		if([default].flat.size != [v].flat.size, {
			format("Not enough channels of data were supplied to set the synth control, % where given, but needed %", [v].flat.size, [default].flat.size).error;
			^this});
		value = [v].flat;
		instance.set(key, v);
		^this;
	}
	setI {
		|v, i|
		value = value ? default;
		value[i] = [v].flat;
		instance.set(key, value);
		^this;
	}
	getValue {
		^value ? default ? 0;
	}
}


JHSynthControls {
	classvar <ctls;
	classvar <loadedFile;
	*reset{ ctls = nil; ^this;}
	*initClass{
		CmdPeriod.add({ JHSynthControls.reset() });
		ServerQuit.add({ JHSynthControls.reset() });
	}
	*add {
		|uuid, name, key, instance, default, spec|
		ctls = ctls ? [];
		ctls = ctls ++ JHSynthControlSpec(uuid: uuid, name: name, key: key, instance: instance, default: default, spec: spec);
		^this;
	}
	*find{
		|uuid, key|
		^ctls.select({|c| (JHControlNameSanitiser(c.uuid) == JHControlNameSanitiser(uuid)) && (c.key == key) })[0]
	}

	*loadFrom { |file|
		try {
			var loadedState = file.parseJSONFile;
			loadedFile = file;
			loadedState.keysValuesDo{|k, v|
				var specs = ctls.select{|c|
					(c.uuid == k.asSymbol) && (c.key == v.["key"].asSymbol);
				};

				if(specs.size != 1,
					{format("could not find ctl named % with key %", k, v.["key"].asSymbol).warn}, {
						var spec = specs[0];
						var vals = v.["value"].asString.compile.();
						if(vals[0].isNil.not,
							{ spec.set(vals) });
				});
			};
		}{|...catch|
			format("Could not load file: \n \t%", catch).error;
		}

		^this
	}

	*saveTo {
		|file|
		var json = ctls.collect({ |c|
			format("\t\"%\":{"
				"\n\t\t key: \"%\","
				"\n\t\t default: %,"
				"\n\t\t value: %"
				"\n\t},",
				c.uuid, c.key, [c.default].flat, [c.value].flat)
		}).asArray.join("\n");
		json = "{\n" ++ json ++ "\n}";
		if(json.isNil,
			{format("json was nil for some reason: %",json).error; ^this;});
		File.use(file, "w", { |f| f.write(json) });
		^this;
	}
}