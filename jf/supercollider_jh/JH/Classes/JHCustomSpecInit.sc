JHCustomSpecInit {
	*initClass {
		Class.initClassTree(Spec);
		Spec.add(\theta, ControlSpec(-pi, pi, default: 0));
		Spec.add(\rq, ControlSpec(0.0001, 2, default: 1));
		Spec.add(\onepole, ControlSpec(0.0000, 0.999999999, default: 0.9));
	}
}