JHControlNameSanitiser {
	*new{ |n|
		var p = n.asString
		.replace($/, $_)
		.replace($ , $_)
		.collect({ |l,i| if(i==0, l.toLower, l) })
		.reject({ |it, i| (i == 0) && (it == $_) });
		^if(p.size > 31,
			{ p[(p.size - 31)..].asSymbol }, {p.asSymbol});

	}
}