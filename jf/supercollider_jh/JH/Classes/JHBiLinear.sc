JHBiLinear {
	var a, b, c, d;
	*new {|a,b,c,d|
		^super.newCopyArgs(a,b,c,d)
	}
	value{ |x,y|
		^
		(a * (1-x) * (1-y)) +
		(b * x * (1-y)) +
		(c * (1-x) * y) +
		(d * x * y)
	}
}