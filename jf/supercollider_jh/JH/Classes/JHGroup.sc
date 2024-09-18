JHActiveGroup {
	classvar activeGroup;
	*get {
		activeGroup = activeGroup ?? {List()};
		Server.default.sync;
		^activeGroup.last ?? {Server.default.defaultGroup}
	}
	*push { |g|
		Server.default.sync;
		activeGroup = activeGroup.add(g)
	}
	*pop {
		Server.default.sync;
		activeGroup.pop()
	}
}

JHGroup {
	var <node;
	*new { |target, addAction='addToTail'| ^super.new.init(target, addAction) }
	asTarget { ^node.asTarget }
	init {
		|target, addAction|
		Server.default.sync;
		node = Group(target ?? {JHActiveGroup.get()}, addAction);
		Server.default.sync;
		^this;
	}
	withGroup {
		|func|
		JHActiveGroup.push(node);
		Server.default.sync;
		func.();
		Server.default.sync;
		JHActiveGroup.pop();
		^this;
	}
}

