PRProjectTarget {
	var <tname, <depends, <function, <isPreBoot;
	*new {|n, d, f, b|
		^super.newCopyArgs(n, d ?? {[]}, f.isKindOf(Function).if({f}, { {f} }), b)
	}

	value {
		postf("** Launching target - % **\n", tname);
		^if (function.def.argNames.size == 1,
			{ this.prValueSync.() },
			{ function.() }
		)
	}

	prValueSync {
		var c = CondVar();
		var ret;
		try { fork{ ret = function.(c)} } { c.signalAll };
		c.wait;
		^ret;
	}
}


Project {
	var targets;
	var endPoints;
	*new { ^super.newCopyArgs(()) }
	addPreBootTarget { |name, depends, func|
		var d = [ depends ?? {[]} ].flat;
		this.prvalidateDepends(d);
		this.prvalidateDepsArePreBoot(name, d);
		targets[name] = PRProjectTarget(name, d, func, true);
		^this;
	}
	addTarget { |name, depends, func|
		var d = [ depends ?? {[]} ].flat;
		this.prvalidateDepends(d);
		targets[name] = PRProjectTarget(name, d, func, false);
		^this;
	}
	run { |name, server|
		this.prvalidateTarget(name);
		this.prRun(name, server ? Server.default)
	}

	defineEndPoints { |...list|
		list.do{|l| this.prvalidateTarget(l) };
		endPoints = list;
		^this;
	}

	mkGUI {
		|parent|
		var title = StaticText()
		.align_(\center)
		.string_("Lauch Piece With Target")
		.font_(Font(Font.defaultSansFace, 64, true));
		var ends = endPoints.collect({|v, k|
			MenuAction(v, { this.run(v) }).font_(Font(Font.defaultSansFace, 24));
		});
		var toolBar = ToolBar(*ends.asArray);
		var v = View(parent).layout_(VLayout(
			[title, s: 1, a: \top],
			[toolBar, s:99, a: \top]
		));
		v.resizeToHint(toolBar.sizeHint);
		^v
	}
	showGUI { ^this.mkGUI().front() }



	prRun { |name, server|
		var launched = Set();
		var preBootList = [];
		var postBootList = [];
		var bootCond = CondVar();

		var addDepsFirst = { |n|
			targets[n].depends.do{|d| addDepsFirst.(d) }; // reccursion
			if (launched.includes(n).not, {
				targets[n].isPreBoot.if(
					{ preBootList  = preBootList  ++ [targets[n]] },
					{ postBootList = postBootList ++ [targets[n]] }
				);
				launched.add(n)
			})
		};

		var actualFunction = {
			preBootList.do( _.value() );

			postf("** Launching target - Boot Server **\n");

			server.waitForBoot {
				postBootList.do { |t| t.(); server.sync; };
				bootCond.signalAll;
			};
		};

		// build dependants tree and try to evalute them in order.

		addDepsFirst.(name);

		fork {
			try { actualFunction.()	} { bootCond.signalAll };
			bootCond.wait;
			postf("|====> ** Finished launching endpoint: % **\n", name);
		}
	}


	prvalidateDepends {|d|
		d.do{ |dep|
			targets.includesKey(dep).not.if({format("dependent (%) cannot be found", dep).throw})
		}
	}
	prvalidateTarget {|n| targets[n].isNil.if({"target does not exist".throw}) }
	prvalidateDepsArePreBoot {|name, d|
		d.do{ |dep|
			targets[dep].isPreBoot.not.if(
				{format("the pre boot target (%) cannot have post boot targets - %", name, dep).throw}
			)
		}
	}

}






