JHNodder {
	var lerpFunc, new_sel, all_keys;
	*new {
		|nodstate, syncron, activeState, waitState, anxState|
		^super.new.init(nodstate, syncron, activeState, waitState, anxState)
	}
	init {
		|nodstate, syncron, activeState, waitState, anxState|
		var state = syncron * 3;
		var nod_up = (nodstate - 0.75).abs < 0.02;
		var sel = state + (nod_up * (state >= 1) * (state < 2));
		var sel_rem = (sel - floor(sel)).lincurve(0.8, 1, 0, 1, 1);

		all_keys = activeState.keys ++ waitState.keys ++ anxState.keys;

		new_sel = floor(sel) + sel_rem;
		lerpFunc = {|key| SelectX.kr(new_sel, [activeState, waitState, anxState].collect{|e| e[key]} ) };
		^this
	}
	get { |key| ^lerpFunc.value(key) }
	asEvent {
		postf("keys in event are: %\n", all_keys);
		^all_keys.asArray.collect({ |k|
			postf("getting value of: %\n", k.asSymbol);
			[k.asSymbol, this.get(k.asSymbol)]
		}).flat.asEvent;
	}
	inAnix { ^ (new_sel - 2).abs < 0.1 }
}